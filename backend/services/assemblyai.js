const UPLOAD_URL = 'https://api.assemblyai.com/v2/upload';
const TRANSCRIPT_URL = 'https://api.assemblyai.com/v2/transcript';

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/// Uploads raw audio bytes, requests a transcript with automatic language
/// detection (artisans may speak Tamil, Hindi or English), and polls until
/// it's done. Short clips (a few seconds) usually finish in 2-5 seconds.
async function transcribeAudio(audioBuffer) {
  const apiKey = process.env.ASSEMBLYAI_API_KEY;

  const uploadRes = await fetch(UPLOAD_URL, {
    method: 'POST',
    headers: { authorization: apiKey },
    body: audioBuffer,
  });
  if (!uploadRes.ok) {
    const text = await uploadRes.text().catch(() => '');
    throw new Error(`AssemblyAI upload responded ${uploadRes.status}: ${text}`);
  }
  const { upload_url: uploadUrl } = await uploadRes.json();

  const transcriptRes = await fetch(TRANSCRIPT_URL, {
    method: 'POST',
    headers: { authorization: apiKey, 'content-type': 'application/json' },
    body: JSON.stringify({ audio_url: uploadUrl, language_detection: true }),
  });
  if (!transcriptRes.ok) {
    const text = await transcriptRes.text().catch(() => '');
    throw new Error(`AssemblyAI transcript request responded ${transcriptRes.status}: ${text}`);
  }
  const { id } = await transcriptRes.json();

  const pollUrl = `${TRANSCRIPT_URL}/${id}`;
  for (let attempt = 0; attempt < 30; attempt++) {
    await wait(2000);
    const pollRes = await fetch(pollUrl, { headers: { authorization: apiKey } });
    const data = await pollRes.json();
    if (data.status === 'completed') {
      return { text: data.text || '', language: data.language_code || 'unknown' };
    }
    if (data.status === 'error') {
      throw new Error(`AssemblyAI transcription error: ${data.error}`);
    }
  }
  throw new Error('AssemblyAI transcription timed out.');
}

module.exports = { transcribeAudio };
