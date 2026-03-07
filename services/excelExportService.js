const ExcelJS = require('exceljs');
const path = require('path');
const { db } = require('../config/firebaseAdmin');

const LOGO_PATH = path.join(__dirname, '..', 'assets', 'img', 'logo', 'logo-sm.png');

const PLATFORMS = [
  'instagram', 'tiktok', 'twitter', 'spotify', 'youtube',
  'facebook', 'threads', 'linkedin', 'pinterest', 'soundcloud',
  'applemusic', 'deezer', 'discord', 'snapchat', 'twitch',
  'kick', 'trovo', 'reddit', 'shopify', 'woocommerce', 'etsy',
  'whatsapp', 'telegram',
];

const BRAND_COLOR = '1A1A2E';
const ACCENT_COLOR = '6C63FF';
const LIGHT_BG = 'F5F5FA';
const WHITE = 'FFFFFF';
const BORDER_COLOR = 'D0D0D8';
const SUCCESS_COLOR = '2ECC71';
const SUMMARY_BG_ALT = 'EDEDF5';

// ─── Firestore Query ───────────────────────────────────────────────────────

async function queryMembers({ startDate, endDate }) {
  let query = db.collection('users');

  if (startDate) {
    query = query.where('createdAt', '>=', new Date(startDate));
  }
  if (endDate) {
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);
    query = query.where('createdAt', '<=', end);
  }

  const snapshot = await query.get();
  return snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((u) => u.isPreRegister !== true);
}

// ─── Social Ecosystem Helpers ──────────────────────────────────────────────

function extractPlatformData(socialEcosystem) {
  const result = {};
  if (!Array.isArray(socialEcosystem)) return result;

  for (const entry of socialEcosystem) {
    if (!entry || typeof entry !== 'object') continue;

    // Format A: { instagram: { username, followers, ... } }
    for (const key of PLATFORMS) {
      if (entry[key] && typeof entry[key] === 'object') {
        result[key] = entry[key];
      }
    }
    // Handle 'x' as alias for 'twitter'
    if (entry.x && typeof entry.x === 'object' && !result.twitter) {
      result.twitter = entry.x;
    }

    // Format B: { platform: 'instagram', username: '...', followers: ... }
    if (entry.platform && PLATFORMS.includes(entry.platform)) {
      result[entry.platform] = entry;
    }
  }

  return result;
}

function getFollowers(platformData) {
  if (!platformData) return 0;
  return platformData.followers || platformData.members_count || 0;
}

function getUrl(platformData) {
  if (!platformData) return '';
  return platformData.url || '';
}

function getCommunityTotal(platforms) {
  return Object.values(platforms).reduce((sum, p) => sum + getFollowers(p), 0);
}

// ─── Row Builder ───────────────────────────────────────────────────────────

function buildMemberRow(user) {
  const platforms = extractPlatformData(user.socialEcosystem);
  const ts = (field) => {
    if (!field) return '';
    if (field._seconds) return new Date(field._seconds * 1000);
    if (field.toDate) return field.toDate();
    if (field instanceof Date) return field;
    return new Date(field);
  };

  return {
    userId: user.id || '',
    fullName: user.displayName || user.fullName || user.full_name || '',
    username: user.username || '',
    email: user.email || '',
    phone: user.phone || '',
    status: user.active === false ? 'inactive' : 'active',
    role: Array.isArray(user.category) ? user.category.join(', ') : (user.category || user.role || ''),
    isDeleted: user.isDeleted ? 'Yes' : 'No',
    isPreRegistered: user.isPreRegistered ? 'Yes' : 'No',
    country: user.location?.country || '',
    city: user.location?.city || '',
    joinedAt: ts(user.createdAt),
    updatedAt: ts(user.updatedAt),
    communityTotal: getCommunityTotal(platforms),
    migozzFollowers: user.migozzFollowers || 0,
    instagramFollowers: getFollowers(platforms.instagram),
    tiktokFollowers: getFollowers(platforms.tiktok),
    xFollowers: getFollowers(platforms.twitter),
    spotifyFollowers: getFollowers(platforms.spotify),
    youtubeFollowers: getFollowers(platforms.youtube),
    facebookFollowers: getFollowers(platforms.facebook),
    threadsFollowers: getFollowers(platforms.threads),
    linkedinFollowers: getFollowers(platforms.linkedin),
    pinterestFollowers: getFollowers(platforms.pinterest),
    snapchatFollowers: getFollowers(platforms.snapchat),
    twitchFollowers: getFollowers(platforms.twitch),
    kickFollowers: getFollowers(platforms.kick),
    trovoFollowers: getFollowers(platforms.trovo),
    redditFollowers: getFollowers(platforms.reddit),
    soundcloudFollowers: getFollowers(platforms.soundcloud),
    applemusicFollowers: getFollowers(platforms.applemusic),
    deezerFollowers: getFollowers(platforms.deezer),
    shopifyFollowers: getFollowers(platforms.shopify),
    woocommerceFollowers: getFollowers(platforms.woocommerce),
    etsyFollowers: getFollowers(platforms.etsy),
    whatsappFollowers: getFollowers(platforms.whatsapp),
    telegramFollowers: getFollowers(platforms.telegram),
    website: user.contactWebsite || (user.featuredLinks?.[0]?.url) || '',
    instagramUrl: getUrl(platforms.instagram),
    tiktokUrl: getUrl(platforms.tiktok),
    xUrl: getUrl(platforms.twitter),
    spotifyUrl: getUrl(platforms.spotify),
    youtubeUrl: getUrl(platforms.youtube),
    facebookUrl: getUrl(platforms.facebook),
    notes: user.notes || '',
  };
}

// ─── Summary Calculator ────────────────────────────────────────────────────

function buildSummary(rows) {
  const summary = {
    totalAppUsers: rows.length,
    totalPreRegistered: rows.filter((r) => r.isPreRegistered === 'Yes').length,
    totalDeleted: rows.filter((r) => r.isDeleted === 'Yes').length,
    totalCommunity: rows.reduce((s, r) => s + r.communityTotal, 0),
    platforms: {},
  };

  const platformKeys = [
    ['instagramFollowers', 'Instagram'],
    ['youtubeFollowers', 'YouTube'],
    ['tiktokFollowers', 'TikTok'],
    ['facebookFollowers', 'Facebook'],
    ['redditFollowers', 'Reddit'],
    ['xFollowers', 'X (Twitter)'],
    ['linkedinFollowers', 'LinkedIn'],
    ['threadsFollowers', 'Threads'],
    ['pinterestFollowers', 'Pinterest'],
    ['snapchatFollowers', 'Snapchat'],
    ['twitchFollowers', 'Twitch'],
    ['kickFollowers', 'Kick'],
    ['trovoFollowers', 'Trovo'],
    ['spotifyFollowers', 'Spotify'],
    ['applemusicFollowers', 'Apple Music'],
    ['deezerFollowers', 'Deezer'],
    ['soundcloudFollowers', 'SoundCloud'],
    ['shopifyFollowers', 'Shopify'],
    ['woocommerceFollowers', 'WooCommerce'],
    ['etsyFollowers', 'Etsy'],
    ['whatsappFollowers', 'WhatsApp'],
    ['telegramFollowers', 'Telegram'],
  ];

  for (const [key, label] of platformKeys) {
    summary.platforms[label] = rows.reduce((s, r) => s + (r[key] || 0), 0);
  }

  return summary;
}

// ─── Style Helpers ─────────────────────────────────────────────────────────

function thinBorder() {
  return {
    top: { style: 'thin', color: { argb: BORDER_COLOR } },
    left: { style: 'thin', color: { argb: BORDER_COLOR } },
    bottom: { style: 'thin', color: { argb: BORDER_COLOR } },
    right: { style: 'thin', color: { argb: BORDER_COLOR } },
  };
}

function headerFont(size = 12, bold = true) {
  return { name: 'Calibri', size, bold, color: { argb: WHITE } };
}

// ─── Excel Workbook Builder ────────────────────────────────────────────────

async function generateMemberExcel({ startDate, endDate, adminName }) {
  // 1. Query Firestore
  const users = await queryMembers({ startDate, endDate });
  const rows = users.map(buildMemberRow);
  const summary = buildSummary(rows);

  // Count pre-registered users separately (excluded from members query)
  const preRegSnap = await db.collection('users').where('isPreRegister', '==', true).get();
  summary.totalPreRegistered = preRegSnap.size;

  // 2. Create workbook
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Migozz';
  workbook.created = new Date();

  const ws = workbook.addWorksheet('Member Report', {
    properties: { defaultColWidth: 18 },
  });

  let currentRow = 1;

  // ── HEADER SECTION ─────────────────────────────────────────────────────

  // Add logo
  try {
    const logoId = workbook.addImage({
      filename: LOGO_PATH,
      extension: 'png',
    });
    ws.addImage(logoId, {
      tl: { col: 0, row: 0 },
      ext: { width: 150, height: 150 },
    });
  } catch (e) {
    console.warn('[Excel Export] Could not load logo:', e.message);
  }

  // Title row
  ws.getRow(1).height = 115;
  ws.mergeCells('B1:H1');
  const titleCell = ws.getCell('B1');
  titleCell.value = 'Member List Export';
  titleCell.font = { name: 'Calibri', size: 20, bold: true, color: { argb: BRAND_COLOR } };
  titleCell.alignment = { vertical: 'middle' };

  // Subtitle row — date + admin
  currentRow = 2;
  ws.mergeCells('B2:H2');
  const now = new Date();
  const dateStr = now.toLocaleDateString('en-US', {
    year: 'numeric', month: 'long', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
  const subtitleCell = ws.getCell('B2');
  subtitleCell.value = `Generated: ${dateStr}  |  By: ${adminName || 'System'}`;
  subtitleCell.font = { name: 'Calibri', size: 10, color: { argb: '666666' } };
  subtitleCell.alignment = { vertical: 'middle' };
  ws.getRow(2).height = 22;

  // Filters row
  currentRow = 3;
  ws.mergeCells('B3:H3');
  const filterCell = ws.getCell('B3');
  const filterFrom = startDate || 'All';
  const filterTo = endDate || 'All';
  filterCell.value = `Filters — From: ${filterFrom}  To: ${filterTo}`;
  filterCell.font = { name: 'Calibri', size: 10, italic: true, color: { argb: '999999' } };
  ws.getRow(3).height = 20;

  // Separator
  currentRow = 4;
  ws.getRow(currentRow).height = 10;

  // ── SUMMARY SECTION ────────────────────────────────────────────────────

  // Use 6 columns for platform grid (3 pairs of label+value)
  const SUMMARY_COLS = 6;

  currentRow = 5;

  // Summary title bar — extend across 6 columns
  ws.mergeCells(currentRow, 1, currentRow, SUMMARY_COLS);
  const summaryTitleCell = ws.getCell(currentRow, 1);
  summaryTitleCell.value = '  REPORT SUMMARY';
  summaryTitleCell.font = headerFont(12, true);
  summaryTitleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: ACCENT_COLOR } };
  summaryTitleCell.alignment = { vertical: 'middle' };
  for (let c = 1; c <= SUMMARY_COLS; c++) {
    ws.getCell(currentRow, c).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: ACCENT_COLOR } };
  }
  ws.getRow(currentRow).height = 30;
  currentRow++;

  // Summary KPIs — 2 per row
  const summaryItems = [
    ['Total App Users', summary.totalAppUsers],
    ['Total Pre-Registered', summary.totalPreRegistered],
    ['Total Community', summary.totalCommunity],
    ['Total Deleted', summary.totalDeleted],
  ];

  for (let i = 0; i < summaryItems.length; i += 2) {
    for (let j = 0; j < 2 && i + j < summaryItems.length; j++) {
      const col = j * 2 + 1;
      const [label, val] = summaryItems[i + j];

      const labelCell = ws.getCell(currentRow, col);
      labelCell.value = label;
      labelCell.font = { name: 'Calibri', size: 9, bold: true, color: { argb: '555555' } };
      labelCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: LIGHT_BG } };
      labelCell.border = thinBorder();
      labelCell.alignment = { vertical: 'middle' };

      const valueCell = ws.getCell(currentRow, col + 1);
      valueCell.value = val;
      valueCell.numFmt = '#,##0';
      valueCell.font = { name: 'Calibri', size: 12, bold: true, color: { argb: BRAND_COLOR } };
      valueCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: LIGHT_BG } };
      valueCell.border = thinBorder();
      valueCell.alignment = { horizontal: 'center', vertical: 'middle' };
    }
    ws.getRow(currentRow).height = 26;
    currentRow++;
  }

  // Small spacer
  ws.getRow(currentRow).height = 6;
  currentRow++;

  // Platform totals title bar
  ws.mergeCells(currentRow, 1, currentRow, SUMMARY_COLS);
  const platTitleCell = ws.getCell(currentRow, 1);
  platTitleCell.value = '  Platform Totals (Followers)';
  platTitleCell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: WHITE } };
  platTitleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '444466' } };
  platTitleCell.alignment = { vertical: 'middle' };
  for (let c = 1; c <= SUMMARY_COLS; c++) {
    ws.getCell(currentRow, c).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '444466' } };
  }
  ws.getRow(currentRow).height = 26;
  currentRow++;

  // Platform totals — 3 per row (label + value pairs)
  const PLAT_PER_ROW = 3;
  const platEntries = Object.entries(summary.platforms);
  for (let rowIdx = 0; rowIdx < Math.ceil(platEntries.length / PLAT_PER_ROW); rowIdx++) {
    const isAlt = rowIdx % 2 === 1;
    const rowBg = isAlt ? SUMMARY_BG_ALT : LIGHT_BG;

    for (let colIdx = 0; colIdx < PLAT_PER_ROW; colIdx++) {
      const idx = rowIdx * PLAT_PER_ROW + colIdx;
      if (idx >= platEntries.length) {
        // Fill empty cells with background
        const col = colIdx * 2 + 1;
        ws.getCell(currentRow, col).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
        ws.getCell(currentRow, col).border = thinBorder();
        ws.getCell(currentRow, col + 1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
        ws.getCell(currentRow, col + 1).border = thinBorder();
        continue;
      }
      const [label, value] = platEntries[idx];
      const col = colIdx * 2 + 1;

      const labelCell = ws.getCell(currentRow, col);
      labelCell.value = label;
      labelCell.font = { name: 'Calibri', size: 9, bold: true, color: { argb: BRAND_COLOR } };
      labelCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
      labelCell.border = thinBorder();
      labelCell.alignment = { vertical: 'middle' };

      const valueCell = ws.getCell(currentRow, col + 1);
      valueCell.value = value;
      valueCell.numFmt = '#,##0';
      valueCell.font = {
        name: 'Calibri', size: 10, bold: true,
        color: { argb: value === 0 ? BRAND_COLOR : ACCENT_COLOR },
      };
      valueCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: rowBg } };
      valueCell.border = thinBorder();
      valueCell.alignment = { horizontal: 'right', vertical: 'middle' };
    }
    ws.getRow(currentRow).height = 22;
    currentRow++;
  }

  // Spacer before data table
  ws.getRow(currentRow).height = 12;
  currentRow++;

  // ── MAIN DATA TABLE ────────────────────────────────────────────────────

  const columns = [
    { key: 'userId', header: 'User ID', width: 28 },
    { key: 'fullName', header: 'Full Name', width: 22 },
    { key: 'username', header: 'Username', width: 18 },
    { key: 'email', header: 'Email', width: 28 },
    { key: 'phone', header: 'Phone', width: 16 },
    { key: 'status', header: 'Status', width: 12 },
    { key: 'role', header: 'Role', width: 10 },
    { key: 'isDeleted', header: 'Deleted', width: 10 },
    { key: 'isPreRegistered', header: 'Pre-Reg', width: 10 },
    { key: 'country', header: 'Country', width: 14 },
    { key: 'city', header: 'City', width: 14 },
    { key: 'joinedAt', header: 'Joined', width: 18 },
    { key: 'updatedAt', header: 'Updated', width: 18 },
    { key: 'communityTotal', header: 'Community Total', width: 16 },
    { key: 'migozzFollowers', header: 'Migozz', width: 12 },
    { key: 'instagramFollowers', header: 'Instagram', width: 12 },
    { key: 'tiktokFollowers', header: 'TikTok', width: 12 },
    { key: 'xFollowers', header: 'X', width: 12 },
    { key: 'spotifyFollowers', header: 'Spotify', width: 12 },
    { key: 'youtubeFollowers', header: 'YouTube', width: 12 },
    { key: 'facebookFollowers', header: 'Facebook', width: 12 },
    { key: 'threadsFollowers', header: 'Threads', width: 12 },
    { key: 'linkedinFollowers', header: 'LinkedIn', width: 12 },
    { key: 'pinterestFollowers', header: 'Pinterest', width: 12 },
    { key: 'snapchatFollowers', header: 'Snapchat', width: 12 },
    { key: 'twitchFollowers', header: 'Twitch', width: 12 },
    { key: 'kickFollowers', header: 'Kick', width: 12 },
    { key: 'trovoFollowers', header: 'Trovo', width: 12 },
    { key: 'redditFollowers', header: 'Reddit', width: 12 },
    { key: 'soundcloudFollowers', header: 'SoundCloud', width: 12 },
    { key: 'applemusicFollowers', header: 'Apple Music', width: 12 },
    { key: 'deezerFollowers', header: 'Deezer', width: 12 },
    { key: 'shopifyFollowers', header: 'Shopify', width: 12 },
    { key: 'woocommerceFollowers', header: 'WooCommerce', width: 14 },
    { key: 'etsyFollowers', header: 'Etsy', width: 12 },
    { key: 'whatsappFollowers', header: 'WhatsApp', width: 12 },
    { key: 'telegramFollowers', header: 'Telegram', width: 12 },
    { key: 'website', header: 'Website', width: 24 },
    { key: 'instagramUrl', header: 'Instagram URL', width: 30 },
    { key: 'tiktokUrl', header: 'TikTok URL', width: 30 },
    { key: 'xUrl', header: 'X URL', width: 30 },
    { key: 'spotifyUrl', header: 'Spotify URL', width: 30 },
    { key: 'youtubeUrl', header: 'YouTube URL', width: 30 },
    { key: 'facebookUrl', header: 'Facebook URL', width: 30 },
    { key: 'notes', header: 'Notes', width: 24 },
  ];

  // Track max content width per column for auto-fit
  const maxWidths = columns.map((col) => col.header.length);

  // Header row
  const headerRow = ws.getRow(currentRow);
  columns.forEach((col, i) => {
    const cell = headerRow.getCell(i + 1);
    cell.value = col.header;
    cell.font = headerFont(10, true);
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: BRAND_COLOR } };
    cell.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
    cell.border = thinBorder();
  });
  headerRow.height = 30;
  currentRow++;

  // Data rows
  rows.forEach((row, rowIdx) => {
    const wsRow = ws.getRow(currentRow);
    const bgColor = rowIdx % 2 === 0 ? WHITE : LIGHT_BG;

    columns.forEach((col, colIdx) => {
      const cell = wsRow.getCell(colIdx + 1);
      let value = row[col.key];

      // Format dates
      if (value instanceof Date && !isNaN(value)) {
        cell.value = value;
        cell.numFmt = 'YYYY-MM-DD HH:mm';
        // Track width for date strings (16 chars for "YYYY-MM-DD HH:mm")
        maxWidths[colIdx] = Math.max(maxWidths[colIdx], 18);
      } else {
        cell.value = value ?? '';
        // Track content width
        const len = String(value ?? '').length;
        if (len > maxWidths[colIdx]) maxWidths[colIdx] = len;
      }

      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: bgColor } };
      cell.border = thinBorder();
      cell.alignment = { vertical: 'middle', wrapText: false };

      // Style numbers — grey for zeros, bold for non-zero
      if (typeof value === 'number') {
        cell.alignment = { horizontal: 'right', vertical: 'middle' };
        cell.numFmt = '#,##0';
        cell.font = value === 0
          ? { name: 'Calibri', size: 9, color: { argb: BRAND_COLOR } }
          : { name: 'Calibri', size: 9, bold: true };
      } else if (col.key === 'status') {
        cell.font = value === 'active'
          ? { name: 'Calibri', size: 9, bold: true, color: { argb: SUCCESS_COLOR } }
          : { name: 'Calibri', size: 9, color: { argb: 'CC4444' } };
      } else {
        cell.font = { name: 'Calibri', size: 9 };
      }
    });

    wsRow.height = 20;
    currentRow++;
  });

  // Auto-fit column widths based on content (with min/max limits)
  columns.forEach((col, i) => {
    const contentWidth = maxWidths[i] + 3; // padding
    ws.getColumn(i + 1).width = Math.max(10, Math.min(contentWidth, 50));
  });

  // Freeze header row of the table
  ws.views = [{ state: 'frozen', ySplit: currentRow - rows.length - 1, xSplit: 3 }];

  // Auto-filter on the data table
  const tableHeaderRow = currentRow - rows.length - 1;
  ws.autoFilter = {
    from: { row: tableHeaderRow, column: 1 },
    to: { row: currentRow - 1, column: columns.length },
  };

  return workbook;
}

// ─── Pre-Registered Export ─────────────────────────────────────────────────

async function queryPreRegistered({ startDate, endDate }) {
  let query = db.collection('users').where('isPreRegister', '==', true);

  if (startDate) {
    query = query.where('preRegisteredAt', '>=', new Date(startDate));
  }
  if (endDate) {
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);
    query = query.where('preRegisteredAt', '<=', end);
  }

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

function buildPreRegRow(user) {
  const ts = (field) => {
    if (!field) return '';
    if (field._seconds) return new Date(field._seconds * 1000);
    if (field.toDate) return field.toDate();
    if (field instanceof Date) return field;
    return new Date(field);
  };

  return {
    userId: user.id || '',
    username: user.username || '',
    preEmail: user.preEmail || user.email || '',
    preRegisteredAt: ts(user.preRegisteredAt),
    wallet: user.wallet || '',
  };
}

async function generatePreRegisteredExcel({ startDate, endDate, adminName }) {
  const users = await queryPreRegistered({ startDate, endDate });
  const rows = users.map(buildPreRegRow);

  /* Sort by preRegisteredAt ascending and assign sequential User ID */
  rows.sort((a, b) => {
    const da = a.preRegisteredAt instanceof Date ? a.preRegisteredAt.getTime() : 0;
    const db = b.preRegisteredAt instanceof Date ? b.preRegisteredAt.getTime() : 0;
    return da - db;
  });
  rows.forEach((r, i) => { r.userId = i + 1; });

  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Migozz';
  workbook.created = new Date();

  const ws = workbook.addWorksheet('Pre-Registered', {
    properties: { defaultColWidth: 18 },
  });

  let currentRow = 1;

  // ── HEADER ────────────────────────────────────────────────────────────

  try {
    const logoId = workbook.addImage({ filename: LOGO_PATH, extension: 'png' });
    ws.addImage(logoId, { tl: { col: 0, row: 0 }, ext: { width: 150, height: 150 } });
  } catch (e) {
    console.warn('[Excel Export] Could not load logo:', e.message);
  }

  ws.getRow(1).height = 115;
  ws.mergeCells('C1:E1');
  const titleCell = ws.getCell('C1');
  titleCell.value = 'Pre-Registered Users Export';
  titleCell.font = { name: 'Calibri', size: 20, bold: true, color: { argb: BRAND_COLOR } };
  titleCell.alignment = { vertical: 'middle' };

  currentRow = 2;
  ws.mergeCells('C2:E2');
  const now = new Date();
  const dateStr = now.toLocaleDateString('en-US', {
    year: 'numeric', month: 'long', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
  const subtitleCell = ws.getCell('C2');
  subtitleCell.value = `Generated: ${dateStr}  |  By: ${adminName || 'System'}`;
  subtitleCell.font = { name: 'Calibri', size: 10, color: { argb: '666666' } };
  subtitleCell.alignment = { vertical: 'middle' };
  ws.getRow(2).height = 22;

  currentRow = 3;
  ws.mergeCells('C3:E3');
  const filterCell = ws.getCell('C3');
  filterCell.value = `Filters — From: ${startDate || 'All'}  To: ${endDate || 'All'}`;
  filterCell.font = { name: 'Calibri', size: 10, italic: true, color: { argb: '999999' } };
  ws.getRow(3).height = 20;

  currentRow = 4;
  ws.getRow(currentRow).height = 10;

  // ── SUMMARY ───────────────────────────────────────────────────────────

  currentRow = 5;
  const SUMMARY_COLS = 4;

  ws.mergeCells(currentRow, 1, currentRow, SUMMARY_COLS);
  const summaryTitleCell = ws.getCell(currentRow, 1);
  summaryTitleCell.value = '  REPORT SUMMARY';
  summaryTitleCell.font = headerFont(12, true);
  summaryTitleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: ACCENT_COLOR } };
  summaryTitleCell.alignment = { vertical: 'middle' };
  for (let c = 1; c <= SUMMARY_COLS; c++) {
    ws.getCell(currentRow, c).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: ACCENT_COLOR } };
  }
  ws.getRow(currentRow).height = 30;
  currentRow++;

  // Total pre-registered KPI
  const labelCell = ws.getCell(currentRow, 1);
  labelCell.value = 'Total Pre-Registered';
  labelCell.font = { name: 'Calibri', size: 9, bold: true, color: { argb: '555555' } };
  labelCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: LIGHT_BG } };
  labelCell.border = thinBorder();
  labelCell.alignment = { vertical: 'middle' };

  const valueCell = ws.getCell(currentRow, 2);
  valueCell.value = rows.length;
  valueCell.numFmt = '#,##0';
  valueCell.font = { name: 'Calibri', size: 12, bold: true, color: { argb: BRAND_COLOR } };
  valueCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: LIGHT_BG } };
  valueCell.border = thinBorder();
  valueCell.alignment = { horizontal: 'center', vertical: 'middle' };
  ws.getRow(currentRow).height = 26;
  currentRow++;

  // Spacer
  ws.getRow(currentRow).height = 12;
  currentRow++;

  // ── DATA TABLE ────────────────────────────────────────────────────────

  const columns = [
    { key: 'userId', header: 'User ID', width: 28 },
    { key: 'username', header: 'Username', width: 22 },
    { key: 'preEmail', header: 'Email', width: 30 },
    { key: 'preRegisteredAt', header: 'Registered At', width: 20 },
    { key: 'wallet', header: 'Wallet', width: 44 },
  ];

  const maxWidths = columns.map((col) => col.header.length);

  // Header row
  const headerRow = ws.getRow(currentRow);
  columns.forEach((col, i) => {
    const cell = headerRow.getCell(i + 1);
    cell.value = col.header;
    cell.font = headerFont(10, true);
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: BRAND_COLOR } };
    cell.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
    cell.border = thinBorder();
  });
  headerRow.height = 30;
  currentRow++;

  // Data rows
  rows.forEach((row, rowIdx) => {
    const wsRow = ws.getRow(currentRow);
    const bgColor = rowIdx % 2 === 0 ? WHITE : LIGHT_BG;

    columns.forEach((col, colIdx) => {
      const cell = wsRow.getCell(colIdx + 1);
      let value = row[col.key];

      if (value instanceof Date && !isNaN(value)) {
        cell.value = value;
        cell.numFmt = 'YYYY-MM-DD HH:mm';
        maxWidths[colIdx] = Math.max(maxWidths[colIdx], 18);
      } else {
        cell.value = value ?? '';
        const len = String(value ?? '').length;
        if (len > maxWidths[colIdx]) maxWidths[colIdx] = len;
      }

      cell.font = { name: 'Calibri', size: 9 };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: bgColor } };
      cell.border = thinBorder();
      cell.alignment = { vertical: 'middle', wrapText: false };
    });

    wsRow.height = 20;
    currentRow++;
  });

  // Auto-fit
  columns.forEach((_, i) => {
    const contentWidth = maxWidths[i] + 3;
    ws.getColumn(i + 1).width = Math.max(10, Math.min(contentWidth, 50));
  });

  // Freeze & auto-filter
  ws.views = [{ state: 'frozen', ySplit: currentRow - rows.length - 1, xSplit: 2 }];
  const tableHeaderRow = currentRow - rows.length - 1;
  ws.autoFilter = {
    from: { row: tableHeaderRow, column: 1 },
    to: { row: currentRow - 1, column: columns.length },
  };

  return workbook;
}

module.exports = { generateMemberExcel, generatePreRegisteredExcel };
