async function scrapeReddit(input) {
  console.log(`🔁 [Reddit] Delegando scraping a Render: ${input}`);

  const endpoint = 'https://migozz-functions.onrender.com/reddit/profile';

  const url = `${endpoint}?username_or_link=${encodeURIComponent(input)}`;

  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'migozz-cloud-run/1.0'
    },
    timeout: 60000
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Render Reddit error ${res.status}: ${text}`);
  }

  const data = await res.json();

  // Normalización mínima (por si Render cambia algo)
  return {
    id: data.id || input,
    username: data.username || input,
    full_name: data.full_name || data.username || input,
    bio: data.bio || '',
    followers: Number(data.followers || 0),
    profile_image_url: data.profile_image_url || '',
    url: data.url,
    platform: 'reddit',
    type: data.type || 'user'
  };
}

module.exports = scrapeReddit;