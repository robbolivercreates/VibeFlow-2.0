import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createSupabaseClient, createSupabaseAdmin } from "../_shared/supabase.ts";

const EDUZZ_API_URL = "https://api-eduzz.com";

// Map Eduzz product IDs to VibeFlow plans
function getProductPlan(productId: string): { plan: string; subPlan: string } | null {
  const monthlyId = Deno.env.get("EDUZZ_PRODUCT_ID_MENSAL");
  const annualId = Deno.env.get("EDUZZ_PRODUCT_ID_ANUAL");

  if (productId === monthlyId) return { plan: "pro", subPlan: "pro_monthly" };
  if (productId === annualId) return { plan: "pro", subPlan: "pro_annual" };
  return null;
}

Deno.serve(async (req) => {
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

    // 2. Get Eduzz token
    const eduzzToken = Deno.env.get("EDUZZ_ACCESS_TOKEN");
    if (!eduzzToken) {
      console.error("EDUZZ_ACCESS_TOKEN not configured");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 3. Query Eduzz for sales by this user's email
    const productIds = [
      Deno.env.get("EDUZZ_PRODUCT_ID_MENSAL"),
      Deno.env.get("EDUZZ_PRODUCT_ID_ANUAL"),
    ].filter(Boolean);

    let activePurchase: { productId: string; transactionId: string } | null = null;

    for (const productId of productIds) {
      const eduzzUrl = `${EDUZZ_API_URL}/myeduzz/financial/sale?email=${encodeURIComponent(user.email!)}&product_id=${productId}&status=3`;

      const eduzzResponse = await fetch(eduzzUrl, {
        headers: {
          Authorization: `Bearer ${eduzzToken}`,
          "Content-Type": "application/json",
        },
      });

      if (!eduzzResponse.ok) {
        console.error(`Eduzz API error for product ${productId}:`, eduzzResponse.status);
        continue;
      }

      const eduzzData = await eduzzResponse.json();
      const sales = eduzzData.data ?? [];

      if (sales.length > 0) {
        activePurchase = {
          productId: productId!,
          transactionId: String(sales[0].sale_id || sales[0].id || ""),
        };
        break;
      }
    }

    const adminClient = createSupabaseAdmin();

    if (activePurchase) {
      // 4a. Found active purchase - activate subscription
      const planInfo = getProductPlan(activePurchase.productId);
      if (!planInfo) {
        return new Response(
          JSON.stringify({ error: "Unknown product" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // Upsert subscription
      const { error: subError } = await adminClient
        .from("subscriptions")
        .upsert(
          {
            user_id: user.id,
            plan: planInfo.subPlan,
            status: "active",
            eduzz_transaction_id: activePurchase.transactionId,
            eduzz_product_id: activePurchase.productId,
            started_at: new Date().toISOString(),
            expires_at: planInfo.subPlan === "pro_annual"
              ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
              : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          },
          { onConflict: "user_id" },
        );

      if (subError) {
        // If upsert fails due to no unique constraint, try insert after delete
        await adminClient
          .from("subscriptions")
          .delete()
          .eq("user_id", user.id);

        await adminClient
          .from("subscriptions")
          .insert({
            user_id: user.id,
            plan: planInfo.subPlan,
            status: "active",
            eduzz_transaction_id: activePurchase.transactionId,
            eduzz_product_id: activePurchase.productId,
            started_at: new Date().toISOString(),
            expires_at: planInfo.subPlan === "pro_annual"
              ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
              : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          });
      }

      // Update profile
      await adminClient
        .from("profiles")
        .update({
          plan: planInfo.plan,
          subscription_status: "active",
        })
        .eq("id", user.id);

      return new Response(
        JSON.stringify({
          success: true,
          plan: planInfo.plan,
          subscription: planInfo.subPlan,
          message: "Assinatura ativada com sucesso!",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    } else {
      // 4b. No active purchase on Eduzz API — check pending_purchases table as fallback
      const { data: pending } = await adminClient
        .from("pending_purchases")
        .select("*")
        .eq("email", user.email!.toLowerCase())
        .eq("status", "pending")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (pending) {
        // Claim the pending purchase
        const planInfo = getProductPlan(pending.eduzz_product_id || "");
        const subPlan = planInfo?.subPlan || pending.plan || "pro_monthly";
        const daysValid = subPlan === "pro_annual" ? 365 : 30;

        // Delete existing subs + create new one
        await adminClient.from("subscriptions").delete().eq("user_id", user.id);
        await adminClient.from("subscriptions").insert({
          user_id: user.id,
          plan: subPlan,
          status: "active",
          eduzz_transaction_id: pending.eduzz_transaction_id,
          eduzz_product_id: pending.eduzz_product_id,
          started_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + daysValid * 24 * 60 * 60 * 1000).toISOString(),
        });

        // Update profile
        await adminClient.from("profiles").update({
          plan: "pro",
          subscription_status: "active",
        }).eq("id", user.id);

        // Mark pending as claimed
        await adminClient.from("pending_purchases").update({
          status: "claimed",
          claimed_at: new Date().toISOString(),
          claimed_by: user.id,
        }).eq("id", pending.id);

        console.log(`Claimed pending purchase for ${user.email}: ${subPlan}`);

        return new Response(
          JSON.stringify({
            success: true,
            plan: "pro",
            subscription: subPlan,
            message: "Assinatura ativada com sucesso!",
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // No purchase found anywhere — check if user had a previous active subscription
      const { data: existingSub } = await adminClient
        .from("subscriptions")
        .select("*")
        .eq("user_id", user.id)
        .eq("status", "active")
        .maybeSingle();

      if (existingSub) {
        await adminClient
          .from("subscriptions")
          .update({ status: "cancelled", cancelled_at: new Date().toISOString() })
          .eq("id", existingSub.id);

        await adminClient
          .from("profiles")
          .update({ plan: "free", subscription_status: "cancelled" })
          .eq("id", user.id);
      }

      return new Response(
        JSON.stringify({
          success: false,
          plan: "free",
          message: "Nenhuma compra ativa encontrada na Eduzz",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
  } catch (err) {
    console.error("Verify purchase error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
