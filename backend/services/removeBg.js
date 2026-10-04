const REMOVE_BG_URL = 'https://api.remove.bg/v1.0/removebg';

/// Sends the image to remove.bg, asking it to also composite the result
/// onto a solid ivory backdrop (matching CribeIt's brand colors) so the
/// returned photo looks like a clean studio shot rather than a transparent
/// cut-out.
async function removeBackground(imageBuffer, mimeType) {
  const apiKey = process.env.REMOVE_BG_API_KEY;

  const form = new FormData();
  const blob = new Blob([imageBuffer], { type: mimeType || 'image/jpeg' });
  form.append('image_file', blob, 'product.jpg');
  form.append('size', 'auto');
  form.append('bg_color', 'F7F1E8'); // CribeIt ivory
  form.append('format', 'png');

  const response = await fetch(REMOVE_BG_URL, {
    method: 'POST',
    headers: { 'X-Api-Key': apiKey },
    body: form,
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`remove.bg responded ${response.status}: ${text}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  return Buffer.from(arrayBuffer);
}

module.exports = { removeBackground };
