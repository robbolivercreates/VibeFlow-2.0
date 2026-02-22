import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createSupabaseAdmin } from "../_shared/supabase.ts";

// Eduzz webhook event types
// status 3 = approved/paid, 4 = cancelled, 6 = refunded, 7 = expired
const STATUS_ACTIVE = ["3"];
const STATUS_CANCELLED = ["4", "6", "7"];

function getSubPlan(productId: string): string | null {
  const monthlyId = Deno.env.get("EDUZZ_PRODUCT_ID_MENSAL");
  const annualId = Deno.env.get("EDUZZ_PRODUCT_ID_ANUAL");

  if (productId === monthlyId) return "pro_monthly";
  if (productId === annualId) return "pro_annual";
  return null;
}

Deno.serve(async (req) => {
  // Webhooks are POST only, no CORS needed (server-to-server)
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // 1. Verify webhook secret (optional, but recommended)
    const webhookSecret = Deno.env.get("EDUZZ_WEBHOOK_SECRET");
    if (webhookSecret) {
      const providedSecret = req.headers.get("x-webhook-secret") ||
        new URL(req.url).searchParams.get("secret");
      if (providedSecret !== webhookSecret) {
        console.error("Invalid webhook secret");
        return new Response("Unauthorized", { status: 401 });
      }
    }

    // 2. Parse webhook payload
    const payload = await req.json();
    console.log("Eduzz webhook received:", JSON.stringify(payload));

    const {
      trans_cod,         // transaction code
      trans_status,      // status code
      cus_email,         // customer email
      product_id,        // product ID
      recurrence_status, // recurrence status (if applicable)
    } = payload;

    // Handle Eduzz verification ping (no customer data in payload)
    if (!cus_email) {
      console.log("Webhook ping/verification received (no customer email) — returning 200");
      return new Response(
        JSON.stringify({ status: "ok", message: "Webhook verified" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const adminClient = createSupabaseAdmin();

    // 3. Find user by email
    const { data: profile } = await adminClient
      .from("profiles")
      .select("id, plan, subscription_status")
      .eq("email", cus_email)
      .maybeSingle();

    if (!profile) {
      // User hasn't signed up yet — save as pending purchase for auto-activation on signup
      const statusStr = String(trans_status);
      const subPlan = getSubPlan(String(product_id));

      if (STATUS_ACTIVE.includes(statusStr) && subPlan) {
        const { error: pendingError } = await adminClient
          .from("pending_purchases")
          .insert({
            email: cus_email.toLowerCase(),
            eduzz_transaction_id: String(trans_cod || ""),
            eduzz_product_id: String(product_id || ""),
            plan: subPlan,
            status: "pending",
            raw_payload: payload,
          });

        if (pendingError) {
          console.error("Failed to save pending purchase:", pendingError);
        } else {
          console.log(`Pending purchase saved for ${cus_email}: ${subPlan} (txn: ${trans_cod})`);
        }
      }

      return new Response(
        JSON.stringify({ received: true, user_found: false, pending_saved: true }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const subPlan = getSubPlan(String(product_id));
    const statusStr = String(trans_status);

    // 4. Handle activation (purchase/renewal)
    if (STATUS_ACTIVE.includes(statusStr) && subPlan) {
      // Delete existing subscriptions for this user
      await adminClient
        .from("subscriptions")
        .delete()
        .eq("user_id", profile.id);

      // Create new active subscription
      await adminClient
        .from("subscriptions")
        .insert({
          user_id: profile.id,
          plan: subPlan,
          status: "active",
          eduzz_transaction_id: String(trans_cod || ""),
          eduzz_product_id: String(product_id || ""),
          started_at: new Date().toISOString(),
          expires_at: subPlan === "pro_annual"
            ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
            : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        });

      // Update profile to pro
      await adminClient
        .from("profiles")
        .update({ plan: "pro", subscription_status: "active" })
        .eq("id", profile.id);

      console.log(`Subscription activated for ${cus_email}: ${subPlan}`);

      return new Response(
        JSON.stringify({ received: true, action: "activated", plan: subPlan }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // 5. Handle cancellation/refund/expiration
    if (STATUS_CANCELLED.includes(statusStr)) {
      // Mark subscription as cancelled
      await adminClient
        .from("subscriptions")
        .update({
          status: statusStr === "6" ? "expired" : "cancelled",
          cancelled_at: new Date().toISOString(),
        })
        .eq("user_id", profile.id)
        .eq("status", "active");

      // Downgrade profile to free
      await adminClient
        .from("profiles")
        .update({
          plan: "free",
          subscription_status: statusStr === "6" ? "expired" : "cancelled",
          free_transcriptions_used: 0,
          free_transcriptions_reset_at: new Date(
            Date.now() + 30 * 24 * 60 * 60 * 1000,
          ).toISOString(),
        })
        .eq("id", profile.id);

      console.log(`Subscription cancelled for ${cus_email}: status=${statusStr}`);

      return new Response(
        JSON.stringify({ received: true, action: "cancelled" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // 6. Unhandled status - just acknowledge
    console.log(`Webhook unhandled status ${statusStr} for ${cus_email}`);
    return new Response(
      JSON.stringify({ received: true, action: "ignored", status: statusStr }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
