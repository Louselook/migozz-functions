/**
 * test_platform_links.js
 * 
 * Comprehensive test for extractUsername() across all 18 platforms.
 * Tests both plain username/handle input AND full profile URL input.
 * 
 * Run:  node test_platform_links.js
 * With integration test (Facebook share URL resolution):
 *       node test_platform_links.js --integration
 */

const { extractUsername, resolveFacebookShareUrl } = require('./utils/helpers');

let passed = 0;
let failed = 0;

function test(description, input, platform, expected) {
    const result = extractUsername(input, platform);
    const ok = result === expected;
    const icon = ok ? '✅' : '❌';
    if (!ok) {
        console.log(`${icon}  [${platform}] ${description}`);
        console.log(`       Input:    "${input}"`);
        console.log(`       Expected: ${JSON.stringify(expected)}`);
        console.log(`       Got:      ${JSON.stringify(result)}`);
        failed++;
    } else {
        console.log(`${icon}  [${platform}] ${description}`);
        passed++;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\n🧪 Platform URL extractUsername — full audit\n' + '─'.repeat(60));

// ── FACEBOOK ─────────────────────────────────────────────────────────────────
console.log('\n📘 Facebook');
test('plain username', 'johnsmith', 'facebook', 'johnsmith');
test('@username stripped', '@johnsmith', 'facebook', 'johnsmith');
test('full profile URL', 'https://www.facebook.com/johnsmith', 'facebook', 'johnsmith');
test('full URL with trailing slash', 'https://www.facebook.com/johnsmith/', 'facebook', 'johnsmith');
test('profile.php?id= URL', 'https://www.facebook.com/profile.php?id=61581724792864', 'facebook', 'profile.php?id=61581724792864');
test('/p/ page URL', 'https://www.facebook.com/p/MyPage-123456/', 'facebook', 'MyPage-123456');
test('share URL → null sentinel', 'https://www.facebook.com/share/1CNr26dt8N/', 'facebook', null);
test('sharer URL → null sentinel', 'https://www.facebook.com/sharer/sharer.php?u=x', 'facebook', null);

// ── INSTAGRAM ────────────────────────────────────────────────────────────────
console.log('\n📷 Instagram');
test('plain username', 'natgeo', 'instagram', 'natgeo');
test('@handle', '@natgeo', 'instagram', 'natgeo');
test('full profile URL', 'https://www.instagram.com/natgeo', 'instagram', 'natgeo');
test('full URL with trailing slash', 'https://www.instagram.com/natgeo/', 'instagram', 'natgeo');

// ── TIKTOK ───────────────────────────────────────────────────────────────────
console.log('\n🎵 TikTok');
test('plain username', 'charlidamelio', 'tiktok', 'charlidamelio');
test('@handle', '@charlidamelio', 'tiktok', 'charlidamelio');
test('full profile URL', 'https://www.tiktok.com/@charlidamelio', 'tiktok', 'charlidamelio');
test('URL with trailing slash', 'https://www.tiktok.com/@charlidamelio/', 'tiktok', 'charlidamelio');

// ── THREADS ──────────────────────────────────────────────────────────────────
console.log('\n🧵 Threads');
test('plain username', 'mosseri', 'threads', 'mosseri');
test('@handle', '@mosseri', 'threads', 'mosseri');
test('full profile URL', 'https://www.threads.net/@mosseri', 'threads', 'mosseri');
test('URL with trailing slash', 'https://www.threads.net/@mosseri/', 'threads', 'mosseri');

// ── TWITTER/X ────────────────────────────────────────────────────────────────
console.log('\n🐦 Twitter/X');
test('plain username', 'elonmusk', 'twitter', 'elonmusk');
test('@handle', '@elonmusk', 'twitter', 'elonmusk');
test('twitter.com URL', 'https://twitter.com/elonmusk', 'twitter', 'elonmusk');
test('x.com URL', 'https://x.com/elonmusk', 'twitter', 'elonmusk');

// ── YOUTUBE ──────────────────────────────────────────────────────────────────
console.log('\n▶️  YouTube');
test('plain handle', 'MrBeast', 'youtube', 'MrBeast');
test('@handle', '@MrBeast', 'youtube', 'MrBeast');
test('/@handle URL', 'https://www.youtube.com/@MrBeast', 'youtube', 'MrBeast');
test('/channel/ID URL', 'https://www.youtube.com/channel/UCX6OQ3DkcsbYNE6H8uQQuVA', 'youtube', 'UCX6OQ3DkcsbYNE6H8uQQuVA');
test('/c/name URL', 'https://www.youtube.com/c/MrBeast6000', 'youtube', 'MrBeast6000');

// ── SPOTIFY ──────────────────────────────────────────────────────────────────
console.log('\n🟢 Spotify');
test('artist name', 'Taylor Swift', 'spotify', 'Taylor Swift');
test('full artist URL', 'https://open.spotify.com/artist/06HL4z0CvFAxyc27GXpf02', 'spotify', 'https://open.spotify.com/artist/06HL4z0CvFAxyc27GXpf02');

// ── REDDIT ───────────────────────────────────────────────────────────────────
console.log('\n🟠 Reddit');
test('subreddit r/ prefix', 'r/worldnews', 'reddit', 'r/worldnews');
test('user u/ prefix', 'u/spez', 'reddit', 'u/spez');
test('subreddit URL /r/', 'https://www.reddit.com/r/worldnews', 'reddit', 'r/worldnews');
test('user URL /user/', 'https://www.reddit.com/user/spez', 'reddit', 'u/spez');
test('user URL /u/', 'https://www.reddit.com/u/spez', 'reddit', 'u/spez');

// ── LINKEDIN ─────────────────────────────────────────────────────────────────
console.log('\n💼 LinkedIn');
test('plain username', 'billgates', 'linkedin', 'billgates');
test('/in/ profile URL', 'https://www.linkedin.com/in/billgates', 'linkedin', 'billgates');
test('/company/ URL', 'https://www.linkedin.com/company/google', 'linkedin', 'google');

// ── TWITCH ───────────────────────────────────────────────────────────────────
console.log('\n🟣 Twitch');
test('plain username', 'ninja', 'twitch', 'ninja');
test('@handle', '@ninja', 'twitch', 'ninja');
test('full profile URL', 'https://www.twitch.tv/ninja', 'twitch', 'ninja');

// ── KICK ─────────────────────────────────────────────────────────────────────
console.log('\n🟩 Kick');
test('plain username', 'xqc', 'kick', 'xqc');
test('@handle', '@xqc', 'kick', 'xqc');
test('full profile URL', 'https://kick.com/xqc', 'kick', 'xqc');

// ── TROVO ────────────────────────────────────────────────────────────────────
console.log('\n🎮 Trovo');
test('plain username', 'ninja', 'trovo', 'ninja');
test('/s/ URL', 'https://trovo.live/s/ninja', 'trovo', 'ninja');

// ── PINTEREST ────────────────────────────────────────────────────────────────
console.log('\n📌 Pinterest');
test('plain username', 'nasa', 'pinterest', 'nasa');
test('@handle', '@nasa', 'pinterest', 'nasa');
test('full profile URL', 'https://www.pinterest.com/nasa', 'pinterest', 'nasa');
test('URL with trailing slash', 'https://www.pinterest.com/nasa/', 'pinterest', 'nasa');

// ── SOUNDCLOUD ───────────────────────────────────────────────────────────────
console.log('\n☁️  SoundCloud');
test('plain username', 'skrillex', 'soundcloud', 'skrillex');
test('@handle', '@skrillex', 'soundcloud', 'skrillex');
test('full profile URL', 'https://soundcloud.com/skrillex', 'soundcloud', 'skrillex');

// ── SNAPCHAT ─────────────────────────────────────────────────────────────────
console.log('\n👻 Snapchat');
test('plain username', 'kylie', 'snapchat', 'kylie');
test('@handle', '@kylie', 'snapchat', 'kylie');
test('/add/ URL', 'https://www.snapchat.com/add/kylie', 'snapchat', 'kylie');

// ── DISCORD ──────────────────────────────────────────────────────────────────
console.log('\n🎮 Discord');
test('invite code', 'minecraft', 'discord', 'minecraft');
test('discord.gg/code URL', 'https://discord.gg/minecraft', 'discord', 'minecraft');
test('discord.com/invite/ URL', 'https://discord.com/invite/minecraft', 'discord', 'minecraft');

// ── DEEZER ───────────────────────────────────────────────────────────────────
console.log('\n🎶 Deezer');
test('artist name', 'Eminem', 'deezer', 'Eminem');
test('numeric artist ID', '13', 'deezer', '13');
test('/artist/ URL', 'https://www.deezer.com/artist/13', 'deezer', '13');

// ── APPLE MUSIC ──────────────────────────────────────────────────────────────
console.log('\n🍎 Apple Music');
test('artist name', 'Adele', 'applemusic', 'Adele');
test('numeric artist ID', '262836961', 'applemusic', '262836961');
// Full URL must be returned as-is (scraper handles routing internally)
const amUrl = 'https://music.apple.com/us/artist/adele/262836961';
test('full artist URL passed as-is', amUrl, 'applemusic', amUrl);

// ─────────────────────────────────────────────────────────────────────────────
console.log('\n' + '─'.repeat(60));
console.log(`Result: ${passed}/${passed + failed} tests passed${failed > 0 ? ` — ${failed} FAILED` : ' ✅'}`);
console.log('─'.repeat(60));

// ── Optional integration test for Facebook share URL resolution ───────────────
if (process.argv.includes('--integration')) {
    const SHARE_URL = 'https://www.facebook.com/share/1CNr26dt8N/';
    console.log(`\n🔗 Integration: resolving Facebook share URL`);
    console.log(`   ${SHARE_URL}`);
    resolveFacebookShareUrl(SHARE_URL).then(resolved => {
        if (!resolved) {
            console.log('❌  Could not resolve — share link may be private/expired');
        } else {
            const username = extractUsername(resolved, 'facebook');
            console.log(`✅  Resolved → ${resolved}`);
            console.log(`   Username: "${username}"`);
        }
    }).catch(console.error);
}
