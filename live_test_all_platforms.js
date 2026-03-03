/**
 * live_test_all_platforms.js
 * 
 * Live end-to-end test — hits the local scraper server on port 8080
 * for EVERY platform with both a plain username AND a full profile URL.
 * 
 * Run:  node live_test_all_platforms.js
 * 
 * NOTE: Each test opens a Puppeteer browser, so expect 1-2 min per platform.
 *       Platforms requiring search (Reddit, Deezer, Apple Music, Spotify) use
 *       real public artist/community names.
 */

const http = require('http');
const https = require('https');

const BASE = 'http://localhost:8080';

// ── Test definitions ──────────────────────────────────────────────────────────
// Each entry: { platform, label, input }
// We use well-known public accounts / communities that are unlikely to disappear.
const TESTS = [
    // Facebook
    { platform: 'facebook', label: 'URL', input: 'https://www.facebook.com/AtifAslamOfficialFanPage/' },
    { platform: 'facebook', label: 'username', input: 'AtifAslamOfficialFanPage' },
    { platform: 'facebook', label: 'share URL', input: 'https://www.facebook.com/share/1CNr26dt8N/' },

    // Instagram
    { platform: 'instagram', label: 'URL', input: 'https://www.instagram.com/natgeo/' },
    { platform: 'instagram', label: 'username', input: 'natgeo' },

    // TikTok
    { platform: 'tiktok', label: 'URL', input: 'https://www.tiktok.com/@nasa' },
    { platform: 'tiktok', label: 'username', input: 'nasa' },

    // Threads
    { platform: 'threads', label: 'URL', input: 'https://www.threads.net/@zuck' },
    { platform: 'threads', label: 'username', input: 'zuck' },

    // Twitter/X
    { platform: 'twitter', label: 'twitter.com URL', input: 'https://twitter.com/NASA' },
    { platform: 'twitter', label: 'x.com URL', input: 'https://x.com/NASA' },
    { platform: 'twitter', label: 'username', input: 'NASA' },

    // YouTube
    { platform: 'youtube', label: '/@handle URL', input: 'https://www.youtube.com/@NASA' },
    { platform: 'youtube', label: '@handle', input: '@NASA' },
    { platform: 'youtube', label: 'plain handle', input: 'NASA' },

    // Spotify
    { platform: 'spotify', label: 'full URL', input: 'https://open.spotify.com/artist/06HL4z0CvFAxyc27GXpf02' },
    { platform: 'spotify', label: 'artist name', input: 'Taylor Swift' },

    // Reddit
    { platform: 'reddit', label: 'subreddit URL', input: 'https://www.reddit.com/r/worldnews' },
    { platform: 'reddit', label: 'r/ prefix', input: 'r/worldnews' },

    // LinkedIn
    { platform: 'linkedin', label: '/in/ URL', input: 'https://www.linkedin.com/in/billgates' },
    { platform: 'linkedin', label: 'username', input: 'billgates' },

    // Twitch
    { platform: 'twitch', label: 'URL', input: 'https://www.twitch.tv/ninja' },
    { platform: 'twitch', label: 'username', input: 'ninja' },

    // Kick
    { platform: 'kick', label: 'URL', input: 'https://kick.com/xqc' },
    { platform: 'kick', label: 'username', input: 'xqc' },

    // Trovo
    { platform: 'trovo', label: '/s/ URL', input: 'https://trovo.live/s/ninja' },
    { platform: 'trovo', label: 'username', input: 'ninja' },

    // Pinterest
    { platform: 'pinterest', label: 'URL', input: 'https://www.pinterest.com/nasa/' },
    { platform: 'pinterest', label: 'username', input: 'nasa' },

    // SoundCloud
    { platform: 'soundcloud', label: 'URL', input: 'https://soundcloud.com/skrillex' },
    { platform: 'soundcloud', label: 'username', input: 'skrillex' },

    // Snapchat
    { platform: 'snapchat', label: '/add/ URL', input: 'https://www.snapchat.com/add/kyliejenner' },
    { platform: 'snapchat', label: 'username', input: 'kyliejenner' },

    // Discord
    { platform: 'discord', label: 'discord.gg URL', input: 'https://discord.gg/minecraft' },
    { platform: 'discord', label: 'discord.com/invite URL', input: 'https://discord.com/invite/minecraft' },
    { platform: 'discord', label: 'invite code', input: 'minecraft' },

    // Deezer
    { platform: 'deezer', label: '/artist/ URL', input: 'https://www.deezer.com/artist/13' },
    { platform: 'deezer', label: 'artist name', input: 'Eminem' },

    // Apple Music
    { platform: 'applemusic', label: 'full URL', input: 'https://music.apple.com/us/artist/taylor-swift/159260351' },
    { platform: 'applemusic', label: 'artist name', input: 'Taylor Swift' },
];

// ── HTTP helper ───────────────────────────────────────────────────────────────
function get(url) {
    return new Promise((resolve) => {
        const mod = url.startsWith('https') ? https : http;
        let data = '';
        const req = mod.get(url, { timeout: 180000 }, (res) => {
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
                catch { resolve({ status: res.statusCode, body: data }); }
            });
        });
        req.on('error', (e) => resolve({ status: 0, body: { error: e.message } }));
        req.on('timeout', () => { req.destroy(); resolve({ status: 0, body: { error: 'timeout' } }); });
    });
}

// ── Runner ────────────────────────────────────────────────────────────────────
function summarize(body) {
    if (!body || typeof body !== 'object') return String(body).slice(0, 80);
    const name = body.full_name || body.username || body.id || '';
    const flwrs = body.followers != null ? `${body.followers.toLocaleString()} followers` : '';
    const img = body.profile_image_url ? '🖼' : '';
    const err = body.error ? `⚠️ ${body.error}: ${body.message || ''}` : '';
    return err || [name, flwrs, img].filter(Boolean).join(' · ') || JSON.stringify(body).slice(0, 100);
}

async function runAll() {
    const results = [];
    let passed = 0, failed = 0;

    console.log('\n🚀 Live platform test — targeting http://localhost:8080\n');

    // Group tests by platform for cleaner output
    let lastPlatform = '';

    for (const t of TESTS) {
        if (t.platform !== lastPlatform) {
            console.log(`\n── ${t.platform.toUpperCase()} ${'─'.repeat(50 - t.platform.length)}`);
            lastPlatform = t.platform;
        }

        const url = `${BASE}/${t.platform}/profile?username_or_link=${encodeURIComponent(t.input)}`;
        process.stdout.write(`  [${t.label}] ... `);

        const { status, body } = await get(url);
        const ok = status === 200 && body && !body.error;
        const icon = ok ? '✅' : (status === 404 ? '⚠️ ' : '❌');

        console.log(`${icon}  ${status} — ${summarize(body)}`);
        results.push({ ...t, status, ok, summary: summarize(body) });
        ok ? passed++ : failed++;
    }

    // ── Summary table ─────────────────────────────────────────────────────────
    console.log('\n' + '═'.repeat(60));
    console.log(`TOTAL: ${passed} passed, ${failed} failed (${TESTS.length} tests)`);
    console.log('═'.repeat(60));

    if (failed > 0) {
        console.log('\n❌ Failed tests:');
        results.filter(r => !r.ok).forEach(r => {
            console.log(`  [${r.platform}] ${r.label}: ${r.status} — ${r.summary}`);
        });
    } else {
        console.log('\n✅ All platforms passed!');
    }
}

runAll().catch(console.error);
