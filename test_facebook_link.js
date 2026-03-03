/**
 * test_facebook_link.js
 * 
 * Tests Facebook URL normalization logic in utils/helpers.js
 * 
 * Run: node test_facebook_link.js
 */

const { extractUsername, resolveFacebookShareUrl } = require('./utils/helpers');

// ─── Unit tests: extractUsername ─────────────────────────────────────────────

const unitTests = [
    {
        description: 'Plain username',
        input: 'johnsmith',
        expected: 'johnsmith',
    },
    {
        description: '@username',
        input: '@johnsmith',
        expected: 'johnsmith',
    },
    {
        description: 'Direct profile URL (https)',
        input: 'https://www.facebook.com/johnsmith',
        expected: 'johnsmith',
    },
    {
        description: 'Direct profile URL (no www)',
        input: 'https://facebook.com/johnsmith',
        expected: 'johnsmith',
    },
    {
        description: 'Direct profile URL with trailing slash',
        input: 'https://www.facebook.com/johnsmith/',
        expected: 'johnsmith',
    },
    {
        description: 'Numeric ID page (profile.php?id=...)',
        input: 'https://www.facebook.com/profile.php?id=61581724792864',
        expected: 'profile.php?id=61581724792864',
    },
    {
        description: '/p/ style page URL',
        input: 'https://www.facebook.com/p/My-Page-Name-123456/',
        expected: 'My-Page-Name-123456',
    },
    {
        description: 'Share URL → should return null (needs resolution)',
        input: 'https://www.facebook.com/share/1CNr26dt8N/',
        expected: null,
    },
    {
        description: 'Sharer URL → should return null',
        input: 'https://www.facebook.com/sharer/sharer.php?u=xxx',
        expected: null,
    },
];

let passed = 0;
let failed = 0;

console.log('\n🧪 Facebook extractUsername — unit tests\n' + '─'.repeat(55));

for (const test of unitTests) {
    const result = extractUsername(test.input, 'facebook');
    const ok = result === test.expected;
    const icon = ok ? '✅' : '❌';
    console.log(`${icon}  ${test.description}`);
    if (!ok) {
        console.log(`    input:    "${test.input}"`);
        console.log(`    expected: ${JSON.stringify(test.expected)}`);
        console.log(`    got:      ${JSON.stringify(result)}`);
        failed++;
    } else {
        passed++;
    }
}

console.log(`\n${passed}/${passed + failed} unit tests passed.\n`);

// ─── Integration test: resolveFacebookShareUrl ────────────────────────────────

const SHARE_URL = process.argv[2] || null; // Pass a real share URL as CLI arg to test

async function runIntegrationTest() {
    console.log('─'.repeat(55));
    if (!SHARE_URL) {
        console.log('ℹ️  Integration test skipped (no share URL provided).');
        console.log('   To run: node test_facebook_link.js "https://www.facebook.com/share/XXXXXX/"');
        console.log('─'.repeat(55));
        return;
    }

    console.log(`🔗 Integration test: resolving "${SHARE_URL}"`);

    const resolved = await resolveFacebookShareUrl(SHARE_URL);
    if (!resolved || resolved === SHARE_URL) {
        console.log('❌ Could not resolve share URL (got same URL or null).');
        console.log('   This may be expected if Facebook required a login for this particular URL.');
    } else {
        console.log(`✅ Resolved to: ${resolved}`);
        const username = extractUsername(resolved, 'facebook');
        console.log(`   Extracted username: "${username}"`);
        if (username && username !== 'share' && username !== 'login') {
            console.log('✅ Username looks valid!');
        } else {
            console.log('⚠️  Username looks invalid — Facebook may have redirected to login or the share was not for a profile.');
        }
    }
    console.log('─'.repeat(55));
}

runIntegrationTest().catch(console.error);
