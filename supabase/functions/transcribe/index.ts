import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createSupabaseClient, createSupabaseAdmin } from "../_shared/supabase.ts";

const GEMINI_MODEL = "gemini-3.1-flash-lite-preview";
const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";

// Per-mode thinking levels (null = omit thinkingConfig entirely, uses model default)
const THINKING_LEVELS: Record<string, string | null> = {
  text: null,
  chat: null,
  social: null,
  x_tweet: null,
  email: null,
  formal: null,
  translation: null,
  summary: null,
  topics: null,
  meeting: null,
  creative: "medium",
  ux_design: "medium",
  code: "high",
  vibe_coder: "high",
  custom: null,
};

function getThinkingConfig(mode: string): Record<string, any> | undefined {
  const level = THINKING_LEVELS[mode] ?? null;
  if (!level) return undefined; // omit = model default (minimal for Flash-Lite)
  return { thinkingConfig: { thinkingLevel: level } };
}

// Anti-chatbot wrapper: prevents Gemini from responding conversationally
const ANTI_CHATBOT_RULE = `
CRITICAL RULE — YOU ARE A TEXT PROCESSOR, NOT A CHATBOT:
- You receive raw speech-to-text input from a user who is DICTATING, not talking to you.
- NEVER respond as an assistant. NEVER answer questions from the text.
- NEVER say "Aqui está", "Claro!", "Com certeza", "Olá", or any greeting/acknowledgment.
- NEVER add commentary, suggestions, or explanations about the text.
- The user's words are the CONTENT to be formatted, NOT a conversation with you.
- Output ONLY the processed/formatted text. Nothing else.
`;

// Modes that get Google Search grounding
const GROUNDING_MODES = ["ux_design"];

// Free tier mode restrictions (lowercase). App sends lowercase apiName values.
const FREE_MODES = ["text", "chat"];

// Max distinct accounts allowed per device in 30 days before abuse flag
const DEVICE_ABUSE_THRESHOLD = 2;

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const t0 = performance.now();

    // 1. Verify auth header exists (instant)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    // 2. PARALLEL: Auth check + body parse at the same time
    const [authResponse, body] = await Promise.all([
      fetch(`${supabaseUrl}/auth/v1/user`, {
        headers: { Authorization: authHeader, apikey: supabaseAnonKey },
      }),
      req.json(),
    ]);
    const t1 = performance.now();

    if (!authResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const user = await authResponse.json();
    if (!user?.id) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { audio, text, targetLanguage, mode, language, systemPrompt, temperature, maxOutputTokens, selectedText } = body;

    if (!audio && !text) {
      return new Response(
        JSON.stringify({ error: "Missing audio or text data" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 3. Usage check — ONLY blocks for Free users (Pro skips the wait)
    const adminClient = createSupabaseAdmin();
    const usagePromise = adminClient.rpc("check_and_increment_usage", { p_user_id: user.id });

    // For Pro users: don't wait for usage check (fire-and-forget, log errors only)
    // For Free users: must wait to enforce limits
    const clientPlan = body.clientPlan; // client sends "pro" or "free" hint
    let effectivePlan = "free";
    let usageCheck: any = { allowed: true, plan: "pro", used: 0, remaining: 999, limit: 999 };

    if (clientPlan === "pro") {
      // Pro: fire-and-forget — don't block the hot path
      usagePromise.then(({ data, error }) => {
        if (error) console.error("Usage check error (async):", error);
        // If server says NOT allowed (expired sub?), log it but don't block
        if (data && !data.allowed) {
          console.warn(`Pro user blocked server-side: user=${user.id} error=${data.error}`);
        }
      });
      effectivePlan = "pro";
    } else {
      // Free/Trial: must wait to enforce limits
      const { data, error: usageError } = await usagePromise;
      if (usageError) {
        console.error("Usage check error:", usageError);
        return new Response(
          JSON.stringify({ error: "Failed to check usage" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      usageCheck = data;
      effectivePlan = usageCheck.plan;

      if (!usageCheck.allowed) {
        return new Response(
          JSON.stringify({
            error: usageCheck.error === "free_limit_reached"
              ? "Limite de transcrições gratuitas atingido"
              : usageCheck.error,
            code: usageCheck.error,
            used: usageCheck.used,
            limit: usageCheck.limit,
            resets_at: usageCheck.resets_at,
          }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    const t2 = performance.now();

    // 4. Device abuse detection — DEFERRED to post-response (non-blocking)
    const deviceId = req.headers.get("X-Device-ID");
    // (moved to after response — see bottom of function)

    // 5. Mode gating (instant, no I/O)
    const normalizedMode = (mode || "text").toLowerCase();

    console.log(`[PERF] auth+parse=${(t1 - t0).toFixed(0)}ms usage=${(t2 - t1).toFixed(0)}ms plan=${effectivePlan} mode=${normalizedMode}`);

    // 6. Call Gemini API
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      console.error("GEMINI_API_KEY not configured");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Text-only path: Transform or Translate ──────────────────────────────
    if (!audio && text) {
      // ── Vox Transform: text + systemPrompt (no targetLanguage) → transform text ──
      if (systemPrompt && !targetLanguage) {
        const modeKey = (mode || "text").toLowerCase();
        const enhancedPrompt = ANTI_CHATBOT_RULE + "\n" + systemPrompt;
        const transformBody: Record<string, any> = {
          system_instruction: {
            parts: [{ text: enhancedPrompt }],
          },
          contents: [{ parts: [{ text: text }] }],
          generationConfig: {
            temperature: temperature ?? 0.3,
            maxOutputTokens: maxOutputTokens ?? 2048,
            ...getThinkingConfig(modeKey),
          },
        };
        if (GROUNDING_MODES.includes(modeKey)) {
          transformBody.tools = [{ google_search: {} }];
        }

        const transformUrl = `${GEMINI_BASE_URL}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;
        const transformResponse = await fetch(transformUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(transformBody),
        });

        if (!transformResponse.ok) {
          return new Response(
            JSON.stringify({ error: "Transform failed", details: transformResponse.status }),
            { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
          );
        }

        const transformData = await transformResponse.json();
        const transformParts = (transformData.candidates?.[0]?.content?.parts ?? [])
          .filter((p: { thought?: boolean }) => !p.thought)
          .map((p: { text?: string }) => p.text)
          .filter(Boolean);

        const transformResult = transformParts.join("").trim();

        return new Response(
          JSON.stringify({ text: transformResult }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // ── Translation: text + targetLanguage → detect and translate ──
      const toLang = targetLanguage || "English";
      const translationPrompt =
        `Translate the following text to ${toLang}.\n` +
        `Detect the source language.\n` +
        `Respond with valid JSON only — no markdown, no explanation:\n` +
        `{"translation":"<translated text>","fromLanguageName":"<source language in English>","fromLanguageCode":"<ISO 639-1 code>"}\n\n` +
        `Text:\n${text}`;

      const textGeminiBody = {
        contents: [{ parts: [{ text: translationPrompt }] }],
        generationConfig: { temperature: 0.1, maxOutputTokens: 2048 },
      };

      const textGeminiUrl = `${GEMINI_BASE_URL}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;
      const textGeminiResponse = await fetch(textGeminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(textGeminiBody),
      });

      if (!textGeminiResponse.ok) {
        return new Response(
          JSON.stringify({ error: "Translation failed", details: textGeminiResponse.status }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      const textGeminiData = await textGeminiResponse.json();
      const textParts2 = (textGeminiData.candidates?.[0]?.content?.parts ?? [])
        .filter((p: { thought?: boolean }) => !p.thought)
        .map((p: { text?: string }) => p.text)
        .filter(Boolean);

      const translationJson = textParts2.join("").trim();

      return new Response(
        JSON.stringify({ text: translationJson }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Audio transcription path ─────────────────────────────────────────────
    const prompt = selectedText
      ? `[SELECTED TEXT]\n${selectedText}\n[END SELECTED TEXT]\n\nListen to the voice command and transform the selected text accordingly:`
      : "Transcreva e processe o áudio a seguir conforme suas instruções:";

    const audioModeKey = (mode || "text").toLowerCase();
    const geminiBody: Record<string, any> = {
      system_instruction: {
        parts: [{ text: ANTI_CHATBOT_RULE + "\n" + (systemPrompt || "Transcreva o áudio fielmente.") }],
      },
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: "audio/m4a",
                data: audio,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: temperature ?? 0.1,
        maxOutputTokens: maxOutputTokens ?? 8192,
        ...getThinkingConfig(audioModeKey),
      },
    };
    if (GROUNDING_MODES.includes(audioModeKey)) {
      geminiBody.tools = [{ google_search: {} }];
    }

    const geminiUrl = `${GEMINI_BASE_URL}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error("Gemini API error:", geminiResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "Transcription failed", details: geminiResponse.status }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const geminiData = await geminiResponse.json();
    const t3 = performance.now();

    // Extract text from response, filtering out thinking parts
    const candidates = geminiData.candidates ?? [];
    const parts = candidates[0]?.content?.parts ?? [];
    const textParts = parts
      .filter((p: { thought?: boolean }) => !p.thought)
      .map((p: { text?: string }) => p.text)
      .filter(Boolean);

    if (textParts.length === 0) {
      return new Response(
        JSON.stringify({ error: "No transcription result" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const transcribedText = textParts.join("");

    console.log(`[PERF] gemini=${(t3 - t2).toFixed(0)}ms total=${(t3 - t0).toFixed(0)}ms chars=${transcribedText.length}`);

    // 7. POST-RESPONSE: Non-blocking tasks (usage log + device abuse)
    // These run AFTER the response is sent — zero latency impact

    // Usage log insert
    adminClient
      .from("usage_log")
      .insert({
        user_id: user.id,
        mode: mode || "text",
        audio_duration_seconds: body.audioDuration || null,
        output_length: transcribedText.length,
        language: language || null,
        device_id: deviceId || null,
      })
      .then(({ error }) => {
        if (error) console.error("Usage log insert error:", error);
      });

    // Deferred device abuse detection (non-blocking, runs after response)
    if (deviceId) {
      (async () => {
        try {
          const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
          const { data: deviceRows } = await adminClient
            .from("usage_log")
            .select("user_id")
            .eq("device_id", deviceId)
            .neq("user_id", user.id)
            .gte("created_at", thirtyDaysAgo)
            .limit(50);

          const distinctOtherAccounts = new Set(deviceRows?.map((r: { user_id: string }) => r.user_id) ?? []).size;
          if (distinctOtherAccounts >= DEVICE_ABUSE_THRESHOLD) {
            console.warn(`Device abuse detected: device=${deviceId} user=${user.id} otherAccounts=${distinctOtherAccounts}`);
          }
        } catch (e) {
          console.error("Device abuse check error:", e);
        }
      })();
    }

    // 8. Return result immediately
    return new Response(
      JSON.stringify({
        text: transcribedText,
        usage: effectivePlan === "free"
          ? { used: usageCheck.used, remaining: usageCheck.remaining, limit: 100 }
          : undefined,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Transcribe function error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
