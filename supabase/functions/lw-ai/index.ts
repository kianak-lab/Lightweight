const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const json = (o: unknown, status = 200) =>
    new Response(JSON.stringify(o), { status, headers: { ...cors, "content-type": "application/json" } });
  try {
    const { prompt, image } = await req.json();
    const content: unknown[] = [];
    if (image) content.push({ type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } });
    content.push({ type: "text", text: String(prompt || "").slice(0, 30000) });
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({ model: "claude-sonnet-5-5", max_tokens: 1500, messages: [{ role: "user", content }] }),
    });
    const j = await r.json();
    if (!r.ok) return json({ error: j?.error?.message || "AI error" }, r.status === 429 ? 429 : 502);
    return json({ text: (j.content || []).map((c: { text?: string }) => c.text || "").join("") });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
