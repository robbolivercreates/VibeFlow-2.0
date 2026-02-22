import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Eduzz Custom Delivery endpoint
// POST: Eduzz sends this to validate the URL (must return 200)
// GET:  Customer is redirected here after purchase → redirect to /compra
// Accepts ANY content type (Eduzz may send JSON or form-urlencoded)

const COMPRA_URL = "https://www.voxaigo.com/compra";

Deno.serve(async (req) => {
  // GET → redirect customer to /compra page
  if (req.method === "GET") {
    return new Response(null, {
      status: 302,
      headers: { Location: COMPRA_URL },
    });
  }

  // POST → Eduzz validation or delivery notification, always return 200
  if (req.method === "POST") {
    try {
      const text = await req.text().catch(() => "");
      console.log("Eduzz delivery POST:", text.slice(0, 500));
    } catch {
      // ignore
    }
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  // OPTIONS (CORS preflight)
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  // Any other method → still return 200 to not break Eduzz
  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
