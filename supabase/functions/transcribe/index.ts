import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createSupabaseClient, createSupabaseAdmin } from "../_shared/supabase.ts";

const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";

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
    // 1. Verify authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createSupabaseClient(authHeader);
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Parse request body
    const body = await req.json();
    const { audio, text, targetLanguage, mode, language, systemPrompt, temperature, maxOutputTokens, selectedText } = body;

    if (!audio && !text) {
      return new Response(
        JSON.stringify({ error: "Missing audio or text data" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 3. Check plan and usage via DB function
    const adminClient = createSupabaseAdmin();
    const { data: usageCheck, error: usageError } = await adminClient.rpc(
      "check_and_increment_usage",
      { p_user_id: user.id },
    );

    if (usageError) {
      console.error("Usage check error:", usageError);
      return new Response(
        JSON.stringify({ error: "Failed to check usage" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

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

    // 4. Device abuse detection
    const deviceId = req.headers.get("X-Device-ID");
    let effectivePlan = usageCheck.plan;

    if (deviceId) {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

      // Find distinct user accounts that used this device in last 30 days (excluding current user)
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
        // Force free tier limits regardless of plan
        effectivePlan = "free";
      }
    }

    // 5. Feature gating: mode restrictions logged but enforced client-side.
    // Server-side enforcement removed because dev mode is client-only
    // and the real protection is the usage limit, not mode gating.
    const normalizedMode = (mode || "text").toLowerCase();
    if (effectivePlan === "free" && !FREE_MODES.includes(normalizedMode)) {
      console.warn(`Free user using pro mode: user=${user.id} mode=${normalizedMode}`);
    }

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
        const transformBody = {
          system_instruction: {
            parts: [{ text: systemPrompt }],
          },
          contents: [{ parts: [{ text: text }] }],
          generationConfig: {
            temperature: temperature ?? 0.3,
            maxOutputTokens: maxOutputTokens ?? 2048,
            thinkingConfig: { thinkingBudget: 0 },
          },
        };

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
        generationConfig: { temperature: 0.1, maxOutputTokens: 2048, thinkingConfig: { thinkingBudget: 0 } },
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

    const geminiBody = {
      system_instruction: {
        parts: [{ text: systemPrompt || "Transcreva o áudio fielmente." }],
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
        thinkingConfig: {
          thinkingBudget: 0,
        },
      },
    };

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

    // 7. Log usage with device ID (non-blocking)
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

    // 8. Return result
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
