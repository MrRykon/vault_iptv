'use strict';
const $ = (selector) => document.querySelector(selector);
const escapeHTML = (value) => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const movies = [];

const COUNTRY_FLAGS = {
  "afghanistan": "🇦🇫",
  "afganistán": "🇦🇫",
  "albania": "🇦🇱",
  "algeria": "🇩🇿",
  "argelia": "🇩🇿",
  "andorra": "🇦🇩",
  "angola": "🇦🇴",
  "antigua and barbuda": "🇦🇬",
  "antigua y barbuda": "🇦🇬",
  "argentina": "🇦🇷",
  "armenia": "🇦🇲",
  "australia": "🇦🇺",
  "austria": "🇦🇹",
  "azerbaijan": "🇦🇿",
  "azerbaiyán": "🇦🇿",
  "bahamas": "🇧🇸",
  "bahrain": "🇧🇭",
  "baréin": "🇧🇭",
  "barein": "🇧🇭",
  "bangladesh": "🇧🇩",
  "barbados": "🇧🇧",
  "belarus": "🇧🇾",
  "bielorrusia": "🇧🇾",
  "belgium": "🇧🇪",
  "bélgica": "🇧🇪",
  "belice": "🇧🇿",
  "belize": "🇧🇿",
  "benin": "🇧🇯",
  "benín": "🇧🇯",
  "bhutan": "🇧🇹",
  "bután": "🇧🇹",
  "bolivia": "🇧🇴",
  "bosnia and herzegovina": "🇧🇦",
  "bosnia": "🇧🇦",
  "bosnia y herzegovina": "🇧🇦",
  "botswana": "🇧🇼",
  "botsuana": "🇧🇼",
  "brazil": "🇧🇷",
  "brasil": "🇧🇷",
  "brunei": "🇧🇳",
  "bulgaria": "🇧🇬",
  "burkina faso": "🇧🇫",
  "burundi": "🇧🇮",
  "cambodia": "🇰🇭",
  "camboya": "🇰🇭",
  "cameroon": "🇨🇲",
  "camerún": "🇨🇲",
  "canada": "🇨🇦",
  "canadá": "🇨🇦",
  "cape verde": "🇨🇻",
  "cabo verde": "🇨🇻",
  "central african republic": "🇨🇫",
  "república centroafricana": "🇨🇫",
  "chad": "🇹🇩",
  "chile": "🇨🇱",
  "china": "🇨🇳",
  "colombia": "🇨🇴",
  "comoros": "🇰🇲",
  "comoras": "🇰🇲",
  "congo": "🇨🇬",
  "costa rica": "🇨🇷",
  "croatia": "🇭🇷",
  "croacia": "🇭🇷",
  "cuba": "🇨🇺",
  "cyprus": "🇨🇾",
  "chipre": "🇨🇾",
  "czech republic": "🇨🇿",
  "república checa": "🇨🇿",
  "czechia": "🇨🇿",
  "denmark": "🇩🇰",
  "dinamarca": "🇩🇰",
  "djibouti": "🇩🇯",
  "yibuti": "🇩🇯",
  "dominica": "🇩🇲",
  "dominican republic": "🇩🇴",
  "república dominicana": "🇩🇴",
  "republica dominicana": "🇩🇴",
  "dr congo": "🇨🇩",
  "ecuador": "🇪🇨",
  "egypt": "🇪🇬",
  "egipto": "🇪🇬",
  "el salvador": "🇸🇻",
  "equatorial guinea": "🇬🇶",
  "guinea ecuatorial": "🇬🇶",
  "eritrea": "🇪🇷",
  "estonia": "🇪🇪",
  "eswatini": "🇸🇿",
  "ethiopia": "🇪🇹",
  "etiopía": "🇪🇹",
  "fiji": "🇫🇯",
  "fiyi": "🇫🇯",
  "finland": "🇫🇮",
  "finlandia": "🇫🇮",
  "france": "🇫🇷",
  "francia": "🇫🇷",
  "gabon": "🇬🇦",
  "gabón": "🇬🇦",
  "gambia": "🇬🇲",
  "georgia": "🇬🇪",
  "germany": "🇩🇪",
  "alemania": "🇩🇪",
  "ghana": "🇬🇭",
  "greece": "🇬🇷",
  "grecia": "🇬🇷",
  "grenada": "🇬🇩",
  "granada": "🇬🇩",
  "guatemala": "🇬🇹",
  "guinea": "🇬🇳",
  "guinea-bissau": "🇬🇼",
  "guyana": "🇬🇾",
  "haiti": "🇭🇹",
  "haití": "🇭🇹",
  "honduras": "🇭🇳",
  "hong kong": "🇭🇰",
  "hungary": "🇭🇺",
  "hungría": "🇭🇺",
  "iceland": "🇮🇸",
  "islandia": "🇮🇸",
  "india": "🇮🇳",
  "indonesia": "🇮🇩",
  "iran": "🇮🇷",
  "irán": "🇮🇷",
  "iraq": "🇮🇶",
  "irak": "🇮🇶",
  "ireland": "🇮🇪",
  "irlanda": "🇮🇪",
  "israel": "🇮🇱",
  "italy": "🇮🇹",
  "italia": "🇮🇹",
  "ivory coast": "🇨🇮",
  "costa de marfil": "🇨🇮",
  "jamaica": "🇯🇲",
  "japan": "🇯🇵",
  "japón": "🇯🇵",
  "japon": "🇯🇵",
  "jordan": "🇯🇴",
  "jordania": "🇯🇴",
  "kazakhstan": "🇰🇿",
  "kazajistán": "🇰🇿",
  "kenya": "🇰🇪",
  "kenia": "🇰🇪",
  "kiribati": "🇰🇮",
  "kosovo": "🇽🇰",
  "kuwait": "🇰🇼",
  "kyrgyzstan": "🇰🇬",
  "kirguistán": "🇰🇬",
  "laos": "🇱🇦",
  "latvia": "🇱🇻",
  "letonia": "🇱🇻",
  "lebanon": "🇱🇧",
  "líbano": "🇱🇧",
  "libano": "🇱🇧",
  "lesotho": "🇱🇸",
  "lesoto": "🇱🇸",
  "liberia": "🇱🇷",
  "libya": "🇱🇾",
  "libia": "🇱🇾",
  "liechtenstein": "🇱🇮",
  "lithuania": "🇱🇹",
  "lituania": "🇱🇹",
  "luxembourg": "🇱🇺",
  "luxemburgo": "🇱🇺",
  "madagascar": "🇲🇬",
  "malawi": "🇲🇼",
  "malaui": "🇲🇼",
  "malaysia": "🇲🇾",
  "malasia": "🇲🇾",
  "maldives": "🇲🇻",
  "maldivas": "🇲🇻",
  "mali": "🇲🇱",
  "malí": "🇲🇱",
  "malta": "🇲🇹",
  "mauritania": "🇲🇷",
  "mauritius": "🇲🇺",
  "mauricio": "🇲🇺",
  "mexico": "🇲🇽",
  "méxico": "🇲🇽",
  "moldova": "🇲🇩",
  "moldavia": "🇲🇩",
  "monaco": "🇲🇨",
  "mónaco": "🇲🇨",
  "mongolia": "🇲🇳",
  "montenegro": "🇲🇪",
  "morocco": "🇲🇦",
  "marruecos": "🇲🇦",
  "mozambique": "🇲🇿",
  "myanmar": "🇲🇲",
  "namibia": "🇳🇦",
  "nepal": "🇳🇵",
  "netherlands": "🇳🇱",
  "países bajos": "🇳🇱",
  "holanda": "🇳🇱",
  "new zealand": "🇳🇿",
  "nueva zelanda": "🇳🇿",
  "nicaragua": "🇳🇮",
  "niger": "🇳🇪",
  "níger": "🇳🇪",
  "nigeria": "🇳🇬",
  "north korea": "🇰🇵",
  "corea del norte": "🇰🇵",
  "north macedonia": "🇲🇰",
  "macedonia del norte": "🇲🇰",
  "macedonia": "🇲🇰",
  "norway": "🇳🇴",
  "noruega": "🇳🇴",
  "oman": "🇴🇲",
  "omán": "🇴🇲",
  "pakistan": "🇵🇰",
  "pakistán": "🇵🇰",
  "palestine": "🇵🇸",
  "palestina": "🇵🇸",
  "panama": "🇵🇦",
  "panamá": "🇵🇦",
  "papua new guinea": "🇵🇬",
  "papúa nueva guinea": "🇵🇬",
  "paraguay": "🇵🇾",
  "peru": "🇵🇪",
  "perú": "🇵🇪",
  "philippines": "🇵🇭",
  "filipinas": "🇵🇭",
  "poland": "🇵🇱",
  "polonia": "🇵🇱",
  "portugal": "🇵🇹",
  "puerto rico": "🇵🇷",
  "qatar": "🇶🇦",
  "catar": "🇶🇦",
  "romania": "🇷🇴",
  "rumania": "🇷🇴",
  "russia": "🇷🇺",
  "rusia": "🇷🇺",
  "rwanda": "🇷🇼",
  "ruanda": "🇷🇼",
  "saint kitts and nevis": "🇰🇳",
  "san cristóbal y nieves": "🇰🇳",
  "saint lucia": "🇱🇨",
  "santa lucía": "🇱🇨",
  "saint vincent": "🇻🇨",
  "san vicente": "🇻🇨",
  "samoa": "🇼🇸",
  "san marino": "🇸🇲",
  "saudi arabia": "🇸🇦",
  "arabia saudita": "🇸🇦",
  "arabia saudí": "🇸🇦",
  "senegal": "🇸🇳",
  "serbia": "🇷🇸",
  "seychelles": "🇸🇨",
  "sierra leone": "🇸🇱",
  "sierra leona": "🇸🇱",
  "singapore": "🇸🇬",
  "singapur": "🇸🇬",
  "slovakia": "🇸🇰",
  "eslovaquia": "🇸🇰",
  "slovenia": "🇸🇮",
  "eslovenia": "🇸🇮",
  "somalia": "🇸🇴",
  "south africa": "🇿🇦",
  "sudáfrica": "🇿🇦",
  "south korea": "🇰🇷",
  "corea del sur": "🇰🇷",
  "south sudan": "🇸🇸",
  "sudán del sur": "🇸🇸",
  "spain": "🇪🇸",
  "españa": "🇪🇸",
  "sri lanka": "🇱🇰",
  "sudan": "🇸🇩",
  "sudán": "🇸🇩",
  "suriname": "🇸🇷",
  "sweden": "🇸🇪",
  "suecia": "🇸🇪",
  "switzerland": "🇨🇭",
  "suiza": "🇨🇭",
  "syria": "🇸🇾",
  "siria": "🇸🇾",
  "taiwan": "🇹🇼",
  "taiwán": "🇹🇼",
  "tajikistan": "🇹🇯",
  "tayikistán": "🇹🇯",
  "tanzania": "🇹🇿",
  "thailand": "🇹🇭",
  "tailandia": "🇹🇭",
  "togo": "🇹🇬",
  "trinidad and tobago": "🇹🇹",
  "trinidad y tobago": "🇹🇹",
  "tunisia": "🇹🇳",
  "túnez": "🇹🇳",
  "tunez": "🇹🇳",
  "turkey": "🇹🇷",
  "turquía": "🇹🇷",
  "turquia": "🇹🇷",
  "türkiye": "🇹🇷",
  "turkmenistan": "🇹🇲",
  "turkmenistán": "🇹🇲",
  "uganda": "🇺🇬",
  "ukraine": "🇺🇦",
  "ucrania": "🇺🇦",
  "united arab emirates": "🇦🇪",
  "emiratos árabes unidos": "🇦🇪",
  "uae": "🇦🇪",
  "united kingdom": "🇬🇧",
  "reino unido": "🇬🇧",
  "uk": "🇬🇧",
  "united states": "🇺🇸",
  "estados unidos": "🇺🇸",
  "usa": "🇺🇸",
  "eeuu": "🇺🇸",
  "uruguay": "🇺🇾",
  "uzbekistan": "🇺🇿",
  "uzbekistán": "🇺🇿",
  "vatican": "🇻🇦",
  "vaticano": "🇻🇦",
  "venezuela": "🇻🇪",
  "vietnam": "🇻🇳",
  "yemen": "🇾🇪",
  "zambia": "🇿🇲",
  "zimbabwe": "🇿🇼"
};

function getCountryFlag(country) {
  if (!country) return '🌐';
  const clean = String(country).trim();
  const lower = clean.toLowerCase();
  return COUNTRY_FLAGS[lower] || COUNTRY_FLAGS[clean] || '🌐';
}
const COUNTRY_TRANSLATIONS = {
  'afghanistan': 'Afganistán', 'albania': 'Albania', 'algeria': 'Argelia',
  'argentina': 'Argentina', 'brasil': 'Brasil', 'brazil': 'Brasil',
  'colombia': 'Colombia', 'ecuador': 'Ecuador', 'italia': 'Italia',
  'italy': 'Italia', 'japon': 'Japón', 'japan': 'Japón', 'mexico': 'México',
  'méxico': 'México', 'paraguay': 'Paraguay', 'peru': 'Perú', 'perú': 'Perú',
  'puerto rico': 'Puerto Rico', 'espana': 'España', 'españa': 'España',
  'spain': 'España', 'united states': 'Estados Unidos', 'estados unidos': 'Estados Unidos',
  'usa': 'Estados Unidos', 'uruguay': 'Uruguay', 'venezuela': 'Venezuela',
  'chile': 'Chile', 'bolivia': 'Bolivia', 'costa rica': 'Costa Rica',
  'cuba': 'Cuba', 'republica dominicana': 'República Dominicana',
  'dominican republic': 'República Dominicana', 'guatemala': 'Guatemala',
  'honduras': 'Honduras', 'nicaragua': 'Nicaragua', 'panama': 'Panamá',
  'panamá': 'Panamá', 'el salvador': 'El Salvador', 'francia': 'Francia',
  'france': 'Francia', 'alemania': 'Alemania', 'germany': 'Alemania',
  'reino unido': 'Reino Unido', 'united kingdom': 'Reino Unido',
  'uk': 'Reino Unido', 'canada': 'Canadá', 'canadá': 'Canadá',
  'internacional': 'Internacional', 'international': 'Internacional'
};

const CATEGORY_MAP = {
  'news': 'Noticias', 'noticias': 'Noticias',
  'sports': 'Deportes', 'sport': 'Deportes', 'deportes': 'Deportes',
  'kids': 'Infantil', 'children': 'Infantil', 'animation': 'Infantil', 'family': 'Infantil', 'infantil': 'Infantil',
  'movies': 'Películas', 'movie': 'Películas', 'cinema': 'Películas', 'film': 'Películas', 'peliculas': 'Películas',
  'series': 'Series',
  'music': 'Música', 'musica': 'Música',
  'documentary': 'Documentales', 'documentales': 'Documentales',
  'comedy': 'Comedia', 'comedia': 'Comedia',
  'entertainment': 'Entretenimiento', 'entretenimiento': 'Entretenimiento',
  'cooking': 'Cocina', 'cocina': 'Cocina',
  'culture': 'Cultura', 'cultura': 'Cultura',
  'education': 'Educación', 'educacion': 'Educación',
  'business': 'Negocios', 'negocios': 'Negocios',
  'religious': 'Religión', 'religion': 'Religión',
  'weather': 'Clima', 'clima': 'Clima',
  'travel': 'Viajes', 'outdoor': 'Viajes',
  'general': 'General', 'undefined': 'General', 'public': 'General'
};

const CATEGORY_ICONS = {
  'Deportes': '⚽', 'Noticias': '📰', 'Infantil': '👶', 'Películas': '🎬',
  'Series': '📺', 'Música': '🎵', 'Documentales': '🦁', 'Entretenimiento': '🎭',
  'Comedia': '😄', 'Cocina': '🍳', 'Cultura': '🏛️', 'Educación': '📚',
  'Negocios': '💼', 'Religión': '⛪', 'Clima': '☀️', 'Viajes': '✈️', 'General': '📡'
};

function getCategoryIcon(cat) {
  if (!cat) return '📡';
  if (CATEGORY_ICONS[cat]) return CATEGORY_ICONS[cat];
  const flag = getCountryFlag(cat);
  if (flag && flag !== '🌐') return flag;
  return '📡';
}

const state = {
  demo: false, demoAdmin: false, device: 'web', tab: 'home',
  countryFilter: 'Todos', categoryFilter: 'Todas', filter: 'Todos', listFilter: 'all',
  online: false, serverDetected: false, server: '', token: '', user: null,
  authMode: 'login', showServerField: false,
  channels: [], serverChannels: [], userLists: [], library: [], notes: [], xtream: [],
  previewNotice: '', favorites: new Set(), recent: [], channelView: 'Todos',
  query: '', alphabetical: false, channelEtag: '', channelPageLimit: 60,
  saved: new Set(), readNotices: new Set(), compact: false,
  libraryType: 'all', librarySavedOnly: false, libraryQuery: '',
  playingItem: null, playingIndex: 0, playerQuery: '', previousTab: 'live',
  playerGuideMode: 'country', playerGuideValue: '', playerAspectRatio: 'contain',
  sleepTimer: null, sleepTimerMinutes: 0,
  webEpisodes: [], webSeries: [], webHistory: [], webExtractorLoading: false,
  noAds: false
};

let toastTimer;
let syncing = false;
const CURRENT_APP_VERSION = '0.0.8';
const CURRENT_APP_BUILD = 5;
let currentChannelIndex = 0;

function channelId(channel) { return String(channel.channel_id || channel.stream_url || channel.channel_name); }

function preferenceKey() { return 'vault_channels_' + JSON.stringify([state.server || 'local', state.user?.custom_username || 'guest']); }
function loadChannelPreferences() {
  state.favorites = new Set(); state.recent = []; state.channelView = 'Todos'; state.query = ''; state.channelEtag = '';
  try {
    const saved = JSON.parse(localStorage.getItem(preferenceKey()) || '{}');
    if (Array.isArray(saved.favorites)) state.favorites = new Set(saved.favorites.filter(id => typeof id === 'string'));
    if (Array.isArray(saved.recent)) state.recent = saved.recent.filter(id => typeof id === 'string').slice(0, 20);
  } catch { /* Private browsing or malformed preferences must not block the app. */ }
}
function saveChannelPreferences() {
  try { localStorage.setItem(preferenceKey(), JSON.stringify({ favorites: [...state.favorites], recent: state.recent })); }
  catch { toast('No se pudieron guardar las preferencias en este navegador.'); }
}
function markRecent(channel) {
  const id = channelId(channel); state.recent = [id, ...state.recent.filter(value => value !== id)].slice(0, 20); saveChannelPreferences();
}

function libraryId(item) { return String(item.id || item.title); }
function notificationId(note) {
  if (note.id != null) return String(note.id);
  let hash = 2166136261;
  for (const character of `${note.subject}\n${note.content}`) hash = Math.imul(hash ^ character.charCodeAt(0), 16777619);
  return 'notice-' + (hash >>> 0).toString(16);
}
function libraryPreferenceKey() { return 'vault_library_' + JSON.stringify([state.server || 'local', state.user?.custom_username || 'guest']); }
function loadLibraryPreferences() {
  state.saved = new Set(); state.readNotices = new Set(); state.compact = false;
  state.libraryType = 'all'; state.librarySavedOnly = false; state.libraryQuery = '';
  try {
    const record = JSON.parse(localStorage.getItem(libraryPreferenceKey()) || '{}');
    if (Array.isArray(record.saved)) state.saved = new Set(record.saved.filter(value => typeof value === 'string'));
    if (Array.isArray(record.read)) state.readNotices = new Set(record.read.filter(value => typeof value === 'string'));
    state.compact = record.compact === true;
  } catch { /* Preferences are optional. */ }
}
function saveLibraryPreferences() {
  try { localStorage.setItem(libraryPreferenceKey(), JSON.stringify({ saved: [...state.saved], read: [...state.readNotices], compact: state.compact })); }
  catch { toast('No se pudieron guardar las preferencias en este navegador.'); }
}

const USER_LISTS_KEY = 'vault_user_lists';
function loadUserLists() {
  state.userLists = [];
  try {
    const raw = localStorage.getItem(USER_LISTS_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        state.userLists = parsed.filter(l => l && typeof l.id === 'string' && Array.isArray(l.channels));
      }
    }
  } catch { state.userLists = []; }
  rebuildChannelsFromLists();
}
function saveUserLists() {
  try {
    localStorage.setItem(USER_LISTS_KEY, JSON.stringify(state.userLists));
  } catch {
    toast('No se pudieron guardar las listas en el almacenamiento local.');
  }
}
function rebuildChannelsFromLists() {
  const userChannels = [];
  for (const list of state.userLists) {
    for (const ch of (list.channels || [])) {
      userChannels.push({
        ...ch,
        listId: list.id,
        listName: list.name
      });
    }
  }
  const combined = [...userChannels, ...(state.serverChannels || [])];
  state.channels = combined;
}

function normalizeClientCategory(rawGroup) {
  if (!rawGroup) return 'General';
  const parts = String(rawGroup).split(';').map(g => g.trim().toLowerCase()).filter(Boolean);
  for (const p of parts) {
    if (CATEGORY_MAP[p]) return CATEGORY_MAP[p];
  }
  for (const p of parts) {
    for (const [k, v] of Object.entries(CATEGORY_MAP)) {
      if (p.includes(k)) return v;
    }
  }
  return rawGroup.split(';')[0].trim() || 'General';
}
function normalizeClientCountry(rawCountry) {
  if (!rawCountry) return 'Internacional';
  const k = String(rawCountry).trim().toLowerCase();
  if (COUNTRY_TRANSLATIONS[k]) return COUNTRY_TRANSLATIONS[k];
  return String(rawCountry).trim() || 'Internacional';
}
function hashStr(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h = Math.imul(h ^ str.charCodeAt(i), 16777619);
  }
  return (h >>> 0).toString(16);
}

function parseM3UContent(content, listName, listId, sourceUrl = '') {
  const clean = String(content || '').replace(/^\uFEFF/, '').trim();
  const channels = [];
  if (clean.includes('#EXTINF:')) {
    let metadata = null;
    const lines = clean.split(/\r?\n/);
    for (let rawLine of lines) {
      const line = rawLine.trim();
      if (!line) continue;
      if (line.startsWith('#EXTINF:')) {
        const attrs = {};
        const attrRegex = /([\w-]+)="([^"]*)"/g;
        let match;
        while ((match = attrRegex.exec(line)) !== null) {
          attrs[match[1].toLowerCase()] = match[2];
        }
        const commaMatch = line.match(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/);
        const rawTitle = commaMatch ? line.slice(commaMatch.index + 1).trim() : '';
        const name = attrs['tvg-name'] || rawTitle || 'Canal IPTV';
        metadata = { attrs, name };
      } else if (line.startsWith('#EXTGRP:') && metadata && !metadata.attrs['group-title']) {
        metadata.attrs['group-title'] = line.slice(8).trim();
      } else if (!line.startsWith('#') && metadata) {
        const url = safeURL(line);
        const { attrs, name } = metadata;
        metadata = null;
        if (!url) continue;
        const category = normalizeClientCategory(attrs['group-title']);
        const country = normalizeClientCountry(attrs['tvg-country']);
        channels.push({
          channel_id: `${listId}_${hashStr(url)}`,
          channel_name: name,
          stream_url: url,
          logo_url: attrs['tvg-logo'] || '',
          category,
          country,
          language: attrs['tvg-language'] || '',
          current_program: 'Transmisión en vivo',
          program_time: 'En vivo',
          is_online: true,
          listId,
          listName
        });
      }
    }
  } else if (clean.includes('#EXT-X-') || /\.(m3u8|mp4|ts|mkv)(\?|$)/i.test(sourceUrl)) {
    const url = safeURL(sourceUrl);
    if (url) {
      channels.push({
        channel_id: `${listId}_${hashStr(url)}`,
        channel_name: listName || 'Canal IPTV',
        stream_url: url,
        logo_url: '',
        category: 'General',
        country: 'Internacional',
        current_program: 'Transmisión en vivo',
        program_time: 'En vivo',
        is_online: true,
        listId,
        listName
      });
    }
  } else {
    // Plain text list of stream URLs (one per line)
    const lines = clean.split(/\r?\n/);
    let idx = 1;
    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) continue;
      const url = safeURL(line);
      if (url) {
        channels.push({
          channel_id: `${listId}_${hashStr(url)}`,
          channel_name: `${listName || 'Canal'} ${idx++}`,
          stream_url: url,
          logo_url: '',
          category: 'General',
          country: 'Internacional',
          current_program: 'Transmisión en vivo',
          program_time: 'En vivo',
          is_online: true,
          listId,
          listName
        });
      }
    }
  }
  return channels;
}

async function fetchAndAddM3UList(name, rawUrl, existingListId = null) {
  const url = safeURL(rawUrl.trim());
  if (!url) throw new Error('Ingresa una URL válida que empiece con http:// o https://');

  const listId = existingListId || ('list_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6));
  const listName = (name || '').trim() || new URL(url).hostname || 'Lista IPTV';
  let parsedChannels = [];
  let directError = null;

  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(25000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const text = await res.text();
    const trimmed = text.trim();
    if (trimmed.toLowerCase().startsWith('<!doctype html') || trimmed.toLowerCase().startsWith('<html')) {
      throw new Error('La URL devolvió una página HTML en lugar de una lista IPTV. Verifica que el enlace sea el enlace directo al archivo .m3u o .m3u8.');
    }
    parsedChannels = parseM3UContent(text, listName, listId, url);
  } catch (err) {
    directError = err;
  }

  if (!parsedChannels.length && state.server && state.serverDetected && state.online) {
    try {
      const data = await api('/iptv/parse-url', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url, name: listName })
      });
      if (Array.isArray(data.channels)) {
        parsedChannels = data.channels.map(ch => ({
          ...ch,
          channel_id: `${listId}_${ch.channel_id || hashStr(ch.stream_url)}`,
          listId,
          listName
        }));
      }
    } catch (_) {}
  }

  if (!parsedChannels.length) {
    if (directError) {
      const msg = directError.message || '';
      if (msg.includes('HTTP 404')) {
        throw new Error('Error 404: La URL de la lista no existe o está incompleta. Verifica la dirección del enlace.');
      }
      if (msg.includes('HTTP')) {
        throw new Error(`El servidor respondió con error (${msg}). Verifica el enlace.`);
      }
      if (directError.name === 'TimeoutError' || msg.includes('timeout')) {
        throw new Error('Tiempo de espera agotado al descargar la lista. Verifica tu conexión a internet.');
      }
      throw new Error(msg || 'No se pudo descargar la lista desde la URL. Verifica tu conexión.');
    }
    throw new Error('La URL no contiene canales IPTV válidos (.m3u o .m3u8).');
  }

  const record = {
    id: listId,
    type: 'm3u',
    name: listName,
    url,
    username: '',
    password: '',
    section: 'live',
    addedAt: new Date().toISOString(),
    channels: parsedChannels
  };

  if (existingListId) {
    const idx = state.userLists.findIndex(l => l.id === existingListId);
    if (idx >= 0) state.userLists[idx] = record;
    else state.userLists.unshift(record);
  } else {
    state.userLists.unshift(record);
  }

  saveUserLists();
  rebuildChannelsFromLists();
  return record;
}

async function fetchAndAddXtreamList({ name, server, username, password, section = 'live' }, existingListId = null) {
  const origin = serverURL(server);
  const userTrim = (username || '').trim();
  const passTrim = password || '';
  if (!userTrim || !passTrim) throw new Error('Ingresa usuario y contraseña de Xtream Codes.');

  const listId = existingListId || ('list_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6));
  const listName = (name || '').trim() || new URL(origin).hostname || 'Xtream Codes';
  const actions = { live: 'get_live_streams', vod: 'get_vod_streams', series: 'get_series' };
  const action = actions[section] || 'get_live_streams';

  let items = [];
  let directError = null;

  try {
    const authUrl = `${origin}/player_api.php?username=${encodeURIComponent(userTrim)}&password=${encodeURIComponent(passTrim)}`;
    const authRes = await fetch(authUrl, { signal: AbortSignal.timeout(15000) });
    if (!authRes.ok) throw new Error(`HTTP ${authRes.status}`);
    const authData = await authRes.json();
    if (!authData || String(authData?.user_info?.auth) !== '1' || authData?.user_info?.status !== 'Active') {
      throw new Error('Credenciales Xtream incorrectas o cuenta inactiva.');
    }
    const catRes = await fetch(`${authUrl}&action=${action}`, { signal: AbortSignal.timeout(20000) });
    if (!catRes.ok) throw new Error(`HTTP ${catRes.status}`);
    const raw = await catRes.json();
    if (!Array.isArray(raw)) throw new Error('Catálogo Xtream inválido.');

    items = raw.map(item => {
      const ident = String(section === 'series' ? (item.series_id || '') : (item.stream_id || ''));
      if (!/^\d+$/.test(ident)) return null;
      const ext = section === 'vod' ? String(item.container_extension || 'mp4').replace(/[^a-zA-Z0-9]/g, '') || 'mp4' : 'm3u8';
      const kind = section === 'vod' ? 'movie' : 'live';
      const streamUrl = section === 'series' ? '' : `${origin}/${kind}/${encodeURIComponent(userTrim)}/${encodeURIComponent(passTrim)}/${ident}.${ext}`;
      return {
        id: ident,
        channel_id: `${listId}_xt_${ident}`,
        channel_name: item.name || 'Xtream',
        title: item.name || 'Xtream',
        stream_url: streamUrl,
        logo_url: item.stream_icon || item.cover || '',
        poster: item.stream_icon || item.cover || '',
        category: section === 'vod' ? 'Películas' : section === 'series' ? 'Series' : 'General',
        country: 'Xtream',
        type: section,
        series_id: section === 'series' ? Number(ident) : undefined,
        current_program: section === 'vod' ? 'Película bajo demanda' : section === 'series' ? 'Serie Xtream' : 'En vivo',
        program_time: section === 'live' ? 'En vivo' : 'VOD',
        is_online: true,
        listId,
        listName
      };
    }).filter(Boolean);
  } catch (err) {
    directError = err;
  }

  if (!items.length && state.server) {
    try {
      const result = await api('/xtream/catalog', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ server: origin, username: userTrim, password: passTrim, section })
      });
      if (Array.isArray(result.items)) {
        items = result.items.map(item => ({
          id: String(item.id || ''),
          channel_id: `${listId}_xt_${item.id || hashStr(item.title || '')}`,
          channel_name: item.title || 'Xtream',
          title: item.title || 'Xtream',
          stream_url: item.stream_url || '',
          logo_url: item.poster || '',
          poster: item.poster || '',
          category: section === 'vod' ? 'Películas' : section === 'series' ? 'Series' : 'General',
          country: 'Xtream',
          type: item.type || section,
          series_id: section === 'series' ? Number(item.id) : undefined,
          current_program: section === 'vod' ? 'Película bajo demanda' : section === 'series' ? 'Serie Xtream' : 'En vivo',
          program_time: section === 'live' ? 'En vivo' : 'VOD',
          is_online: true,
          listId,
          listName
        }));
      }
    } catch (proxyErr) {
      throw new Error(proxyErr.message || (directError ? directError.message : 'No se pudo conectar con Xtream Codes.'));
    }
  }

  if (!items.length) {
    if (directError) throw directError;
    throw new Error('No se encontraron canales en esta cuenta Xtream.');
  }

  const record = {
    id: listId,
    type: 'xtream',
    name: listName,
    url: origin,
    username: userTrim,
    password: passTrim,
    section,
    addedAt: new Date().toISOString(),
    channels: items
  };

  if (existingListId) {
    const idx = state.userLists.findIndex(l => l.id === existingListId);
    if (idx >= 0) state.userLists[idx] = record;
    else state.userLists.unshift(record);
  } else {
    state.userLists.unshift(record);
  }

  state.xtream = items;
  saveUserLists();
  rebuildChannelsFromLists();
  return record;
}

function activeNotes() { return state.notes || []; }
function unreadNotes() { return activeNotes().filter(note => !state.readNotices.has(notificationId(note))); }
function inbox() {
  dialog(`<span class="eyebrow">TU BANDEJA</span><h2>Avisos de Vault</h2><p class="muted">${unreadNotes().length} sin leer</p><button id="read-all-notes" class="secondary-button" ${unreadNotes().length ? '' : 'disabled'}>Marcar todos como leídos</button><div class="inbox-list">${activeNotes().map((note, index) => `<article class="inbox-note ${state.readNotices.has(notificationId(note)) ? 'read' : ''}"><h3>${escapeHTML(note.subject)}</h3><p>${escapeHTML(note.content)}</p><button data-read-note="${index}" class="quiet-button" ${state.readNotices.has(notificationId(note)) ? 'disabled' : ''}>${state.readNotices.has(notificationId(note)) ? 'Leído' : 'Marcar como leído'}</button></article>`).join('') || '<p class="muted">No hay avisos por ahora.</p>'}</div>`);
}

let notifTimer = null;

function showNotification({ title = 'Aviso', message = '', type = 'info', icon = 'ℹ️', badge = 'Vault', actionText = '', onAction = null, duration = 5000 }) {
  const card = $('#vault-notification');
  if (!card) {
    const t = $('#toast');
    if (t) {
      t.textContent = message;
      t.hidden = false;
      clearTimeout(toastTimer);
      toastTimer = setTimeout(() => t.hidden = true, duration || 4500);
    }
    return;
  }

  clearTimeout(notifTimer);
  card.className = `vault-notification-card ${type}`;
  const titleEl = $('#notif-title');
  const descEl = $('#notif-desc');
  const iconEl = $('#notif-icon-symbol');
  const badgeEl = $('#notif-badge');

  if (titleEl) titleEl.textContent = title;
  if (descEl) descEl.textContent = message;
  if (iconEl) iconEl.textContent = icon;
  if (badgeEl) badgeEl.textContent = badge;

  const actionsRow = $('#notif-actions-row');
  if (actionsRow) {
    if (actionText && typeof onAction === 'function') {
      actionsRow.innerHTML = `<button type="button" class="notif-action-btn" id="notif-custom-action">${escapeHTML(actionText)}</button>`;
      actionsRow.hidden = false;
      const btn = $('#notif-custom-action');
      if (btn) {
        btn.onclick = (e) => {
          e.stopPropagation();
          hideNotification();
          onAction();
        };
      }
    } else {
      actionsRow.innerHTML = '';
      actionsRow.hidden = true;
    }
  }

  card.hidden = false;
  card.classList.remove('notif-hiding');

  if (duration > 0) {
    notifTimer = setTimeout(() => hideNotification(), duration);
  }
}

function hideNotification() {
  const card = $('#vault-notification');
  if (!card || card.hidden) return;
  card.classList.add('notif-hiding');
  clearTimeout(notifTimer);
  notifTimer = setTimeout(() => {
    card.hidden = true;
    card.classList.remove('notif-hiding');
  }, 250);
}

function toast(message, type = 'info') {
  let icon = 'ℹ️';
  let title = 'Aviso';
  if (type === 'success' || message.includes('✓') || message.includes('éxito') || message.includes('🎉') || message.includes('agregada') || message.includes('conectada')) {
    type = 'playlist-added';
    icon = '✓';
    title = 'Completado';
  } else if (type === 'error' || message.includes('Error') || message.includes('No se pudo') || message.includes('interrumpida')) {
    type = 'offline';
    icon = '⚠️';
    title = 'Atención';
  }
  showNotification({ title, message, type, icon, badge: 'Vault', duration: 4500 });
}
function safeURL(value) {
  if (!value || typeof value !== 'string') return '';
  const trimmed = value.trim();
  try {
    const url = new URL(trimmed);
    if (['http:', 'https:'].includes(url.protocol)) {
      return url.href;
    }
  } catch (_) {
    try {
      const fixed = encodeURI(trimmed);
      const url = new URL(fixed);
      if (['http:', 'https:'].includes(url.protocol)) {
        return url.href;
      }
    } catch (_) {}
  }
  return '';
}
function serverURL(value) {
  let val = (value || '').trim();
  if (!val) throw new Error('Ingresa la dirección del servidor');
  if (!/^https?:\/\//i.test(val)) {
    val = (typeof location !== 'undefined' && location.protocol === 'https:' ? 'https://' : 'http://') + val;
  }
  const url = new URL(val);
  if (!['http:', 'https:'].includes(url.protocol) || url.search || url.hash) throw new Error('Usa la dirección del servidor sin rutas: http://host:puerto');
  if (typeof location !== 'undefined' && location.protocol === 'https:' && url.protocol !== 'https:') throw new Error('Esta web HTTPS necesita un servidor HTTPS. Para una red local abre la vista desde tu servidor Vault.');
  return url.origin;
}

async function api(path, options = {}) {
  const server = state.server, token = state.token;
  if (!server) throw new Error('No hay servidor configurado.');
  const response = await fetch(server + path, { ...options, signal: AbortSignal.timeout(12000), headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), ...options.headers } });
  if (server !== state.server || token !== state.token) throw new Error('La sesión cambió mientras se cargaba el contenido.');
  if (path === '/iptv/channels' && response.status === 304) return state.serverChannels;
  
  const cType = response.headers.get('content-type') || '';
  if (!cType.includes('application/json')) {
    if (!response.ok) throw new Error(`Error en el servidor (${response.status}).`);
    throw new Error('Respuesta inválida del servidor (no es JSON).');
  }

  if (!response.ok) {
    if (state.token && [401, 403].includes(response.status) && !path.startsWith('/xtream/')) {
      state.token = ''; state.user = null;
      try { localStorage.removeItem('vault_session'); } catch (_) {}
      updateHeaderProfile();
      render();
      throw new Error('Tu sesión expiró. Puedes volver a iniciar sesión desde tu perfil.');
    }
    const error = await response.json().catch(() => ({}));
    throw new Error(typeof error.detail === 'string' ? error.detail : `No se pudo completar la solicitud (${response.status}).`);
  }
  if (path === '/iptv/channels') state.channelEtag = response.headers.get('etag') || '';
  return response.json();
}

function updateHeaderProfile() {
  const btn = $('#header-profile-btn');
  const avatar = $('#header-profile-avatar');
  const label = $('#header-profile-label');
  if (!btn || !avatar || !label) return;
  if (state.token && state.user) {
    const name = state.user.display_name || state.user.custom_username || 'Usuario';
    avatar.textContent = name.slice(0, 1).toUpperCase();
    label.textContent = name;
    btn.classList.add('logged-in');
  } else {
    avatar.textContent = '👤';
    label.textContent = 'Mi Perfil';
    btn.classList.remove('logged-in');
  }
}

function showApp() {
  const vaultView = $('#vault-view');
  if (vaultView) vaultView.hidden = false;
  updateHeaderProfile();
  render();
}
function showLogin() {
  state.tab = 'profile';
  showApp();
}

function setDevice(device) {
  state.device = device; $('#device-frame').dataset.device = device;
  document.querySelectorAll('[data-device]').forEach(button => { if (button.tagName === 'BUTTON') button.setAttribute('aria-pressed', String(button.dataset.device === device)); });
  $('#device-caption').textContent = { web: 'Vista web adaptable', phone: 'Teléfono Android · 390 px', tv: 'Chromecast con Google TV · formato 16:9' }[device];
  $('#preview-help').textContent = device === 'tv' ? 'Usa las flechas del teclado y Enter como un mando. En pantallas pequeñas, desplaza el marco horizontalmente. Esta vista no transmite a un Chromecast.' : 'Vault: agrega tus listas IPTV o Xtream Codes y disfruta tus canales en cualquier pantalla.';
}


function updateOnlineStatus() {
  const isOnline = navigator.onLine;
  const banner = $('#offline-status-banner');
  if (!isOnline) {
    if (banner) banner.hidden = false;
    showNotification({
      title: 'Sin conexión a Internet',
      message: 'Estás navegando sin conexión. Tus listas y canales guardados siguen disponibles en modo local.',
      type: 'offline',
      icon: '📡',
      badge: 'OFFLINE',
      actionText: '↻ Reintentar',
      onAction: () => {
        toast('Comprobando conexión de red…');
        updateOnlineStatus();
      },
      duration: 6500
    });
  } else {
    if (banner) banner.hidden = true;
    if (state._wasOffline) {
      showNotification({
        title: 'Conexión Restablecida',
        message: 'Tu dispositivo está nuevamente en línea. Transmisiones y listas sincronizadas.',
        type: 'online',
        icon: '🟢',
        badge: 'EN LÍNEA',
        duration: 4000
      });
    }
  }
  state._wasOffline = !isOnline;
  connection();
}
window.addEventListener('online', updateOnlineStatus);
window.addEventListener('offline', updateOnlineStatus);

function connection() {
  const el = $('#connection');
  if (!el) return;
  if (state.online && state.token) {
    el.className = 'connection online';
    el.innerHTML = '<i></i>Conectado';
  } else if (state.serverDetected) {
    el.className = 'connection online';
    el.innerHTML = '<i></i>Servidor listo';
  } else {
    el.className = 'connection';
    el.innerHTML = '<i></i>Modo local';
  }
}

function openAddM3UDialog() {
  dialog(`
    <span class="eyebrow">NUEVA LISTA IPTV</span>
    <h2>Agregar IPTV con URL</h2>
    <p class="muted">Pega la URL directa de tu lista .M3U o .M3U8 para cargar todos tus canales.</p>
    <form id="add-m3u-form">
      <label>Nombre de la lista
        <input name="name" type="text" placeholder="Ej. TV Abierta / Deportes" maxlength="80" required>
      </label>
      <label>URL de la lista (.m3u / .m3u8)
        <input name="url" type="url" placeholder="https://ejemplo.com/lista.m3u" required>
      </label>
      <p class="form-message" id="add-m3u-message" role="status"></p>
      <div style="display:flex;gap:10px;margin-top:16px">
        <button class="primary-button" type="submit" style="flex:1">Agregar lista <span>→</span></button>
        <button type="button" id="close-dialog" class="secondary-button" style="width:auto">Cancelar</button>
      </div>
    </form>
  `);
}

function openAddXtreamDialog() {
  dialog(`
    <span class="eyebrow">PROVEEDOR XTREAM CODES</span>
    <h2>Agregar Xtream Codes</h2>
    <p class="muted">Conecta con los datos de tu proveedor para importar TV en vivo, películas o series.</p>
    <form id="add-xtream-modal-form">
      <label>Nombre de la lista
        <input name="name" type="text" placeholder="Ej. Mi Proveedor Xtream" maxlength="80" required>
      </label>
      <label>URL del servidor
        <input name="server" type="url" placeholder="http://servidor.com:8080" required>
      </label>
      <label>Usuario
        <input name="username" type="text" placeholder="Usuario del proveedor" autocomplete="off" required>
      </label>
      <label>Contraseña
        <input name="password" type="password" placeholder="Contraseña del proveedor" autocomplete="off" required>
      </label>
      <label>Contenido
        <select name="section">
          <option value="live">Televisión en vivo</option>
          <option value="vod">Películas</option>
          <option value="series">Series</option>
        </select>
      </label>
      <p class="form-message" id="add-xtream-message" role="status"></p>
      <div style="display:flex;gap:10px;margin-top:16px">
        <button class="primary-button" type="submit" style="flex:1">Conectar y agregar <span>→</span></button>
        <button type="button" id="close-dialog" class="secondary-button" style="width:auto">Cancelar</button>
      </div>
    </form>
  `);
}

function openCheckoutDialog() {
  dialog(`
    <span class="eyebrow">MONETIZACIÓN · PAGO SEGURO</span>
    <h2>Quitar Anuncios</h2>
    <p class="muted">Desactiva permanentemente todos los anuncios y banners en Vault.</p>
    
    <div class="checkout-summary-card">
      <div class="checkout-product-title">
        <span class="checkout-star-icon">👑</span>
        <div>
          <strong>Pase Permanente Sin Anuncios</strong>
          <small>Licencia única de por vida para este dispositivo</small>
        </div>
      </div>
      <div class="checkout-price-row">
        <span>Precio final:</span>
        <span class="checkout-price-highlight">$2.99 USD</span>
      </div>
      <div class="checkout-perks-list">
        <div>✓ Eliminación del 100% de la publicidad en Inicio, Live TV y Reproductor</div>
        <div>✓ Mayor fluidez, menor uso de memoria y datos</div>
        <div>✓ No es suscripción mensual (pago único de por vida)</div>
      </div>
    </div>

    <form id="checkout-purchase-form">
      <div style="display:flex;gap:10px;margin-top:16px">
        <button type="submit" class="primary-button buy-confirm-btn" style="flex:1">
          💳 Pagar $2.99 y Activar <span>→</span>
        </button>
        <button type="button" id="close-dialog" class="secondary-button" style="width:auto">
          Cancelar
        </button>
      </div>
    </form>
  `);
}


/* ==========================================================================
   WEB VIDEO EXTRACTOR / EXPLORADOR WEB DE VIDEO
   Permite ingresar cualquier URL web (como lacartoons.com), extraer videos,
   reproductores embebidos (iframes) y listas de capitulos para reproducirlos.
   ========================================================================== */

function resolveFullUrl(base, relative) {
  if (!relative) return '';
  try {
    return new URL(relative, base).href;
  } catch (_) {
    return relative;
  }
}

function isValidHtmlResponse(text) {
  if (!text || typeof text !== 'string' || text.length < 100) return false;
  const lower = text.toLowerCase();
  if (lower.includes('just a moment...') ||
      lower.includes('checking your browser') ||
      lower.includes('403 forbidden') ||
      lower.includes('access denied') ||
      lower.includes('hide.mn') ||
      lower.includes('cloudflare ray id') ||
      lower.includes('enable javascript and cookies to continue')) {
    return false;
  }
  return true;
}

async function resolveCubeEmbed(url, parentReferer = '') {
  if (!url || !url.includes('cubeembed.rpmvid.com')) return url;
  const fileId = url.includes('#') ? url.split('#')[1].trim() : '';
  if (!fileId) return url;
  try {
    const apiTarget = `https://cubeembed.rpmvid.com/api/public/resolve?file1=${encodeURIComponent(fileId)}`;
    
    // Probar con servidor local /proxy si está disponible
    const srv = state.server || 'http://localhost:8000';
    try {
      const res = await fetch(`${srv}/proxy?url=${encodeURIComponent(apiTarget)}`, { signal: AbortSignal.timeout(4000) });
      if (res.ok) {
        const data = await res.json();
        if (data && data.url) return data.url;
      }
    } catch (_) {}

    // CapacitorHttp en APK nativo
    const capHttp = window.Capacitor?.Plugins?.CapacitorHttp || window.CapacitorHttp;
    if (capHttp && typeof capHttp.get === 'function') {
      const res = await capHttp.get({
        url: apiTarget,
        responseType: 'json',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': parentReferer || 'https://lacartoons.com/'
        }
      });
      if (res && res.data && res.data.url) return res.data.url;
    }
  } catch (e) {
    console.warn('CubeEmbed resolve fallback error:', e);
  }
  return url;
}

function normalizeWebVideoUrl(rawUrl) {
  if (!rawUrl) return '';
  const url = rawUrl.trim();
  // YouTube watch / share normalization
  const ytMatch = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/i);
  if (ytMatch) {
    return {
      type: 'web_embed',
      embed_url: `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&rel=0`,
      stream_url: `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&rel=0`
    };
  }
  // Vimeo
  const vimeoMatch = url.match(/vimeo\.com\/(?:video\/)?(\d+)/i);
  if (vimeoMatch) {
    return {
      type: 'web_embed',
      embed_url: `https://player.vimeo.com/video/${vimeoMatch[1]}?autoplay=1`,
      stream_url: `https://player.vimeo.com/video/${vimeoMatch[1]}?autoplay=1`
    };
  }
  // Dailymotion
  const dmMatch = url.match(/dailymotion\.com\/video\/([a-zA-Z0-9]+)/i);
  if (dmMatch) {
    return {
      type: 'web_embed',
      embed_url: `https://www.dailymotion.com/embed/video/${dmMatch[1]}?autoplay=1`,
      stream_url: `https://www.dailymotion.com/embed/video/${dmMatch[1]}?autoplay=1`
    };
  }
  return null;
}

async function fetchHtmlWithCorsFallback(targetUrl) {
  // 1. En Android / TV nativo (CapacitorHttp con responseType text y cabeceras completas)
  const capHttp = window.Capacitor?.Plugins?.CapacitorHttp || window.CapacitorHttp;
  if (capHttp && typeof capHttp.get === 'function') {
    try {
      const res = await capHttp.get({
        url: targetUrl,
        responseType: 'text',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Referer': targetUrl
        }
      });
      if (res && res.data) {
        const text = typeof res.data === 'string' ? res.data : JSON.stringify(res.data);
        if (isValidHtmlResponse(text)) return text;
      }
    } catch (e) {
      console.warn('CapacitorHttp native request failed, trying fallback:', e);
    }
  }

  // 2. Servidor Vault Backend (/proxy - soporte tanto en state.server como en localhost:8000)
  const localEndpoints = [state.server, 'http://localhost:8000', 'http://127.0.0.1:8000'].filter(Boolean);
  for (const srv of [...new Set(localEndpoints)]) {
    try {
      const res = await fetch(`${srv}/proxy?url=${encodeURIComponent(targetUrl)}`, { signal: AbortSignal.timeout(5000) });
      if (res.ok) {
        const text = await res.text();
        if (isValidHtmlResponse(text)) return text;
      }
    } catch (_) {}
  }

  // 3. Fetch directo estándar (para endpoints que admiten CORS o descargas directas)
  try {
    const res = await fetch(targetUrl, { signal: AbortSignal.timeout(3000) });
    if (res.ok) {
      const text = await res.text();
      if (isValidHtmlResponse(text)) return text;
    }
  } catch (_) {}

  // 4. Proxies CORS públicos probados con validación anti-bloqueo
  const publicProxies = [
    u => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}`,
    u => `https://api.allorigins.win/get?url=${encodeURIComponent(u)}`,
    u => `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(u)}`
  ];
  for (const getP of publicProxies) {
    try {
      const fullUrl = getP(targetUrl);
      const res = await fetch(fullUrl, { signal: AbortSignal.timeout(10000) });
      if (res.ok) {
        let text = '';
        if (fullUrl.includes('/get?url=')) {
          const json = await res.json();
          text = json?.contents || '';
        } else {
          text = await res.text();
        }
        if (isValidHtmlResponse(text)) return text;
      }
    } catch (_) {}
  }

  throw new Error('No se pudo descargar el HTML directamente por restricciones del navegador (CORS). Puedes cargar el reproductor directo.');
}

function extractMediaFromHtml(baseUrl, html) {
  let pageTitle = '';
  const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (titleMatch) {
    pageTitle = titleMatch[1].replace(/<[^>]+>/g, '').trim().replace(/\s+/g, ' ');
  }

  // 1. Videos directos y tags <source>
  const directVideos = [];
  const videoSrcRegex = /<video[^>]+src=['"]([^'"]+)['"]/gi;
  let m;
  while ((m = videoSrcRegex.exec(html)) !== null) {
    if (!m[1].startsWith('blob:')) directVideos.push(resolveFullUrl(baseUrl, m[1]));
  }
  const sourceSrcRegex = /<source[^>]+src=['"]([^'"]+)['"]/gi;
  while ((m = sourceSrcRegex.exec(html)) !== null) {
    if (!m[1].startsWith('blob:')) directVideos.push(resolveFullUrl(baseUrl, m[1]));
  }

  // URLs de streams .m3u8 y .mp4 en scripts o atributos
  const streamRegex = /['"](https?:\/\/[^\s'"<>]+\.(?:m3u8|mp4|webm)[^\s'"<>]*)['"]/gi;
  while ((m = streamRegex.exec(html)) !== null) {
    directVideos.push(m[1].replace(/\\\//g, '/'));
  }

  // 2. Reproductores embebidos iframes
  const iframes = [];
  const seenIframes = new Set();
  const iframeRegex = /<iframe[^>]+src=['"]([^'"]+)['"][^>]*>/gi;
  while ((m = iframeRegex.exec(html)) !== null) {
    const rawSrc = m[1].trim();
    if (!rawSrc || rawSrc.startsWith('javascript:') || rawSrc.startsWith('about:') || rawSrc.startsWith('data:')) continue;
    const fullSrc = resolveFullUrl(baseUrl, rawSrc);
    if (!seenIframes.has(fullSrc)) {
      seenIframes.add(fullSrc);
      const isPlayer = /embed|player|video|stream|rpmvid|ok\.ru|youtube|vimeo|dailymotion|tape|cloud|vid|mp4upload/i.test(fullSrc) ||
                       /allowfullscreen/i.test(m[0]);
      iframes.push({ src: fullSrc, isPlayer, tag: m[0] });
    }
  }

  // 3. Enlaces a capitulos / episodios
  const episodes = [];
  const seenEps = new Set();
  const epRegex = /<a[^>]+href=['"]([^'"]*(?:capitulo|episodio|episode|chapter|\/ver\/|\/watch\/|\/video\/)[^'"]*)['"][^>]*>([\s\S]*?)<\/a>/gi;
  while ((m = epRegex.exec(html)) !== null) {
    const href = m[1].trim();
    const fullHref = resolveFullUrl(baseUrl, href);
    if (!seenEps.has(fullHref) && !/\.(?:jpg|png|css|js|webp)$/i.test(fullHref)) {
      seenEps.add(fullHref);
      let text = m[2].replace(/<[^>]+>/g, ' ').trim().replace(/\s+/g, ' ');
      if (!text) text = `Capítulo ${episodes.length + 1}`;
      episodes.push({ url: fullHref, title: text });
    }
  }

  // 4. Series / Catálogo
  const series = [];
  const seenSeries = new Set();
  const seriesRegex = /<a[^>]+href=['"]([^'"]*(?:\/serie\/\d+|\/series\/\d+|\/anime\/|\/show\/|\/pelicula\/)[^'"]*)['"][^>]*>([\s\S]*?)<\/a>/gi;
  while ((m = seriesRegex.exec(html)) !== null) {
    const href = m[1].trim();
    if (/\/capitulo\/|\/episode\//i.test(href)) continue;
    const fullHref = resolveFullUrl(baseUrl, href);
    if (!seenSeries.has(fullHref)) {
      seenSeries.add(fullHref);
      const inner = m[2];
      
      // Clean series title
      const titleP = inner.match(/<p[^>]*class=['"][^'"]*nombre-serie[^'"]*['"][^>]*>([\s\S]*?)<\/p>/i) ||
                     inner.match(/<h\d[^>]*>([\s\S]*?)<\/h\d>/i);
      let cleanTitle = titleP ? titleP[1].replace(/<[^>]+>/g, '').trim() : '';
      if (!cleanTitle) {
        cleanTitle = inner.replace(/<[^>]+>/g, ' ').trim().replace(/\s+/g, ' ');
      }

      // Network & Year tags
      const networkM = inner.match(/<span[^>]*class=['"][^'"]*marcadorSeries[^'"]*['"][^>]*>([\s\S]*?)<\/span>/i);
      const network = networkM ? networkM[1].replace(/<[^>]+>/g, '').trim() : '';
      const yearM = inner.match(/<span[^>]*class=['"][^'"]*marcador-ano[^'"]*['"][^>]*>([\s\S]*?)<\/span>/i);
      const year = yearM ? yearM[1].replace(/<[^>]+>/g, '').trim() : '';

      const imgMatch = inner.match(/src=['"]([^'"]+)['"]/i);
      const poster = imgMatch ? resolveFullUrl(baseUrl, imgMatch[1]) : null;

      series.push({
        url: fullHref,
        title: cleanTitle || fullHref.split('/').pop(),
        network,
        year,
        poster
      });
    }
  }

  return {
    pageTitle,
    directVideos: [...new Set(directVideos)],
    iframes,
    episodes,
    series
  };
}

function openWebExtractorDialog(initialUrl = '') {
  dialog(`
    <span class="eyebrow">REPRODUCTOR UNIVERSAL · WEB EXTRACTOR</span>
    <h2>🌐 Reproducir desde la Web</h2>
    <p class="muted">Ingresa el enlace de cualquier página web (como portales de caricaturas, series, videos o transmisiones). Vault analizará el sitio para extraer sus reproductores, streams o capítulos.</p>
    
    <form id="web-extractor-form">
      <div class="web-extractor-input-box">
        <label for="web-extractor-url-input">Dirección web o enlace de video</label>
        <div class="web-extractor-input-row">
          <input type="url" id="web-extractor-url-input" name="web_url" placeholder="https://lacartoons.com/ o cualquier URL..." value="${escapeHTML(initialUrl)}" required autofocus>
          <button type="button" id="web-extractor-paste-btn" class="secondary-button" title="Pegar del portapapeles">📋 Pegar</button>
        </div>
      </div>
      <div class="web-extractor-shortcuts">
        <span class="web-shortcut-label">Accesos rápidos de prueba:</span>
        <button type="button" class="web-shortcut-btn" data-fill-url="https://lacartoons.com/">🌐 Portada</button>
        <button type="button" class="web-shortcut-btn" data-fill-url="https://lacartoons.com/serie/2">📺 Caballeros del Zodiaco</button>
        <button type="button" class="web-shortcut-btn" data-fill-url="https://lacartoons.com/serie/capitulo/13?t=1">🎬 Cap. 1 Turbovio</button>
      </div>
      
      <div class="web-extractor-submit-row">
        <button type="submit" class="primary-button" id="web-extractor-submit-btn" style="flex:1">
          <span>🔍 Explorar y Reproducir</span>
        </button>
        <button type="button" id="close-dialog" class="secondary-button" style="width:auto">Cancelar</button>
      </div>
    </form>

    <div id="web-extractor-results" class="web-extractor-results-container"></div>
  `);
}

async function runWebExtractor(targetUrl, parentTitle = '') {
  const resultsEl = $('#web-extractor-results');
  const submitBtn = $('#web-extractor-submit-btn');
  if (submitBtn) submitBtn.disabled = true;

  if (resultsEl) {
    resultsEl.innerHTML = `
      <div class="web-extractor-spinner">
        <div class="theater-spinner-ring"></div>
        <div class="web-spinner-info">
          <strong>Analizando sitio web…</strong>
          <small>${escapeHTML(targetUrl)}</small>
        </div>
      </div>
    `;
  }

  try {
    // 1. Detección rápida de archivo de video directo
    const cleanLower = targetUrl.toLowerCase();
    if (cleanLower.endsWith('.mp4') || cleanLower.endsWith('.m3u8') || cleanLower.endsWith('.webm') || cleanLower.endsWith('.ts')) {
      const fileName = targetUrl.split('/').pop().split('?')[0] || 'Video Web';
      toast('✓ Stream directo detectado');
      closeDialog();
      return play({
        channel_name: fileName,
        title: fileName,
        type: 'web_video',
        stream_url: targetUrl,
        country: 'Web',
        category: 'Video Web',
        page_url: targetUrl
      });
    }

    // 2. Descargar y analizar el HTML con fallback a reproducción directa si CORS lo restringe
    let html = '';
    try {
      html = await fetchHtmlWithCorsFallback(targetUrl);
    } catch (fetchErr) {
      console.warn('Scrape HTML fallback:', fetchErr);
      if (resultsEl) {
        resultsEl.innerHTML = `
          <div class="web-extractor-empty">
            <span class="empty-icon">📺</span>
            <h4>Reproducir Sitio Web Directamente</h4>
            <p class="muted">No fue posible extraer los capítulos automáticamente debido a políticas CORS del navegador, pero <strong>puedes reproducir esta página web directamente</strong> en Vault IPTV con pantalla completa:</p>
            <div style="display:flex;gap:10px;justify-content:center;margin-top:14px;flex-wrap:wrap">
              <button type="button" class="primary-button" id="web-extractor-fallback-play" data-target-url="${escapeHTML(targetUrl)}" style="width:auto">
                ▶ Cargar en Reproductor de Vault
              </button>
            </div>
          </div>
        `;
      }
      if (submitBtn) submitBtn.disabled = false;
      return;
    }

    const extracted = extractMediaFromHtml(targetUrl, html);
    const title = parentTitle || extracted.pageTitle || 'Video Web';

    // Priorizar iframes que sean players
    const playerIframe = extracted.iframes.find(i => i.isPlayer) || extracted.iframes[0];
    const directVid = extracted.directVideos[0];

    // Caso A: Si la página tiene un reproductor directo o iframe
    if (playerIframe || directVid) {
      let embedUrl = playerIframe ? playerIframe.src : '';
      if (embedUrl && embedUrl.includes('cubeembed.rpmvid.com')) {
        embedUrl = await resolveCubeEmbed(embedUrl, targetUrl);
      }
      const streamUrl = directVid || embedUrl;

      // Si además la página tiene lista de capítulos (ej. lacartoons capitulo 889 que tiene iframe + los 46 capítulos)
      if (extracted.episodes && extracted.episodes.length > 0) {
        state.webEpisodes = extracted.episodes.map((ep, idx) => ({
          channel_name: ep.title,
          title: ep.title,
          url: ep.url,
          country: 'Web',
          category: 'Capítulos',
          index: idx
        }));
      }

      toast('🎬 ¡Reproductor detectado! Iniciando video…');
      closeDialog();
      return play({
        channel_name: title,
        title: title,
        type: embedUrl ? 'web_embed' : 'web_video',
        stream_url: streamUrl,
        embed_url: embedUrl,
        page_url: targetUrl,
        country: 'Web',
        category: 'Video Web'
      });
    }

    // Caso B: Si la página contiene lista de capítulos (ej. serie / temporada)
    if (extracted.episodes && extracted.episodes.length > 0) {
      state.webEpisodes = extracted.episodes.map((ep, idx) => ({
        channel_name: ep.title,
        title: ep.title,
        url: ep.url,
        country: 'Web',
        category: 'Capítulos',
        index: idx
      }));

      if (resultsEl) {
        window._activeWebEpisodes = extracted.episodes;
        resultsEl.innerHTML = `
          <div class="web-extracted-header">
            <div>
              <h3>🎬 Capítulos encontrados (${extracted.episodes.length})</h3>
              <p class="muted">${escapeHTML(title)}</p>
            </div>
            ${parentTitle ? `<button type="button" class="secondary-button compact" id="web-extractor-back-to-series">← Volver a series</button>` : ''}
          </div>
          <div class="web-chapter-search-box">
            <input type="search" id="web-chapter-filter-input" placeholder="🔍 Filtrar capítulo por número o título…">
          </div>
          <div class="web-episodes-scroll-list" id="web-episodes-scroll-container">
            ${extracted.episodes.map((ep, idx) => `
              <div class="web-episode-card" data-play-web-ep="${encodeURIComponent(JSON.stringify(ep))}">
                <div class="web-ep-badge">${idx + 1}</div>
                <div class="web-ep-text">
                  <strong>${escapeHTML(ep.title)}</strong>
                  <small>${escapeHTML(ep.url)}</small>
                </div>
                <button type="button" class="primary-button compact">▶ Reproducir</button>
              </div>
            `).join('')}
          </div>
        `;
      }
      return;
    }

    // Caso C: Si la página contiene catálogo de series (ej. lacartoons.com portada)
    if (extracted.series && extracted.series.length > 0) {
      state.webSeries = extracted.series;
      if (resultsEl) {
        resultsEl.innerHTML = `
          <div class="web-extracted-header">
            <h3>📺 Series y contenidos encontrados (${extracted.series.length})</h3>
            <p class="muted">Selecciona una serie para ver sus capítulos y reproducir:</p>
          </div>
          <div class="web-series-grid">
            ${extracted.series.map(s => `
              <div class="web-serie-card" data-open-web-serie="${escapeHTML(s.url)}" data-serie-title="${escapeHTML(s.title)}">
                ${s.poster ? `<img src="${escapeHTML(s.poster)}" alt="" class="web-serie-poster" onerror="this.style.display='none'">` : `<div class="web-serie-poster-placeholder">📺</div>`}
                <div class="web-serie-info">
                  <strong>${escapeHTML(s.title)}</strong>
                  <div class="web-serie-meta-tags">
                    ${s.network ? `<span class="serie-tag">${escapeHTML(s.network)}</span>` : ''}
                    ${s.year ? `<span class="serie-year">${escapeHTML(s.year)}</span>` : ''}
                  </div>
                  <button type="button" class="primary-button compact" style="margin-top:4px">Ver capítulos →</button>
                </div>
              </div>
            `).join('')}
          </div>
        `;
      }
      return;
    }

    // Caso D: Nada reconocido automáticamente -> ofrecer reproducir la página directamente
    if (resultsEl) {
      resultsEl.innerHTML = `
        <div class="web-extractor-empty">
          <span class="empty-icon">📺</span>
          <h4>Reproducir esta página web</h4>
          <p class="muted">No se reconocieron listas de capítulos de catálogo, pero puedes reproducir esta página web directamente dentro del reproductor de Vault:</p>
          <div style="display:flex;gap:10px;justify-content:center;margin-top:14px;flex-wrap:wrap">
            <button type="button" class="primary-button" id="web-extractor-fallback-play" data-target-url="${escapeHTML(targetUrl)}" style="width:auto">
              ▶ Cargar en Reproductor de Vault
            </button>
          </div>
        </div>
      `;
    }
  } catch (err) {
    if (resultsEl) {
      resultsEl.innerHTML = `
        <div class="web-extractor-empty error">
          <span class="empty-icon">📺</span>
          <h4>Reproducir Sitio Directamente</h4>
          <p class="muted">${escapeHTML(err.message)}</p>
          <div style="display:flex;gap:10px;justify-content:center;margin-top:14px;flex-wrap:wrap">
            <button type="button" class="primary-button" id="web-extractor-fallback-play" data-target-url="${escapeHTML(targetUrl)}" style="width:auto">
              ▶ Cargar en Reproductor de Vault
            </button>
          </div>
        </div>
      `;
    }
  } finally {
    if (submitBtn) submitBtn.disabled = false;
  }
}

async function loadAndPlayWebEpisode(ep) {
  if (ep.embed_url || (ep.stream_url && ep.stream_url.startsWith('http') && !ep.stream_url.includes('/serie/capitulo/'))) {
    closeDialog();
    return play({
      channel_name: ep.title || ep.channel_name,
      title: ep.title || ep.channel_name,
      type: ep.embed_url ? 'web_embed' : 'web_video',
      stream_url: ep.stream_url || ep.embed_url,
      embed_url: ep.embed_url || '',
      page_url: ep.url || ep.page_url,
      country: 'Web',
      category: 'Capítulos'
    });
  }

  toast(`Conectando con capítulo: ${ep.title}…`);
  try {
    const epUrl = ep.url || ep.page_url;
    const html = await fetchHtmlWithCorsFallback(epUrl);
    const extracted = extractMediaFromHtml(epUrl, html);
    let playerIframe = extracted.iframes.find(i => i.isPlayer) || extracted.iframes[0];
    let directVid = extracted.directVideos[0];

    let embedUrl = playerIframe ? playerIframe.src : '';
    // Resolve CubeEmbed directly if needed
    if (embedUrl && embedUrl.includes('cubeembed.rpmvid.com')) {
      embedUrl = await resolveCubeEmbed(embedUrl, epUrl);
    }
    const streamUrl = directVid || embedUrl || epUrl;
    const finalEmbed = embedUrl || epUrl;

    ep.embed_url = embedUrl;
    ep.stream_url = streamUrl;

    // Si tiene capítulos adicionales, sincronizarlos
    if (extracted.episodes && extracted.episodes.length > 0 && (!state.webEpisodes || state.webEpisodes.length < extracted.episodes.length)) {
      state.webEpisodes = extracted.episodes.map((e, idx) => ({
        channel_name: e.title,
        title: e.title,
        url: e.url,
        country: 'Web',
        category: 'Capítulos',
        index: idx
      }));
    }

    closeDialog();
    play({
      channel_name: ep.title,
      title: ep.title,
      type: 'web_embed',
      stream_url: streamUrl,
      embed_url: finalEmbed,
      page_url: epUrl,
      country: 'Web',
      category: 'Capítulos'
    });
  } catch (err) {
    console.warn('Fallback loading web episode:', err);
    closeDialog();
    play({
      channel_name: ep.title,
      title: ep.title,
      type: 'web_embed',
      stream_url: epUrl,
      embed_url: epUrl,
      page_url: epUrl,
      country: 'Web',
      category: 'Capítulos'
    });
  }
}

function home() {
  const userName = state.user ? (state.user.display_name || state.user.custom_username) : '';
  const greeting = userName ? `Hola, ${escapeHTML(userName)}` : 'Bienvenido a Vault';
  const totalChannels = state.channels.length;
  const hasLists = state.userLists.length > 0;

  return `
    <div class="home-welcome">
      <h1>${greeting}</h1>
      <p>Tu reproductor IPTV limpio y directo. Agrega tus listas por URL o conecta tus cuentas en la sección Xtream.</p>
    </div>

    ${hasLists ? `
      <section class="add-source-section compact" aria-label="Agregar contenido adicional">
        <div class="add-source-compact-row">
          <button type="button" data-add-m3u="1" class="compact-add-card">
            <span class="compact-add-icon">🔗</span>
            <div class="compact-add-text">
              <strong>+ Agregar IPTV con URL</strong>
              <small>Lista .M3U o .M3U8</small>
            </div>
          </button>
          <button type="button" data-open-web-extractor="1" class="compact-add-card web">
            <span class="compact-add-icon">🌐</span>
            <div class="compact-add-text">
              <strong>Reproducir desde Web</strong>
              <small>Extraer videos o series web</small>
            </div>
          </button>
        </div>
      </section>
    ` : `
      <section class="add-source-section" aria-label="Agregar fuentes IPTV y Web">
        <div class="section-heading" style="margin-top:8px">
          <h2>Agregar contenido</h2>
          <small>${totalChannels} canales cargados</small>
        </div>
        <div class="add-source-grid" style="grid-template-columns:repeat(auto-fit, minmax(260px, 1fr))">
          <button type="button" data-add-m3u="1" class="source-action-card">
            <span class="source-action-icon">🔗</span>
            <div class="source-action-body">
              <strong>Agregar IPTV con URL</strong>
              <small>Importa una lista .M3U o .M3U8 desde un enlace web para ver tus canales</small>
            </div>
            <span class="source-action-plus">+</span>
          </button>
          <button type="button" data-open-web-extractor="1" class="source-action-card web">
            <span class="source-action-icon">🌐</span>
            <div class="source-action-body">
              <strong>Reproducir desde Web</strong>
              <small>Pega el enlace de cualquier web para reproducir sus videos o capítulos</small>
            </div>
            <span class="source-action-plus">▶</span>
          </button>
        </div>
      </section>
    `}

    ${!state.noAds ? `
      <!-- SECCIÓN 1 DE MONETIZACIÓN: BANNER PRINCIPAL (INICIO) -->
      <section class="ad-container-section" aria-label="Espacio Publicitario">
        <div class="ad-banner-card" id="ad-banner-home">
          <div class="ad-tag-row">
            <span class="ad-badge">ANUNCIO · PATROCINADO</span>
            <button type="button" class="ad-remove-hint" data-open-buy-no-ads="1" title="Quitar anuncios por $2.99">
              ⭐ Quitar anuncios ($2.99)
            </button>
          </div>
          <div class="ad-banner-content">
            <div class="ad-banner-icon">📡</div>
            <div class="ad-banner-info">
              <strong>Espacio Publicitario Disponible</strong>
              <small>Compatible con Google AdMob, Unity Ads y redes de monetización</small>
            </div>
            <button type="button" class="ad-cta-btn" data-open-buy-no-ads="1">Quitar Ads</button>
          </div>
        </div>
      </section>
    ` : ''}

    <section class="user-lists-section" aria-label="Mis listas agregadas">
      <div class="section-heading">
        <h2>Mis listas agregadas</h2>
        <small>${state.userLists.length} ${state.userLists.length === 1 ? 'lista' : 'listas'}</small>
      </div>
      ${state.userLists.length === 0 ? `
        <div class="empty-lists-box">
          <div class="empty-lists-icon">📺</div>
          <h3>Todavía no has agregado ninguna lista</h3>
          <p class="muted">La aplicación está limpia y lista para ti. Usa uno de los botones de arriba para agregar tu primera lista IPTV o cuenta Xtream Codes.</p>
        </div>
      ` : `
        <div class="user-lists-grid">
          ${state.userLists.map(list => `
            <article class="user-list-card">
              <div class="user-list-top">
                <span class="list-type-badge ${list.type === 'xtream' ? 'xtream' : 'm3u'}">
                  ${list.type === 'xtream' ? 'ϟ XTREAM CODES' : '🔗 IPTV URL'}
                </span>
                <span class="list-count-pill">${(list.channels || []).length} canales</span>
              </div>
              <h3 class="user-list-title" title="${escapeHTML(list.name)}">${escapeHTML(list.name)}</h3>
              <p class="user-list-meta" title="${escapeHTML(list.url)}">
                ${escapeHTML(list.url)}${list.type === 'xtream' && list.username ? ` · Usuario: ${escapeHTML(list.username)}` : ''}
              </p>
              <div class="list-card-actions">
                <button type="button" class="primary-button list-open-btn" data-open-list="${escapeHTML(list.id)}">▶ Ver canales</button>
                <button type="button" class="secondary-button list-icon-btn" data-refresh-list="${escapeHTML(list.id)}" title="Actualizar lista">↻</button>
                <button type="button" class="secondary-button list-icon-btn danger" data-delete-list="${escapeHTML(list.id)}" title="Eliminar lista">🗑</button>
              </div>
            </article>
          `).join('')}
        </div>
      `}
    </section>
  `;
}

function live() {
  const activeListId = state.listFilter || 'all';
  const listScopedChannels = state.channels.map((channel, index) => ({ channel, index }))
    .filter(({ channel }) => activeListId === 'all' || channel.listId === activeListId);

  const allCountries = [...new Set(listScopedChannels.map(({ channel: c }) => c.country || 'Internacional').filter(Boolean))]
    .sort((a, b) => a.localeCompare(b, 'es'));
  const countries = ['Todos', ...allCountries];

  const allCategories = [...new Set(listScopedChannels.map(({ channel: c }) => c.category || 'General').filter(Boolean))]
    .sort((a, b) => a.localeCompare(b, 'es'));
  const categories = ['Todas', ...allCategories];

  const query = state.query.trim().toLocaleLowerCase('es');

  let visible = listScopedChannels.filter(({ channel: c }) => {
    const matchesCountry = (state.countryFilter === 'Todos' || (c.country || 'Internacional') === state.countryFilter);
    const matchesCategory = (state.categoryFilter === 'Todas' || (c.category || 'General') === state.categoryFilter);
    const matchesView = (state.channelView === 'Todos') ||
      (state.channelView === 'Favoritos' && state.favorites.has(channelId(c))) ||
      (state.channelView === 'Recientes' && state.recent.includes(channelId(c)));
    const targetText = `${c.channel_name} ${c.country || ''} ${c.category || ''} ${c.listName || ''}`.toLocaleLowerCase('es');
    const matchesQuery = !query || targetText.includes(query);
    return matchesCountry && matchesCategory && matchesView && matchesQuery;
  });

  if (state.channelView === 'Recientes') visible.sort((a, b) => state.recent.indexOf(channelId(a.channel)) - state.recent.indexOf(channelId(b.channel)));
  else if (state.alphabetical) visible.sort((a, b) => a.channel.channel_name.localeCompare(b.channel.channel_name, 'es'));

  const totalMatches = visible.length;
  const pageLimit = state.channelPageLimit || 60;
  const pagedVisible = visible.slice(0, pageLimit);

  const countForCountry = (c) => c === 'Todos' ? listScopedChannels.length : listScopedChannels.filter(({ channel: ch }) => (ch.country || 'Internacional') === c).length;
  const countForCategory = (cat) => cat === 'Todas' ? listScopedChannels.length : listScopedChannels.filter(({ channel: ch }) => (ch.category || 'General') === cat).length;

  return `<div class="iptv-toolbar">
    <div>
      <span class="eyebrow">TELEVISIÓN EN VIVO · STREAMING</span>
      <h1 class="page-title" style="margin:2px 0 4px">Live TV</h1>
      <p class="page-subtitle" style="margin:0">${state.channels.length} canales disponibles · ${totalMatches} coincidentes</p>
    </div>
    <div class="iptv-actions">
      <button type="button" data-open-web-extractor="1" class="action-chip web-chip" title="Reproducir video desde cualquier enlace web">🌐 Reproducir Web</button>
      ${state.user?.admin_status ? `
        <button id="refresh-iptv-btn" class="action-chip" title="Sincronizar listas del servidor">↻ Servidor</button>
      ` : ''}
    </div>
  </div>

  ${state.channels.length === 0 ? `
    <div class="empty-lists-box" style="margin-top:20px">
      <div class="empty-lists-icon">📡</div>
      <h3>No hay canales cargados</h3>
      <p class="muted">Agrega una lista IPTV por URL para empezar a ver canales (o conecta tu proveedor en la sección Xtream).</p>
      <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:16px">
        <button type="button" data-add-m3u="empty" class="primary-button" style="width:auto">🔗 Agregar IPTV con URL</button>
      </div>
    </div>
  ` : `
    ${state.userLists.length > 0 ? `
      <div class="iptv-filter-section user-lists-filter-block">
        <div class="filter-section-header">
          <span class="filter-title-label">📋 Mis Listas Agregadas (${state.userLists.length})</span>
        </div>
        <div class="filter-scroll-row user-lists-pills-row">
          <button data-list-filter="all" class="user-list-pill ${activeListId === 'all' ? 'active' : ''}">
            <span class="pill-dot">●</span>
            <span class="pill-name">Todas las listas</span>
            <span class="pill-badge">${state.channels.length}</span>
          </button>
          ${state.userLists.map(l => `
            <button data-list-filter="${escapeHTML(l.id)}" class="user-list-pill ${activeListId === l.id ? 'active' : ''}">
              <span class="pill-icon">${l.type === 'xtream' ? '⚡' : '🔗'}</span>
              <span class="pill-name">${escapeHTML(l.name)}</span>
              <span class="pill-badge">${(l.channels || []).length}</span>
            </button>
          `).join('')}
        </div>
      </div>
    ` : ''}

    <label>Buscar canal, país o subcategoría<input id="channel-search" type="search" value="${escapeHTML(state.query)}" placeholder="Buscar por nombre, país o género..." autocomplete="off"></label>

    <div class="filters">
      ${['Todos', 'Favoritos', 'Recientes'].map(view => `<button data-channel-view="${view}" class="filter ${view === state.channelView ? 'active' : ''}">${view === 'Favoritos' ? '★ Favoritos' : view === 'Recientes' ? '🕒 Recientes' : 'Todos'}</button>`).join('')}
      <button id="sort-channels" class="filter ${state.alphabetical ? 'active' : ''}" aria-pressed="${state.alphabetical}">Ordenar A–Z</button>
    </div>

    ${!state.noAds ? `
      <!-- SECCIÓN 2 DE MONETIZACIÓN: BANNER LIVE TV -->
      <div class="ad-container-section compact" aria-label="Espacio Publicitario">
        <div class="ad-banner-card compact" id="ad-banner-live">
          <div class="ad-tag-row">
            <span class="ad-badge">PUBLICIDAD</span>
            <button type="button" class="ad-remove-hint" data-open-buy-no-ads="1" title="Quitar anuncios por $2.99">
              ⭐ Sin anuncios $2.99
            </button>
          </div>
          <div class="ad-banner-content">
            <div class="ad-banner-icon">🎬</div>
            <div class="ad-banner-info">
              <strong>Anuncio Patrocinado</strong>
              <small>Espacio publicitario integrado para monetización de emisiones</small>
            </div>
            <button type="button" class="ad-cta-btn" data-open-buy-no-ads="1">Desactivar</button>
          </div>
        </div>
      </div>
    ` : ''}

    ${allCountries.length > 1 ? `
      <div class="iptv-filter-section">
        <div class="filter-section-header">
          <span>🌎 Categoría por País (${countries.length - 1} países)</span>
          <select id="country-select" class="country-select-dropdown" aria-label="Seleccionar país">
            ${countries.map(c => `<option value="${escapeHTML(c)}" ${c === state.countryFilter ? 'selected' : ''}>${c === 'Todos' ? '🌐 Todos los países' : `${getCountryFlag(c)} ${escapeHTML(c)}`} (${countForCountry(c)})</option>`).join('')}
          </select>
        </div>
        <div class="filter-scroll-row">
          ${countries.map(c => `<button data-country-filter="${escapeHTML(c)}" class="filter ${c === state.countryFilter ? 'active' : ''}">${c === 'Todos' ? '🌐 Todos' : `${getCountryFlag(c)} ${escapeHTML(c)}`} <small style="opacity:.7">(${countForCountry(c)})</small></button>`).join('')}
        </div>
      </div>
    ` : ''}

    ${allCategories.length > 1 ? `
      <div class="iptv-filter-section">
        <div class="filter-section-header">
          <span class="filter-title-label">🏷️ Subcategorías de Contenido</span>
          <small class="subcat-counter">${categories.length - 1} subcategorías</small>
        </div>
        <div class="filter-scroll-row subcat-pills-row">
          ${categories.map(cat => {
            const isAll = cat === 'Todas';
            const icon = isAll ? '✨' : getCategoryIcon(cat);
            return `<button data-category-filter="${escapeHTML(cat)}" class="subcat-pill ${cat === state.categoryFilter ? 'active' : ''}">
              <span class="subcat-pill-icon">${icon}</span>
              <span class="subcat-pill-name">${escapeHTML(cat)}</span>
              <span class="subcat-pill-badge">${countForCategory(cat)}</span>
            </button>`;
          }).join('')}
        </div>
      </div>
    ` : ''}

    <div class="channels">
      ${pagedVisible.map(({ channel: c, index }) => `
        <div class="channel-card-rich" data-channel="${index}" tabindex="0" role="button" aria-label="Canal ${escapeHTML(c.channel_name)}">
          <div class="channel-card-top">
            <div class="channel-logo-rich">
              ${c.logo_url ? `<img src="${escapeHTML(c.logo_url)}" alt="${escapeHTML(c.channel_name)}" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='block'"><span class="fallback-text" style="display:none">${escapeHTML(c.channel_name.slice(0, 2).toUpperCase())}</span>` : `<span class="fallback-text">${escapeHTML(c.initials || c.channel_name.slice(0, 2).toUpperCase())}</span>`}
            </div>
            <div class="channel-title-group">
              <div class="channel-name-rich" title="${escapeHTML(c.channel_name)}">${escapeHTML(c.channel_name)}</div>
              <div class="channel-meta-rich">
                ${c.listName ? `<span class="channel-tag">📋 ${escapeHTML(c.listName)}</span>` : ''}
                <span class="channel-tag">${getCountryFlag(c.country)} ${escapeHTML(c.country || 'Internacional')}</span>
                <span class="channel-tag">${getCategoryIcon(c.category)} ${escapeHTML(c.category || 'General')}</span>
              </div>
            </div>
            <button class="channel-fav-btn ${state.favorites.has(channelId(c)) ? 'saved' : ''}" data-star="${index}" title="${state.favorites.has(channelId(c)) ? 'Quitar de favoritos' : 'Agregar a favoritos'}" aria-label="${state.favorites.has(channelId(c)) ? 'Quitar de favoritos' : 'Agregar a favoritos'}">
              ${state.favorites.has(channelId(c)) ? '★' : '☆'}
            </button>
          </div>

          <div class="channel-epg-box">
            <div class="epg-header-row">
              <span class="epg-broadcasting-label"><span style="color:#00ffaa;font-size:11px">●</span> EN EMISIÓN</span>
              <span class="epg-time-badge">⏱️ ${escapeHTML(c.program_time || 'En vivo')}</span>
            </div>
            <div class="epg-program-name" title="${escapeHTML(c.current_program || 'Programación habitual')}">
              ${escapeHTML(c.current_program || 'Programación habitual')}
            </div>
          </div>

          <div class="channel-bottom-bar">
            <span class="signal-status-pill ${c.is_online !== false ? 'online' : 'offline'}">
              <i></i> ${c.is_online !== false ? 'En línea' : 'Sin señal'}
            </span>
            <span class="play-quick-chip">Ver canal ▶</span>
          </div>
        </div>
      `).join('') || '<p class="empty-state">No hay canales con estos filtros. Prueba cambiando la lista, país o subcategoría.</p>'}
    </div>
    ${totalMatches > pageLimit ? `
      <div class="load-more-container">
        <button id="load-more-channels-btn" class="primary-button">
          Cargar más canales (+60) · Mostrando ${pagedVisible.length} de ${totalMatches}
        </button>
      </div>
    ` : ''}
  `}`;
}

function xtream() {
  const xtreamLists = state.userLists.filter(l => l.type === 'xtream');
  return `
    <span class="eyebrow">UN ESPACIO PARA TU PROVEEDOR</span>
    <h1 class="page-title">Xtream Codes</h1>
    <p class="page-subtitle">Conecta tu proveedor Xtream para agregar TV en vivo, películas o series a tus listas.</p>
    <div class="settings-card">
      <h2>Conectar Xtream Codes</h2>
      <p class="muted">Las listas que agregues aparecerán también en "Mis listas agregadas" en Inicio.</p>
      <form id="xtream-form">
        <label>Nombre de la lista<input name="name" type="text" placeholder="Ej. Mi Proveedor Xtream" maxlength="80" required></label>
        <label>URL del proveedor<input name="server" type="url" placeholder="http://proveedor.com:8080" required></label>
        <label>Usuario<input name="username" autocomplete="off" required placeholder="Usuario del proveedor"></label>
        <label>Contraseña<input name="password" type="password" autocomplete="off" required placeholder="Contraseña del proveedor"></label>
        <label>Contenido<select name="section"><option value="live">Televisión en vivo</option><option value="vod">Películas</option><option value="series">Series</option></select></label>
        <button class="primary-button" type="submit">Conectar y guardar lista <span>→</span></button>
      </form>
    </div>
    ${xtreamLists.length > 0 ? `
      <div class="section-heading">
        <h2>Listas Xtream agregadas</h2>
        <small>${xtreamLists.length}</small>
      </div>
      <div class="user-lists-grid">
        ${xtreamLists.map(list => `
          <article class="user-list-card">
            <div class="user-list-top">
              <span class="list-type-badge xtream">ϟ XTREAM CODES</span>
              <span class="list-count-pill">${(list.channels || []).length} elementos</span>
            </div>
            <h3 class="user-list-title">${escapeHTML(list.name)}</h3>
            <p class="user-list-meta">${escapeHTML(list.url)} · Usuario: ${escapeHTML(list.username)}</p>
            <div class="list-card-actions">
              <button type="button" class="primary-button list-open-btn" data-open-list="${escapeHTML(list.id)}">▶ Ver contenido</button>
              <button type="button" class="secondary-button list-icon-btn" data-refresh-list="${escapeHTML(list.id)}" title="Actualizar">↻</button>
              <button type="button" class="secondary-button list-icon-btn danger" data-delete-list="${escapeHTML(list.id)}" title="Eliminar">🗑</button>
            </div>
          </article>
        `).join('')}
      </div>
    ` : ''}
    ${state.xtream.length > 0 ? `
      <div class="section-heading"><h2>Elementos cargados recientemente</h2><small>${state.xtream.length}</small></div>
      <div class="channels">${state.xtream.slice(0, 60).map((item, index) => `<button class="channel" data-xtream="${index}"><span class="channel-logo">ϟ</span><div><h3>${escapeHTML(item.title || item.channel_name)}</h3><small>${escapeHTML(item.type || 'live')}</small></div></button>`).join('')}</div>
    ` : ''}
  `;
}

function profile() {
  const isLoggedIn = Boolean(state.token && state.user);
  const name = isLoggedIn ? (state.user?.display_name || state.user?.custom_username || 'Usuario') : 'Mi Perfil';
  const admin = isLoggedIn && state.user?.admin_status === true;

  return `
    <div class="profile-summary">
      <div class="profile-avatar">${isLoggedIn ? escapeHTML(name.slice(0, 1).toUpperCase()) : '👤'}</div>
      <h1 class="page-title">${escapeHTML(name)}</h1>
      <p class="page-subtitle">${isLoggedIn ? (admin ? '👑 Administrador de Vault' : 'Cuenta Vault conectada') : 'Modo Local · Reproductor IPTV 100% independiente'}</p>
      ${isLoggedIn ? `<button id="edit-name" class="quiet-button" ${!state.online ? 'disabled' : ''}>Editar nombre</button>` : ''}
    </div>

    <!-- SECCIÓN DE MONETIZACIÓN Y QUITAR ANUNCIOS -->
    <div class="settings-card premium-upgrade-card" id="premium-upgrade-card">
      <span class="eyebrow">${state.noAds ? '👑 MIEMBRO VIP' : '⭐ MONETIZACIÓN · PLAN PREMIUM'}</span>
      <h2>${state.noAds ? 'Plan Sin Anuncios Activado' : 'Quitar anuncios de la app'}</h2>
      <p class="muted">
        ${state.noAds
          ? 'Tienes la versión permanente sin publicidad. Disfruta de la reproducción y menús completamente limpios.'
          : 'Elimina para siempre los banners y anuncios publicitarios de todas las pantallas con un único pago.'}
      </p>

      ${state.noAds ? `
        <div class="premium-active-row">
          <span class="premium-badge-icon">✓</span>
          <div class="premium-active-text">
            <strong>Licencia Permanente Activa</strong>
            <small>Sin publicidad en Inicio, Live TV y Reproductor</small>
          </div>
        </div>
        <div style="margin-top:14px;display:flex;gap:10px;flex-wrap:wrap">
          <button type="button" id="restore-ads-dev-btn" class="quiet-button" style="font-size:12px;opacity:.7">
            Restablecer anuncios (modo prueba)
          </button>
        </div>
      ` : `
        <div class="premium-pricing-box">
          <div class="pricing-header">
            <span class="price-val">$2.99</span>
            <span class="price-unit">USD · Pago único de por vida</span>
          </div>
          <div class="premium-perks">
            <div class="premium-perk-item"><span>✓</span> Cero anuncios en todas las pantallas</div>
            <div class="premium-perk-item"><span>✓</span> Mayor velocidad de carga y menor consumo de datos</div>
            <div class="premium-perk-item"><span>✓</span> Apoya el desarrollo independiente de Vault</div>
          </div>
          <div class="premium-btn-row">
            <button type="button" id="buy-no-ads-btn" class="primary-button premium-buy-button">
              <span>👑 Quitar anuncios por $2.99</span>
              <span>→</span>
            </button>
            <button type="button" id="restore-purchase-btn" class="secondary-button" style="font-size:12px;padding:8px 12px">
              Restaurar compra
            </button>
          </div>
        </div>
      `}
    </div>

    <div class="settings-card">
      <span class="eyebrow">ESTADO DE TU VAULT</span>
      <h2>Tu Espacio</h2>
      <div class="settings-row">
        <span>Listas agregadas</span>
        <small>${state.userLists.length} ${state.userLists.length === 1 ? 'lista' : 'listas'} (${state.channels.length} canales)</small>
      </div>
      <div class="settings-row">
        <span>Canales favoritos</span>
        <small>${state.favorites.size} ${state.favorites.size === 1 ? 'canal' : 'canales'}</small>
      </div>
      <div class="settings-row">
        <span>Canales recientes</span>
        <small>${state.recent.length} vistos</small>
      </div>
      <div class="settings-row">
        <span>Modo de uso</span>
        <small style="color:#00e5a3">● Local (Sin servidor requerido)</small>
      </div>
      <div class="settings-row">
        <span>Versión de la app</span>
        <small>${CURRENT_APP_VERSION} · Build ${CURRENT_APP_BUILD}</small>
      </div>
      <div class="settings-row">
        <span>Formato de pantalla</span>
        <small>${escapeHTML({ web: 'Web', phone: 'Android Móvil', tv: 'Chromecast / TV' }[state.device] || 'Adaptable')}</small>
      </div>
      <div class="settings-actions" style="margin-top:14px">
        <button type="button" data-add-m3u="profile" class="primary-button" style="font-size:13px;padding:8px 14px">+ Agregar IPTV (URL)</button>
        <button type="button" id="about-button" class="secondary-button" style="font-size:13px;padding:8px 14px">Acerca de Vault</button>
        ${isLoggedIn ? `<button type="button" id="logout" class="secondary-button danger" style="font-size:13px;padding:8px 14px">Cerrar sesión</button>` : ''}
      </div>
    </div>

    ${admin && state.online ? `
      <div class="settings-card admin-hub">
        <span class="eyebrow">ZONA ADMINISTRADOR</span>
        <h2>Centro de administración</h2>
        <p class="muted">Gestión avanzada del servidor y usuarios centralizados.</p>
        <div class="admin-actions">
          <button data-admin="users"><strong>Usuarios y acceso →</strong><small>Crear cuentas, perfiles infantiles y sesiones</small></button>
          <button data-admin="sync"><strong>Sincronizar IPTV ↻</strong><small>Leer los cambios en tus fuentes ahora</small></button>
        </div>
      </div>
    ` : ''}

    ${!isLoggedIn ? `
      <div class="admin-discreet-wrapper">
        <details class="admin-login-details">
          <summary class="admin-login-summary">
            <span>🔐 Acceso Administrador (Opcional)</span>
            <small style="opacity:.7">Para usuarios con servidor centralizado</small>
          </summary>
          <div class="admin-login-body">
            <p class="admin-login-note">
              Esta sección es exclusiva para administradores que gestionan un servidor Vault. Los usuarios normales no necesitan iniciar sesión ni configurar un servidor.
            </p>
            <form id="login-form">
              <label>Dirección del servidor Vault (Opcional)
                <input name="server" type="url" value="${escapeHTML(state.server || 'http://localhost:8000')}" placeholder="http://localhost:8000" autocomplete="url">
              </label>
              <label>Usuario Administrador
                <input name="username" placeholder="Tu usuario de administrador" required autocomplete="username">
              </label>
              <label>Contraseña
                <input name="password" type="password" placeholder="Tu contraseña" required autocomplete="current-password">
              </label>
              <button class="primary-button" type="submit" style="margin-top:10px">Iniciar sesión de Administrador <span>→</span></button>
              <p class="form-message" id="login-message" role="status"></p>
            </form>
          </div>
        </details>
      </div>
    ` : ''}
  `;
}

function render() {
  const active = document.activeElement;
  let focusSelector = '';
  let cursorPosition = null;
  if ($('#app-content')?.contains(active)) {
    if (active.id) {
      focusSelector = '#' + CSS.escape(active.id);
      if (active.tagName === 'INPUT') cursorPosition = active.selectionStart;
    } else if (active.tagName === 'BUTTON') {
      const attribute = [...active.attributes].find(attr => attr.name.startsWith('data-'));
      if (attribute) focusSelector = `[${attribute.name}="${CSS.escape(attribute.value)}"]`;
    }
  }
  connection();
  updateHeaderProfile();
  $('#app-screen').classList.toggle('compact-library', state.compact);
  $('#unread-count').textContent = String(unreadNotes().length); $('#unread-count').hidden = !unreadNotes().length;
  document.querySelectorAll('.bottom-nav [data-nav]').forEach(button => {
    if (button.dataset.nav === state.tab) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  });
  const headerProfileBtn = $('#header-profile-btn');
  if (headerProfileBtn) {
    if (state.tab === 'profile') headerProfileBtn.setAttribute('aria-current', 'page');
    else headerProfileBtn.removeAttribute('aria-current');
  }
  $('#app-content').innerHTML = ({ home, live, xtream, profile, player }[state.tab] || home)();
  if (state.tab === 'player') {
    initPlayerVideo();
  }
  if (focusSelector) {
    const el = $('#app-content').querySelector(focusSelector) || $('#app-content .filter.active');
    if (el) {
      el.focus({ preventScroll: true });
      if (cursorPosition !== null && typeof el.setSelectionRange === 'function') {
        el.setSelectionRange(cursorPosition, cursorPosition);
      }
    }
  }
}

function navigate(tab) {
  if (state.tab === 'player' && tab !== 'player') {
    cleanupPlayer();
  }
  state.tab = tab;
  render();
  $('#app-content').scrollTop = 0;
  if (state.device === 'tv') $('#app-content button, #app-content input')?.focus();
}
function dialog(html) { $('#dialog-content').innerHTML = html; $('#detail-dialog').showModal(); }
let currentHls = null;
function closeDialog() {
  if (currentHls) {
    try { currentHls.destroy(); } catch (_) {}
    currentHls = null;
  }
  const video = $('#detail-dialog video');
  if (video) {
    video.pause();
    video.removeAttribute('src');
    video.load();
  }
  $('#detail-dialog').classList.remove('video-dialog');
  $('#dialog-content').replaceChildren();
  $('#detail-dialog').close();
}

function cleanupPlayer() {
  if (currentHls) {
    try { currentHls.destroy(); } catch (_) {}
    currentHls = null;
  }
  const video = $('#vault-video-player');
  if (video) {
    video.pause();
    video.removeAttribute('src');
    video.load();
  }
  const iframe = $('#vault-iframe-player');
  if (iframe) {
    try { iframe.src = 'about:blank'; } catch (_) {}
  }
}

function getPlayerGroupChannels() {
  const item = state.playingItem || state.channels[currentChannelIndex];
  if (!item) return state.channels;

  if ((item.type === 'web_embed' || item.type === 'web_video') && state.webEpisodes && state.webEpisodes.length > 0) {
    return state.webEpisodes.map((ep, idx) => ({
      channel_name: ep.title,
      title: ep.title,
      country: 'Web',
      category: 'Capítulos',
      stream_url: ep.stream_url || ep.embed_url || ep.url,
      embed_url: ep.embed_url || '',
      page_url: ep.url,
      type: ep.embed_url ? 'web_embed' : 'web_video',
      epIdx: idx
    }));
  }

  const mode = state.playerGuideMode;
  const val = state.playerGuideValue;

  if (mode === 'country' && val) {
    const list = state.channels.filter(c => (c.country || 'Internacional') === val);
    if (list.length) return list;
  }
  if (mode === 'category' && val) {
    const list = state.channels.filter(c => (c.category || 'General') === val);
    if (list.length) return list;
  }
  if (mode === 'all') {
    return state.channels;
  }

  // Fallback / Auto: match playing channel's country or category
  if (item.country && item.country !== 'Internacional') {
    const list = state.channels.filter(c => (c.country || 'Internacional') === item.country);
    if (list.length) return list;
  }
  if (item.category && item.category !== 'General') {
    const list = state.channels.filter(c => (c.category || 'General') === item.category);
    if (list.length) return list;
  }
  return state.channels;
}

function player() {
  const item = state.playingItem || state.channels[currentChannelIndex] || {};
  const channelName = item.channel_name || item.title || 'Canal en vivo';
  const isFav = state.favorites.has(channelId(item));

  // Determine scoped channel group
  const groupChannels = getPlayerGroupChannels();
  const currentIdxInGroup = groupChannels.findIndex(c => channelId(c) === channelId(item));
  
  // Category & Country info for chips
  const channelCountry = item.country || 'Internacional';
  const channelCategory = item.category || 'General';
  const countryChannelsCount = state.channels.filter(c => (c.country || 'Internacional') === channelCountry).length;
  const categoryChannelsCount = state.channels.filter(c => (c.category || 'General') === channelCategory).length;

  const isWebItem = item.type === 'web_embed' || item.type === 'web_video';
  const mode = state.playerGuideMode;
  let groupTitle = 'Canales';
  let groupBadge = '📺';
  if (isWebItem && state.webEpisodes && state.webEpisodes.length > 0) {
    groupTitle = `Capítulos disponibles (${state.webEpisodes.length})`;
    groupBadge = '🎬';
  } else if (mode === 'country') {
    groupTitle = `Canales de ${state.playerGuideValue || channelCountry}`;
    groupBadge = getCountryFlag(state.playerGuideValue || channelCountry);
  } else if (mode === 'category') {
    groupTitle = `Canales de ${state.playerGuideValue || channelCategory}`;
    groupBadge = getCategoryIcon(state.playerGuideValue || channelCategory);
  } else {
    groupTitle = 'Todos los canales';
    groupBadge = '🌐';
  }

  // Filter scoped group with search query
  const q = (state.playerQuery || '').trim().toLowerCase();
  const visibleGuideChannels = groupChannels.filter(c => {
    if (!q) return true;
    return (c.channel_name || '').toLowerCase().includes(q) ||
           (c.country || '').toLowerCase().includes(q) ||
           (c.category || '').toLowerCase().includes(q);
  });

  const sleepMinutes = state.sleepTimerMinutes || 0;
  const aspectMode = state.playerAspectRatio || 'contain';
  const aspectLabel = aspectMode === 'contain' ? 'Ajustar 16:9' : (aspectMode === 'cover' ? 'Zoom / Llenar' : 'Estirar');

  return `
    <div class="player-page-view">
      <!-- Top Navigation & Channel Header -->
      <div class="player-top-bar">
        <button type="button" id="player-back-btn" class="player-back-pill" title="Volver al listado de canales">
          <span class="back-arrow">←</span>
          <span class="back-text">Volver</span>
        </button>

        <div class="player-now-watching">
          <span class="watching-pulse-dot" title="En directo"></span>
          <div class="watching-meta-col">
            <span class="watching-title" title="${escapeHTML(channelName)}">${escapeHTML(channelName)}</span>
            <div class="watching-tags">
              <span class="watching-tag">${getCountryFlag(item.country)} ${escapeHTML(item.country || 'Internacional')}</span>
              <span class="watching-tag">${getCategoryIcon(item.category)} ${escapeHTML(item.category || 'General')}</span>
            </div>
          </div>
        </div>

        <div class="player-quick-actions">
          <button type="button" id="player-star-toggle" class="player-circle-action ${isFav ? 'starred' : ''}" title="${isFav ? 'Quitar de favoritos' : 'Agregar a favoritos'}" aria-label="Favorito">
            ${isFav ? '★' : '☆'}
          </button>
          <button type="button" id="player-pip-toggle" class="player-circle-action" title="Ventana flotante (PiP)" aria-label="Picture in Picture">
            🗔
          </button>
          <button type="button" id="player-fullscreen-toggle" class="player-circle-action" title="Pantalla completa" aria-label="Pantalla completa">
            ⛶
          </button>
        </div>
      </div>

      <!-- Cinema Video Theater Stage -->
      <div class="player-theater-stage">
        <div class="player-video-box" id="player-video-box">
          <div class="player-overlay-badges">
            <span class="player-overlay-badge live-badge">${item.type === 'web_embed' || item.type === 'web_video' ? '🌐 WEB' : '● EN VIVO'}</span>
            <span class="player-overlay-badge quality-badge" id="player-quality-badge" hidden>HD</span>
            <span class="player-overlay-badge aspect-badge" id="player-aspect-badge">${aspectLabel}</span>
          </div>

          ${item.type === 'web_embed' || item.embed_url ? `
            <iframe id="vault-iframe-player"
                    src="${escapeHTML(item.embed_url)}"
                    allow="autoplay; fullscreen; encrypted-media; picture-in-picture; clipboard-write"
                    allowfullscreen="true"
                    webkitallowfullscreen="true"
                    mozallowfullscreen="true"
                    referrerpolicy="no-referrer"
                    style="width:100%;height:100%;border:none;background:#000;display:block;">
            </iframe>
          ` : `
            <video id="vault-video-player" controls autoplay playsinline style="object-fit:${aspectMode}"></video>
          `}

          <div id="player-spinner" class="player-theater-spinner" hidden>
            <div class="theater-spinner-ring"></div>
            <span>Conectando con la señal…</span>
          </div>

          <div id="player-video-retry" class="player-theater-retry" hidden>
            <span class="retry-icon">⚠️</span>
            <p>Señal interrumpida o no disponible en este momento</p>
            <button type="button" id="player-retry-stream-btn" class="primary-button retry-btn">↻ Reintentar conexión</button>
          </div>
        </div>
      </div>

      <!-- Modern Control Deck -->
      <div class="player-control-deck" aria-label="Controles de reproducción">
        <button type="button" id="player-zap-prev" class="player-deck-btn" title="Canal anterior en esta categoría">
          <span class="deck-icon">⏮</span> Anterior
        </button>
        <button type="button" id="player-zap-next" class="player-deck-btn" title="Canal siguiente en esta categoría">
          Siguiente <span class="deck-icon">⏭</span>
        </button>
        <button type="button" id="player-reconnect-btn" class="player-deck-btn" title="Reiniciar señal IPTV">
          <span class="deck-icon">↻</span> Reconectar
        </button>
        <button type="button" id="player-aspect-toggle" class="player-deck-btn" title="Cambiar escala de video (Ajustar / Zoom / Estirar)">
          <span class="deck-icon">📐</span> ${aspectMode === 'contain' ? 'Ajuste 16:9' : (aspectMode === 'cover' ? 'Zoom' : 'Estirar')}
        </button>
        <button type="button" id="player-mute-toggle" class="player-deck-btn" title="Silenciar / Activar sonido">
          <span class="deck-icon">🔊</span> Audio
        </button>
        <button type="button" id="player-sleep-timer" class="player-deck-btn ${sleepMinutes > 0 ? 'active' : ''}" title="Temporizador de apagado">
          <span class="deck-icon">⏱️</span> ${sleepMinutes > 0 ? `${sleepMinutes} min` : 'Temporizador'}
        </button>
        <button type="button" id="player-copy-link" class="player-deck-btn" title="Copiar enlace de transmisión directa">
          <span class="deck-icon">📋</span> Copiar URL
        </button>
        <button type="button" id="player-external-btn" class="player-deck-btn" title="Abrir en VLC o reproductor externo">
          <span class="deck-icon">↗</span> Externo
        </button>
      </div>

      <!-- Channel Details & EPG Card -->
      <div class="player-details-card">
        <div class="player-channel-info-row">
          <div class="player-channel-badge">
            <span class="player-badge-live">● EN EMISIÓN</span>
            <span class="player-badge-meta">${getCountryFlag(item.country)} ${escapeHTML(item.country || 'Internacional')}</span>
            <span class="player-badge-meta">${getCategoryIcon(item.category)} ${escapeHTML(item.category || 'General')}</span>
            ${item.listName ? `<span class="player-badge-meta list-name-badge">📋 ${escapeHTML(item.listName)}</span>` : ''}
          </div>
          <span class="playback-status-chip" id="playback-message">Conectado a la señal IPTV</span>
        </div>

        <div class="player-epg-info">
          <div class="epg-time-row">
            <span class="epg-time-chip">⏱️ ${escapeHTML(item.program_time || 'En vivo')}</span>
            <span class="epg-order-chip">Canal ${currentIdxInGroup >= 0 ? currentIdxInGroup + 1 : 1} de ${groupChannels.length}</span>
          </div>
          <h2 class="epg-program-heading">${escapeHTML(item.current_program || item.channel_name || 'Programación en vivo')}</h2>
        </div>
      </div>

      ${!state.noAds ? `
        <!-- MONETIZACIÓN: BANNER DEL REPRODUCTOR -->
        <div class="ad-container-section in-player" aria-label="Espacio Publicitario">
          <div class="ad-banner-card player-ad" id="ad-banner-player">
            <div class="ad-tag-row">
              <span class="ad-badge">ANUNCIO · PATROCINADO</span>
              <button type="button" class="ad-remove-hint" data-open-buy-no-ads="1">⭐ Quitar anuncios ($2.99)</button>
            </div>
            <div class="ad-banner-content">
              <span class="ad-banner-icon">📺</span>
              <div class="ad-banner-info">
                <strong>Disfruta sin interrupciones</strong>
                <small>Elimina este espacio con el pase permanente por solo $2.99</small>
              </div>
              <button type="button" class="ad-cta-btn" data-open-buy-no-ads="1">Ver pase</button>
            </div>
          </div>
        </div>
      ` : ''}

      <!-- Scoped Category / Country Channel Guide -->
      <div class="player-channel-guide">
        <div class="guide-header-row">
          <div class="guide-title-wrap">
            <span class="guide-section-title">${groupBadge} ${escapeHTML(groupTitle)}</span>
            <small class="guide-channels-count">${groupChannels.length} canales en esta sección</small>
          </div>
        </div>

        <!-- Quick Switcher Chips: País, Categoría, Todos -->
        ${isWebItem ? `
          <div class="player-guide-chips">
            <span class="player-guide-chip active">🎬 ${state.webEpisodes?.length ? `Capítulos (${state.webEpisodes.length})` : 'Video Web'}</span>
          </div>
        ` : `
        <div class="player-guide-chips">
          ${channelCountry ? `
            <button type="button" class="player-guide-chip ${mode === 'country' ? 'active' : ''}" data-guide-mode="country" data-guide-val="${escapeHTML(channelCountry)}">
              ${getCountryFlag(channelCountry)} ${escapeHTML(channelCountry)} (${countryChannelsCount})
            </button>
          ` : ''}
          ${channelCategory ? `
            <button type="button" class="player-guide-chip ${mode === 'category' ? 'active' : ''}" data-guide-mode="category" data-guide-val="${escapeHTML(channelCategory)}">
              ${getCategoryIcon(channelCategory)} ${escapeHTML(channelCategory)} (${categoryChannelsCount})
            </button>
          ` : ''}
          <button type="button" class="player-guide-chip ${mode === 'all' ? 'active' : ''}" data-guide-mode="all" data-guide-val="Todos">
            🌐 Todos (${state.channels.length})
          </button>
        </div>
        `}

        <div class="guide-search-box">
          <input id="player-guide-search" type="search" value="${escapeHTML(state.playerQuery || '')}" placeholder="Buscar en ${escapeHTML(groupTitle)}…" autocomplete="off">
        </div>

        <div class="guide-channels-scroll">
          ${visibleGuideChannels.slice(0, 100).map((c) => {
            const isPlayingThis = isWebItem
              ? (c.page_url === (item.page_url || item.url) || c.channel_name === (item.channel_name || item.title))
              : channelId(c) === channelId(item);
            const globalIdx = state.channels.indexOf(c);
            return `
              <button type="button" class="guide-channel-item ${isPlayingThis ? 'playing' : ''}"
                      ${isWebItem && c.page_url ? `data-guide-web-ep="${encodeURIComponent(JSON.stringify(c))}"` : `data-zap="${globalIdx >= 0 ? globalIdx : 0}"`}>
                <div class="guide-item-left">
                  <span class="guide-item-flag">${isWebItem ? '🎬' : getCountryFlag(c.country)}</span>
                  <div class="guide-item-names">
                    <strong class="guide-item-title">${escapeHTML(c.channel_name)}</strong>
                    <small class="guide-item-sub">${isWebItem ? `Capítulo · ${escapeHTML(item.category || 'Web')}` : `${getCountryFlag(c.country)} ${escapeHTML(c.country || 'Internacional')} · ${getCategoryIcon(c.category)} ${escapeHTML(c.category || 'General')}`}</small>
                  </div>
                </div>
                ${isPlayingThis ? '<span class="guide-playing-tag">● Sintonizado</span>' : '<span class="guide-play-arrow">▶</span>'}
              </button>
            `;
          }).join('') || '<p class="empty-state" style="padding:14px;text-align:center">No hay canales que coincidan con la búsqueda en esta sección.</p>'}
        </div>
      </div>
    </div>
  `;
}

function initPlayerVideo() {
  const item = state.playingItem || state.channels[currentChannelIndex];
  if (!item) return;
  const spinner = $('#player-spinner');
  const msg = $('#playback-message');
  const qualityBadge = $('#player-quality-badge');
  const aspectBadge = $('#player-aspect-badge');
  const retryOverlay = $('#player-video-retry');

  if (item.type === 'web_embed' || item.embed_url) {
    if (spinner) spinner.hidden = true;
    if (retryOverlay) retryOverlay.hidden = true;
    if (msg) msg.textContent = '🌐 Reproduciendo contenido web embebido';
    return;
  }

  const url = safeURL(item.stream_url);
  const video = $('#vault-video-player');
  if (!video) return;

  if (currentHls) {
    try { currentHls.destroy(); } catch (_) {}
    currentHls = null;
  }

  if (retryOverlay) retryOverlay.hidden = true;

  if (!url) {
    if (msg) msg.textContent = 'El canal no tiene una URL de reproducción activa.';
    if (retryOverlay) retryOverlay.hidden = false;
    return;
  }

  // Apply current aspect ratio
  const aspectMode = state.playerAspectRatio || 'contain';
  video.style.objectFit = aspectMode;
  if (aspectBadge) {
    aspectBadge.textContent = aspectMode === 'contain' ? 'Ajustar 16:9' : (aspectMode === 'cover' ? 'Zoom / Llenar' : 'Estirar');
  }

  if (location.protocol === 'https:' && new URL(url).protocol !== 'https:') {
    toast('Esta fuente HTTP requiere abrir Vault desde HTTP o la app de Android/TV.');
  }

  if (spinner) spinner.hidden = false;
  if (msg) msg.textContent = 'Conectando con la señal en directo…';

  const onLoadedMetadata = () => {
    if (spinner) spinner.hidden = true;
    if (retryOverlay) retryOverlay.hidden = true;
    if (msg) msg.textContent = '● Señal en directo conectada';
    if (qualityBadge && video.videoHeight) {
      qualityBadge.textContent = `${video.videoHeight >= 1080 ? 'FHD' : (video.videoHeight >= 720 ? 'HD' : 'SD')} ${video.videoHeight}p`;
      qualityBadge.hidden = false;
    }
  };
  video.removeEventListener('loadedmetadata', video._vaultMetaHandler);
  video._vaultMetaHandler = onLoadedMetadata;
  video.addEventListener('loadedmetadata', onLoadedMetadata, { once: true });

  const isM3U8 = url.includes('.m3u8') || url.includes('m3u8') || url.includes('/live/') || url.includes('playlist');

  if (typeof Hls !== 'undefined' && Hls.isSupported() && isM3U8) {
    const hls = new Hls({
      enableWorker: true,
      lowLatencyMode: true,
      backBufferLength: 60,
      maxBufferLength: 30,
      maxMaxBufferLength: 60,
      manifestLoadingTimeOut: 15000,
      manifestLoadingMaxRetry: 5,
      manifestLoadingRetryDelay: 1000,
      fragLoadingTimeOut: 20000,
      fragLoadingMaxRetry: 6,
      fragLoadingRetryDelay: 1000,
    });
    currentHls = hls;
    hls.loadSource(url);
    hls.attachMedia(video);

    hls.on(Hls.Events.MANIFEST_PARSED, (ev, data) => {
      if (spinner) spinner.hidden = true;
      if (retryOverlay) retryOverlay.hidden = true;
      if (msg) msg.textContent = '● Señal en directo conectada';
      if (qualityBadge && data.levels && data.levels.length) {
        const topLevel = data.levels[data.levels.length - 1];
        if (topLevel.height) {
          qualityBadge.textContent = `${topLevel.height >= 1080 ? 'FHD' : (topLevel.height >= 720 ? 'HD' : 'SD')} ${topLevel.height}p`;
          qualityBadge.hidden = false;
        }
      }
      video.play().catch(() => {});
    });

    hls.on(Hls.Events.LEVEL_SWITCHED, (ev, data) => {
      if (hls.levels && hls.levels[data.level] && qualityBadge) {
        const lvl = hls.levels[data.level];
        if (lvl.height) {
          qualityBadge.textContent = `${lvl.height >= 1080 ? 'FHD' : (lvl.height >= 720 ? 'HD' : 'SD')} ${lvl.height}p`;
        }
      }
    });

    hls.on(Hls.Events.ERROR, (_, data) => {
      console.warn('HLS player event:', data.details, data.type);
      if (data.fatal) {
        switch (data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            console.warn('Network error on HLS, attempting recovery...');
            hls.startLoad();
            break;
          case Hls.ErrorTypes.MEDIA_ERROR:
            console.warn('Media error on HLS, attempting recovery...');
            hls.recoverMediaError();
            break;
          default:
            console.warn('Unrecoverable HLS error, attempting direct native playback fallback...');
            try { hls.destroy(); } catch (_) {}
            currentHls = null;
            video.src = url;
            video.load();
            video.play().catch(() => {});
            break;
        }
      }
    });
  } else {
    // Direct native video playback (MP4, direct TS or Safari / Android native HLS)
    video.src = url;
    video.load();
    video.play().catch(() => {});
  }

  video.addEventListener('error', () => {
    if (spinner) spinner.hidden = true;
    if (retryOverlay) retryOverlay.hidden = false;
    if (msg) msg.textContent = 'No se pudo cargar la emisión. Presiona Reconectar o verifica la señal.';
  }, { once: true });
}

function play(item, channelIndex) {
  if (item?.type === 'series' && item?.series_id) {
    openXtreamSeries(item);
    return;
  }
  if (channelIndex !== undefined) {
    currentChannelIndex = channelIndex;
  } else {
    const idx = state.channels.findIndex(c => channelId(c) === channelId(item));
    currentChannelIndex = idx >= 0 ? idx : 0;
  }
  state.playingItem = item;
  state.playingIndex = currentChannelIndex;
  if (state.tab !== 'player') {
    state.previousTab = state.tab || 'live';
  }

  // Determine active category/country context for the player switcher panel
  if (state.categoryFilter && state.categoryFilter !== 'Todas') {
    state.playerGuideMode = 'category';
    state.playerGuideValue = state.categoryFilter;
  } else if (state.countryFilter && state.countryFilter !== 'Todos') {
    state.playerGuideMode = 'country';
    state.playerGuideValue = state.countryFilter;
  } else if (item.country && item.country !== 'Internacional') {
    state.playerGuideMode = 'country';
    state.playerGuideValue = item.country;
  } else if (item.category && item.category !== 'General') {
    state.playerGuideMode = 'category';
    state.playerGuideValue = item.category;
  } else {
    state.playerGuideMode = 'all';
    state.playerGuideValue = 'Todos';
  }

  state.playerQuery = '';
  markRecent(item);
  state.tab = 'player';
  render();
}

async function openXtreamSeries(item) {
  const list = state.userLists.find(l => l.id === item.listId);
  if (!list) return toast('No se encontró la configuración de esta serie.');
  toast('Cargando episodios...');
  let episodes = [];
  try {
    const res = await fetch(`${list.url}/player_api.php?username=${encodeURIComponent(list.username)}&password=${encodeURIComponent(list.password)}&action=get_series_info&series_id=${encodeURIComponent(item.series_id)}`, { signal: AbortSignal.timeout(15000) });
    if (res.ok) {
      const raw = await res.json();
      if (raw && raw.episodes && typeof raw.episodes === 'object') {
        for (const season of Object.values(raw.episodes)) {
          for (const ep of (Array.isArray(season) ? season : [])) {
            const ident = String(ep.id || '');
            const ext = String(ep.container_extension || 'mp4').replace(/[^a-zA-Z0-9]/g, '') || 'mp4';
            if (/^\d+$/.test(ident)) {
              episodes.push({
                id: ident,
                title: ep.title || `Episodio ${ident}`,
                channel_name: ep.title || `Episodio ${ident}`,
                type: 'episode',
                stream_url: `${list.url}/series/${encodeURIComponent(list.username)}/${encodeURIComponent(list.password)}/${ident}.${ext}`
              });
            }
          }
        }
      }
    }
  } catch (_) {}

  if (!episodes.length && state.server) {
    try {
      const res = await api('/xtream/episodes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          server: list.url,
          username: list.username,
          password: list.password,
          section: 'series',
          series_id: item.series_id
        })
      });
      episodes = (res.items || []).map(ep => ({ ...ep, channel_name: ep.title }));
    } catch (err) {
      return toast(err.message);
    }
  }

  if (!episodes.length) return toast('No se encontraron episodios disponibles.');
  window._xtreamEpisodes = episodes;
  dialog(`
    <span class="eyebrow">SERIE XTREAM</span>
    <h2>${escapeHTML(item.channel_name || item.title)}</h2>
    <p class="muted">${episodes.length} episodios disponibles</p>
    <div class="inbox-list" style="max-height:50vh;overflow:auto">
      ${episodes.map((ep, idx) => `
        <button class="channel" data-xtream-episode="${idx}" style="width:100%;margin-bottom:8px">
          <span class="channel-logo">▶</span>
          <div><h3>${escapeHTML(ep.title)}</h3><small>Episodio</small></div>
        </button>
      `).join('')}
    </div>
  `);
}

async function sync() {
  if (!state.token || syncing) return;
  syncing = true;
  try {
    await api('/health'); state.online = true; state.serverDetected = true;
    state.user = await api('/auth/me');
    const results = await Promise.allSettled([
      api('/iptv/channels', { headers: state.channelEtag ? { 'If-None-Match': state.channelEtag } : {} }),
      api('/plex/library'),
      api('/notifications/')
    ]);
    if (!state.token) return;
    if (results[0].status === 'fulfilled') state.serverChannels = Array.isArray(results[0].value) ? results[0].value : [];
    if (results[1].status === 'fulfilled') state.library = Array.isArray(results[1].value) ? results[1].value : [];
    if (results[2].status === 'fulfilled') state.notes = Array.isArray(results[2].value) ? results[2].value : [];
    rebuildChannelsFromLists();
    connection();
    render();
  } catch {
    if (state.token) { state.online = false; connection(); }
  } finally { syncing = false; }
}

async function checkForOTAUpdates(manual = false) {
  if (!state.server) return;
  const platform = document.querySelector('meta[name="app-platform"]')?.content;
  if (!platform) {
    if (manual) toast('La versión web siempre está actualizada. Las actualizaciones OTA son para las apps de Android y TV.');
    return;
  }
  try {
    const res = await fetch(state.server + '/updates/check?platform=' + encodeURIComponent(platform), { signal: AbortSignal.timeout(4000) });
    if (!res.ok) {
      if (manual) toast('No se pudo verificar actualizaciones.');
      return;
    }
    const data = await res.json();
    const newBuild = Number(data.build_number || data.latest_build || 0);
    const newVer = String(data.version || data.latest_version || '');
    if (data.available && newBuild > CURRENT_APP_BUILD) {
      dialog(`
        <div class="update-dialog-card">
          <div class="update-icon">🚀</div>
          <span class="eyebrow" style="color:#00ffaa">ACTUALIZACIÓN DISPONIBLE</span>
          <h2 style="margin:4px 0 8px">Nueva versión de Vault</h2>
          <span class="update-version-tag">Versión ${escapeHTML(newVer)} (Build ${newBuild})</span>
          <p class="muted" style="margin:0">Hay una nueva versión disponible para tu dispositivo con mejoras y optimizaciones.</p>
          <div class="update-notes-box">
            <strong>Novedades:</strong>
            <p style="margin:4px 0 0;white-space:pre-wrap">${escapeHTML(data.release_notes || 'Mejoras de rendimiento y estabilidad.')}</p>
          </div>
          <div style="display:flex;flex-direction:column;gap:8px;margin-top:14px">
            <a href="${escapeHTML(data.apk_download_url)}" target="_blank" download class="primary-button" style="text-decoration:none;display:flex;align-items:center;justify-content:center;gap:6px">
              ⬇ Descargar e Instalar Actualización (APK)
            </a>
            <button id="close-dialog" class="secondary-button">Recordármelo más tarde</button>
          </div>
        </div>
      `);
    } else if (manual) {
      toast('Tu app de Vault está en la versión más reciente (v' + CURRENT_APP_VERSION + ').');
    }
  } catch (err) {
    if (manual) toast('Error al buscar actualizaciones: ' + err.message);
  }
}

async function probeServer(url) {
  try {
    const res = await fetch(url + '/health', { signal: AbortSignal.timeout(800) });
    if (res.ok) {
      const data = await res.json();
      if (data.status === 'online' || data.status === 'ok') return url;
    }
  } catch (_) {}
  return null;
}

async function autoDetectServer() {
  const splashStatus = $('#splash-status');
  if (splashStatus) splashStatus.textContent = 'Iniciando Vault…';

  const candidates = [];
  if (typeof location !== 'undefined' && /^https?:/.test(location.origin)) {
    candidates.push(location.origin);
  }
  try {
    const cached = localStorage.getItem('vault_server');
    if (cached) candidates.push(cached);
  } catch (_) {}
  candidates.push('http://localhost:8000');
  candidates.push('http://127.0.0.1:8000');
  candidates.push('http://10.0.2.2:8000');
  if (typeof location !== 'undefined' && location.hostname && !['localhost', '127.0.0.1'].includes(location.hostname)) {
    candidates.push(`http://${location.hostname}:8000`);
  }

  const unique = [...new Set(candidates.filter(Boolean))];
  let found = null;
  try {
    const results = await Promise.allSettled(unique.map(c => probeServer(c)));
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value) {
        found = r.value;
        break;
      }
    }
  } catch (_) {}

  const finalServer = found || '';
  state.server = finalServer;
  state.serverDetected = Boolean(found);
  state.online = Boolean(found);
  if (found) {
    try { localStorage.setItem('vault_server', finalServer); } catch (_) {}
  }

  if (splashStatus) {
    splashStatus.textContent = 'Listo en modo local';
  }
  return finalServer;
}

function dismissSplash() {
  const splash = $('#splash-screen');
  if (!splash) return;
  splash.classList.add('splash-fade-out');
  setTimeout(() => {
    try { splash.remove(); } catch (_) { splash.hidden = true; }
  }, 600);
}

document.addEventListener('click', async event => {
  if (event.target.id === 'notif-dismiss-btn') {
    return hideNotification();
  }
  if (event.target.id === 'offline-retry-btn') {
    toast('Comprobando conexión de red…');
    updateOnlineStatus();
    return;
  }
  const fillBtn = event.target.closest('[data-fill-url]');
  if (fillBtn) {
    const u = fillBtn.dataset.fillUrl;
    const inp = $('#web-extractor-url-input');
    if (inp) {
      inp.value = u;
      inp.focus();
    }
    return runWebExtractor(u);
  }
  if (event.target.id === 'shortcut-lacartoons-btn') {
    const inp = $('#web-extractor-url-input');
    if (inp) {
      inp.value = 'https://lacartoons.com/';
      runWebExtractor('https://lacartoons.com/', 'LACartoons');
    }
    return;
  }

  const fallbackPlayBtn = event.target.closest('#web-extractor-fallback-play, #web-extractor-direct-play-btn');
  if (fallbackPlayBtn) {
    const targetUrl = fallbackPlayBtn.dataset.targetUrl || ($('#web-extractor-url-input')?.value || '').trim();
    if (targetUrl) {
      closeDialog();
      toast('🎬 Cargando en reproductor integrado…');
      return play({
        channel_name: 'Página Web / Video',
        title: 'Página Web / Video',
        type: 'web_embed',
        stream_url: targetUrl,
        embed_url: targetUrl,
        page_url: targetUrl,
        country: 'Web',
        category: 'Web Directa'
      });
    }
    return;
  }

  const guideWebEpBtn = event.target.closest('[data-guide-web-ep]');
  if (guideWebEpBtn) {
    try {
      const epData = JSON.parse(decodeURIComponent(guideWebEpBtn.dataset.guideWebEp));
      return loadAndPlayWebEpisode(epData);
    } catch (e) {
      console.warn('Error loading guide web ep:', e);
    }
  }

  const webEpBtn = event.target.closest('[data-play-web-ep]');
  if (webEpBtn) {
    try {
      const epData = JSON.parse(decodeURIComponent(webEpBtn.dataset.playWebEp));
      return loadAndPlayWebEpisode(epData);
    } catch (e) {
      console.warn('Error playing web ep:', e);
    }
  }

  const webSerieCard = event.target.closest('[data-open-web-serie]');
  if (webSerieCard) {
    const serieUrl = webSerieCard.dataset.openWebSerie;
    const serieTitle = webSerieCard.dataset.serieTitle || '';
    return runWebExtractor(serieUrl, serieTitle);
  }

  if (event.target.id === 'web-extractor-back-to-series') {
    if (state.webSeries && state.webSeries.length > 0) {
      const resultsEl = $('#web-extractor-results');
      if (resultsEl) {
        resultsEl.innerHTML = `
          <div class="web-extracted-header">
            <h3>📺 Series y contenidos encontrados (${state.webSeries.length})</h3>
            <p class="muted">Selecciona una serie para ver sus capítulos y reproducir:</p>
          </div>
          <div class="web-series-grid">
            ${state.webSeries.map(s => `
              <div class="web-serie-card" data-open-web-serie="${escapeHTML(s.url)}" data-serie-title="${escapeHTML(s.title)}">
                ${s.poster ? `<img src="${escapeHTML(s.poster)}" alt="" class="web-serie-poster" onerror="this.style.display='none'">` : `<div class="web-serie-poster-placeholder">📺</div>`}
                <div class="web-serie-info">
                  <strong>${escapeHTML(s.title)}</strong>
                  <button type="button" class="primary-button compact">Ver capítulos →</button>
                </div>
              </div>
            `).join('')}
          </div>
        `;
      }
    }
    return;
  }

  if (event.target.id === 'web-extractor-paste-btn') {
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        const input = $('#web-extractor-url-input');
        if (input) {
          input.value = text.trim();
          input.focus();
        }
        toast('✓ Enlace pegado del portapapeles');
      }
    } catch (_) {
      toast('Pega el enlace directamente en la casilla.');
    }
    return;
  }
  const starBtn = event.target.closest('[data-star]');
  if (starBtn) {
    event.stopPropagation();
    const ch = state.channels[Number(starBtn.dataset.star)];
    if (ch) {
      const id = channelId(ch);
      if (!state.favorites.delete(id)) state.favorites.add(id);
      saveChannelPreferences();
      render();
    }
    return;
  }

  const channelCard = event.target.closest('[data-channel]');
  if (channelCard) {
    const chIdx = Number(channelCard.dataset.channel);
    const ch = state.channels[chIdx];
    if (ch) {
      markRecent(ch);
      return play(ch, chIdx);
    }
  }

  const button = event.target.closest('button,a[data-nav]');
  if (!button) return;

  if (button.id === 'show-register-btn') {
    state.authMode = 'register';
    return render();
  }
  if (button.id === 'show-login-btn') {
    state.authMode = 'login';
    return render();
  }
  if (button.id === 'toggle-server-btn') {
    state.showServerField = !state.showServerField;
    return render();
  }

  if (button.dataset.openWebExtractor !== undefined || button.id === 'open-web-extractor-btn') {
    return openWebExtractorDialog();
  }
  if (button.dataset.addM3u !== undefined || button.id === 'open-add-m3u-btn') {
    return openAddM3UDialog();
  }
  if (button.dataset.addXtream !== undefined || button.id === 'open-add-xtream-btn') {
    return openAddXtreamDialog();
  }

  if (button.id === 'buy-no-ads-btn' || button.dataset.openBuyNoAds !== undefined) {
    return openCheckoutDialog();
  }
  if (button.id === 'restore-purchase-btn') {
    if (state.noAds) {
      return toast('✓ Tu dispositivo ya tiene activa la licencia sin publicidad.');
    }
    state.noAds = true;
    try { localStorage.setItem('vault_no_ads', 'true'); } catch (_) {}
    render();
    return toast('✓ Compra restaurada con éxito: Anuncios eliminados.');
  }
  if (button.id === 'restore-ads-dev-btn') {
    state.noAds = false;
    try { localStorage.removeItem('vault_no_ads'); } catch (_) {}
    render();
    return toast('Anuncios restablecidos (Modo prueba activado).');
  }

  if (button.dataset.openList) {
    state.listFilter = button.dataset.openList;
    state.countryFilter = 'Todos';
    state.categoryFilter = 'Todas';
    state.channelPageLimit = 60;
    return navigate('live');
  }

  if (button.dataset.refreshList) {
    const listId = button.dataset.refreshList;
    const list = state.userLists.find(l => l.id === listId);
    if (!list) return;
    button.disabled = true;
    toast(`Actualizando "${list.name}"...`);
    try {
      if (list.type === 'xtream') {
        const updated = await fetchAndAddXtreamList({
          name: list.name,
          server: list.url,
          username: list.username,
          password: list.password,
          section: list.section || 'live'
        }, list.id);
        toast(`"${updated.name}" actualizada (${updated.channels.length} canales).`);
      } else {
        const updated = await fetchAndAddM3UList(list.name, list.url, list.id);
        toast(`"${updated.name}" actualizada (${updated.channels.length} canales).`);
      }
      render();
    } catch (err) {
      toast(err.message);
    } finally {
      button.disabled = false;
    }
    return;
  }

  if (button.dataset.deleteList) {
    const listId = button.dataset.deleteList;
    const list = state.userLists.find(l => l.id === listId);
    if (!list) return;
    state.userLists = state.userLists.filter(l => l.id !== listId);
    if (state.listFilter === listId) state.listFilter = 'all';
    saveUserLists();
    rebuildChannelsFromLists();
    render();
    toast(`Lista "${list.name}" eliminada.`);
    return;
  }

  if (button.dataset.listFilter !== undefined) {
    state.listFilter = button.dataset.listFilter;
    state.countryFilter = 'Todos';
    state.categoryFilter = 'Todas';
    state.channelPageLimit = 60;
    return render();
  }

  if (button.dataset.xtreamEpisode !== undefined) {
    const ep = window._xtreamEpisodes?.[Number(button.dataset.xtreamEpisode)];
    if (ep) play(ep);
    return;
  }

  if (button.id === 'check-ota-btn') {
    return checkForOTAUpdates(true);
  }
  if (button.id === 'refresh-iptv-btn' || button.id === 'modal-sync-btn') {
    button.disabled = true;
    toast('Sincronizando listas...');
    try {
      if (state.token) {
        await api('/iptv/refresh', { method: 'POST' });
        await sync();
      }
      render();
      toast(`Listas sincronizadas: ${state.channels.length} canales`);
    } catch (err) {
      toast('Error al sincronizar: ' + err.message);
    } finally {
      button.disabled = false;
    }
    return;
  }
  if (button.id === 'player-back-btn') {
    cleanupPlayer();
    return navigate(state.previousTab || 'live');
  }
  if (button.id === 'player-star-toggle') {
    const ch = state.playingItem || state.channels[currentChannelIndex];
    if (ch) {
      const id = channelId(ch);
      if (state.favorites.has(id)) state.favorites.delete(id);
      else state.favorites.add(id);
      saveChannelPreferences();
      button.classList.toggle('starred', state.favorites.has(id));
      button.textContent = state.favorites.has(id) ? '★' : '☆';
    }
    return;
  }
  if (button.id === 'player-pip-toggle') {
    const video = $('#vault-video-player');
    if (video) {
      if (document.pictureInPictureElement) {
        document.exitPictureInPicture().catch(() => {});
      } else if (video.requestPictureInPicture) {
        video.requestPictureInPicture().catch(() => toast('Picture-in-Picture no está disponible en este dispositivo.'));
      } else {
        toast('Tu navegador o dispositivo no soporta Picture-in-Picture.');
      }
    }
    return;
  }
  if (button.id === 'player-fullscreen-toggle') {
    const box = $('#player-video-box') || $('#vault-video-player');
    if (!document.fullscreenElement) {
      (box.requestFullscreen || box.webkitRequestFullscreen || box.msRequestFullscreen)?.call(box);
    } else {
      (document.exitFullscreen || document.webkitExitFullscreen)?.call(document);
    }
    return;
  }
  if (button.id === 'player-zap-prev') {
    if ((state.playingItem?.type === 'web_embed' || state.playingItem?.type === 'web_video') && state.webEpisodes?.length) {
      const curIdx = state.webEpisodes.findIndex(e => e.url === state.playingItem?.page_url || e.title === state.playingItem?.title);
      const nextIdx = (curIdx - 1 + state.webEpisodes.length) % state.webEpisodes.length;
      return loadAndPlayWebEpisode(state.webEpisodes[nextIdx]);
    }
    const group = getPlayerGroupChannels();
    if (group.length > 0) {
      const curItem = state.playingItem || state.channels[currentChannelIndex];
      const curIdx = group.findIndex(c => channelId(c) === channelId(curItem));
      const nextIdx = (curIdx - 1 + group.length) % group.length;
      const targetChannel = group[nextIdx];
      const globalIdx = state.channels.indexOf(targetChannel);
      return play(targetChannel, globalIdx >= 0 ? globalIdx : 0);
    }
    return;
  }
  if (button.id === 'player-zap-next') {
    if ((state.playingItem?.type === 'web_embed' || state.playingItem?.type === 'web_video') && state.webEpisodes?.length) {
      const curIdx = state.webEpisodes.findIndex(e => e.url === state.playingItem?.page_url || e.title === state.playingItem?.title);
      const nextIdx = (curIdx + 1) % state.webEpisodes.length;
      return loadAndPlayWebEpisode(state.webEpisodes[nextIdx]);
    }
    const group = getPlayerGroupChannels();
    if (group.length > 0) {
      const curItem = state.playingItem || state.channels[currentChannelIndex];
      const curIdx = group.findIndex(c => channelId(c) === channelId(curItem));
      const nextIdx = (curIdx + 1) % group.length;
      const targetChannel = group[nextIdx];
      const globalIdx = state.channels.indexOf(targetChannel);
      return play(targetChannel, globalIdx >= 0 ? globalIdx : 0);
    }
    return;
  }
  if (button.id === 'player-reconnect-btn' || button.id === 'player-retry-stream-btn') {
    toast('↻ Reconectando señal IPTV…');
    initPlayerVideo();
    return;
  }
  if (button.id === 'player-aspect-toggle') {
    const modes = ['contain', 'cover', 'fill'];
    const cur = state.playerAspectRatio || 'contain';
    const nextMode = modes[(modes.indexOf(cur) + 1) % modes.length];
    state.playerAspectRatio = nextMode;
    const video = $('#vault-video-player');
    if (video) video.style.objectFit = nextMode;
    const aspectBadge = $('#player-aspect-badge');
    const label = nextMode === 'contain' ? 'Ajustar 16:9' : (nextMode === 'cover' ? 'Zoom / Llenar' : 'Estirar');
    if (aspectBadge) aspectBadge.textContent = label;
    button.innerHTML = `<span class="deck-icon">📐</span> ${nextMode === 'contain' ? 'Ajuste 16:9' : (nextMode === 'cover' ? 'Zoom' : 'Estirar')}`;
    toast(`Escala de video: ${label}`);
    return;
  }
  if (button.id === 'player-mute-toggle') {
    const video = $('#vault-video-player');
    if (video) {
      video.muted = !video.muted;
      button.innerHTML = `<span class="deck-icon">${video.muted ? '🔇' : '🔊'}</span> ${video.muted ? 'Silenciado' : 'Audio'}`;
      toast(video.muted ? 'Audio silenciado' : 'Audio activado');
    }
    return;
  }
  if (button.id === 'player-sleep-timer') {
    const options = [0, 15, 30, 60];
    const curMin = state.sleepTimerMinutes || 0;
    const nextMin = options[(options.indexOf(curMin) + 1) % options.length];
    state.sleepTimerMinutes = nextMin;
    if (state.sleepTimer) {
      clearTimeout(state.sleepTimer);
      state.sleepTimer = null;
    }
    if (nextMin > 0) {
      state.sleepTimer = setTimeout(() => {
        const v = $('#vault-video-player');
        if (v) v.pause();
        toast('⏱️ Temporizador de apagado: emisión pausada.');
        state.sleepTimerMinutes = 0;
        render();
      }, nextMin * 60 * 1000);
      button.classList.add('active');
      button.innerHTML = `<span class="deck-icon">⏱️</span> ${nextMin} min`;
      toast(`⏱️ Temporizador configurado para ${nextMin} minutos.`);
    } else {
      button.classList.remove('active');
      button.innerHTML = `<span class="deck-icon">⏱️</span> Temporizador`;
      toast('⏱️ Temporizador desactivado.');
    }
    return;
  }
  if (button.id === 'player-copy-link') {
    const item = state.playingItem || state.channels[currentChannelIndex];
    if (item && item.stream_url) {
      try {
        navigator.clipboard.writeText(item.stream_url);
        toast('📋 Enlace de transmisión copiado al portapapeles.');
      } catch (_) {
        prompt('Copia el enlace del canal:', item.stream_url);
      }
    }
    return;
  }
  if (button.id === 'player-external-btn') {
    const item = state.playingItem || state.channels[currentChannelIndex];
    if (item && item.stream_url) {
      window.open(item.stream_url, '_system') || window.open(item.stream_url, '_blank');
      try { navigator.clipboard.writeText(item.stream_url); } catch (_) {}
      toast('Abriendo en reproductor externo / Enlace copiado.');
    }
    return;
  }

  if (button.dataset.guideMode !== undefined) {
    state.playerGuideMode = button.dataset.guideMode;
    state.playerGuideValue = button.dataset.guideVal || '';
    state.playerQuery = '';
    return render();
  }

  if (button.dataset.zap !== undefined) {
    const zapIndex = Number(button.dataset.zap);
    const ch = state.channels[zapIndex];
    if (ch) {
      markRecent(ch);
      play(ch, zapIndex);
    }
    return;
  }
  if (button.id === 'toggle-drawer-btn') {
    const drawer = $('#player-drawer');
    if (drawer) drawer.hidden = !drawer.hidden;
    return;
  }
  if (button.dataset.admin || button.dataset.userAction) return handleAdmin(button);
  if (button.dataset.device) return setDevice(button.dataset.device);
  if (button.dataset.nav) { event.preventDefault(); return navigate(button.dataset.nav); }
  if (button.dataset.toast) return toast(button.dataset.toast);
  if (button.id === 'edit-name') {
    const name = state.user?.display_name || state.user?.custom_username || '';
    return dialog(`<span class="eyebrow">TU PERFIL</span><h2>Editar nombre</h2><form id="profile-name-form"><label>Nombre visible<input name="display_name" value="${escapeHTML(name)}" maxlength="80" required autocomplete="nickname"></label><button class="primary-button">Guardar</button><p class="muted">Tu usuario de inicio de sesión seguirá siendo el mismo.</p></form>`);
  }
  if (['inbox-button', 'notice-open'].includes(button.id)) return inbox();
  if (button.dataset.readNote !== undefined || button.id === 'read-all-notes') {
    const notes = button.id === 'read-all-notes' ? activeNotes() : [activeNotes()[Number(button.dataset.readNote)]];
    notes.forEach(note => state.readNotices.add(notificationId(note)));
    saveLibraryPreferences(); render(); closeDialog(); inbox(); return;
  }
  if (button.dataset.channelView) { state.channelView = button.dataset.channelView; return render(); }
  if (button.id === 'sort-channels') { state.alphabetical = !state.alphabetical; return render(); }
  if (button.dataset.countryFilter !== undefined) {
    state.countryFilter = button.dataset.countryFilter;
    state.channelPageLimit = 60;
    return render();
  }
  if (button.dataset.categoryFilter !== undefined) {
    state.categoryFilter = button.dataset.categoryFilter;
    state.channelPageLimit = 60;
    return render();
  }
  if (button.id === 'load-more-channels-btn') {
    state.channelPageLimit = (state.channelPageLimit || 60) + 60;
    return render();
  }
  if (button.dataset.filter) { state.filter = button.dataset.filter; return render(); }
  if (button.dataset.xtream !== undefined) {
    const item = state.xtream[Number(button.dataset.xtream)];
    if (!item) return;
    if (item.type === 'series' && item.series_id) return openXtreamSeries(item);
    return play(item);
  }
  switch (button.id) {
    case 'close-dialog': return closeDialog();
    case 'about-button': return dialog('<span class="eyebrow">TU ESPACIO DE ENTRETENIMIENTO</span><h2>Vault</h2><p class="muted">IPTV y Xtream Codes en una sola app. Agrega tus propias listas por URL o credenciales Xtream y reprodúcelas al instante.</p>');
    case 'logout':
      if (state.token) await api('/auth/logout', { method: 'POST' }).catch(() => {});
      try { localStorage.removeItem('vault_session'); } catch (_) {}
      state.token = ''; state.user = null; state.serverChannels = []; state.library = []; state.notes = [];
      rebuildChannelsFromLists();
      updateHeaderProfile();
      render();
      toast('Sesión cerrada.');
      return;
  }
});

document.addEventListener('change', event => {
  if (event.target.id === 'country-select') {
    state.countryFilter = event.target.value;
    state.channelPageLimit = 60;
    render();
  }
  if (event.target.id === 'player-guide-search') {
    state.playerQuery = event.target.value;
    const q = event.target.value.trim().toLowerCase();
    document.querySelectorAll('.guide-channel-item').forEach(item => {
      const name = item.querySelector('.guide-item-title')?.textContent.toLowerCase() || '';
      const sub = item.querySelector('.guide-item-sub')?.textContent.toLowerCase() || '';
      const matches = !q || name.includes(q) || sub.includes(q);
      item.style.display = matches ? 'flex' : 'none';
    });
  }
});

document.addEventListener('input', event => {
  if (event.target.id === 'channel-search') {
    state.query = event.target.value;
    state.channelPageLimit = 60;
    render();
  }
  if (event.target.id === 'player-guide-search') {
    state.playerQuery = event.target.value;
    const q = event.target.value.trim().toLowerCase();
    document.querySelectorAll('.guide-channel-item').forEach(item => {
      const name = item.querySelector('.guide-item-title')?.textContent.toLowerCase() || '';
      const sub = item.querySelector('.guide-item-sub')?.textContent.toLowerCase() || '';
      const matches = !q || name.includes(q) || sub.includes(q);
      item.style.display = matches ? 'flex' : 'none';
    });
  }
});

document.addEventListener('submit', async event => {
  const form = event.target;
  const handled = ['login-form', 'register-form', 'add-m3u-form', 'add-xtream-modal-form', 'xtream-form', 'notice-form', 'profile-name-form', 'admin-create-form', 'checkout-purchase-form', 'web-extractor-form'];
  if (!handled.includes(form.id)) return;
  event.preventDefault();
  const button = form.querySelector('button[type="submit"]') || form.querySelector('button');
  if (button) button.disabled = true;

  try {
    if (form.id === 'web-extractor-form') {
      const urlInput = form.elements.web_url;
      const targetUrl = (urlInput ? urlInput.value : '').trim();
      if (!targetUrl) return toast('Por favor ingresa una URL válida.');
      await runWebExtractor(targetUrl);
      return;
    }
    if (form.id === 'checkout-purchase-form') {
      state.noAds = true;
      try {
        localStorage.setItem('vault_no_ads', 'true');
      } catch (_) {}
      closeDialog();
      render();
      toast('🎉 ¡Pago de $2.99 completado! Anuncios eliminados permanentemente.');
      return;
    }
    if (form.id === 'login-form') {
      const msgEl = $('#login-message');
      if (msgEl) msgEl.textContent = 'Conectando…';
      try {
        const srvVal = form.elements.server?.value.trim() || state.server || 'http://localhost:8000';
        state.server = serverURL(srvVal);
        const result = await api('/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ username: form.elements.username.value, password: form.elements.password.value })
        });
        state.token = result.access_token;
        state.user = await api('/auth/me');
        try {
          localStorage.setItem('vault_session', JSON.stringify({ server: state.server, token: state.token, user: state.user }));
          localStorage.setItem('vault_server', state.server);
        } catch (_) {}
        loadChannelPreferences();
        loadLibraryPreferences();
        form.elements.password.value = '';
        state.online = true;
        state.serverDetected = true;
        updateHeaderProfile();
        await sync();
        render();
        toast(`¡Bienvenido, ${state.user.display_name || state.user.custom_username}!`);
        checkForOTAUpdates();
      } catch (err) {
        state.token = '';
        if (msgEl) msgEl.textContent = err instanceof TypeError ? 'No se pudo conectar. Revisa la dirección y que el servidor esté encendido.' : err.message;
      }
      return;
    }

    if (form.id === 'register-form') {
      const msgEl = $('#register-message');
      if (msgEl) msgEl.textContent = 'Creando cuenta…';
      try {
        const srvInput = form.elements.reg_server?.value.trim() || state.server || 'http://localhost:8000';
        state.server = serverURL(srvInput);
        const username = form.elements.reg_username.value.trim();
        const displayName = form.elements.reg_display_name?.value.trim() || username;
        const password = form.elements.reg_password.value;
        if (password.length < 6) throw new Error('La contraseña debe tener al menos 6 caracteres.');

        const regRes = await fetch(state.server + '/auth/register', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ custom_username: username, password, display_name: displayName, profile_type: 'standard' })
        });
        if (!regRes.ok) {
          const errData = await regRes.json().catch(() => ({}));
          throw new Error(errData.detail || `Error al registrarse (${regRes.status})`);
        }
        if (msgEl) msgEl.textContent = 'Cuenta creada. Iniciando sesión…';
        const loginResult = await api('/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ username, password })
        });
        state.token = loginResult.access_token;
        state.user = await api('/auth/me');
        try {
          localStorage.setItem('vault_session', JSON.stringify({ server: state.server, token: state.token, user: state.user }));
          localStorage.setItem('vault_server', state.server);
        } catch (_) {}
        loadChannelPreferences();
        loadLibraryPreferences();
        state.online = true;
        state.serverDetected = true;
        state.authMode = 'login';
        updateHeaderProfile();
        await sync();
        render();
        toast(`¡Bienvenido a Vault, ${displayName}!`);
        checkForOTAUpdates();
      } catch (err) {
        if (msgEl) msgEl.textContent = err.message;
      }
      return;
    }

    if (form.id === 'add-m3u-form') {
      const msgEl = $('#add-m3u-message');
      if (msgEl) msgEl.textContent = 'Descargando y procesando lista…';
      try {
        const record = await fetchAndAddM3UList(form.elements.name.value, form.elements.url.value);
        closeDialog();
        render();
        showNotification({
          title: '¡Lista IPTV Agregada!',
          message: `Se importaron con éxito ${record.channels.length} canales en "${record.name}". Ya están listos para ver en directo.`,
          type: 'playlist-added',
          icon: '📋',
          badge: `${record.channels.length} CANALES`,
          actionText: '▶ Ver Canales',
          onAction: () => {
            state.listFilter = record.id;
            state.countryFilter = 'Todos';
            state.categoryFilter = 'Todas';
            state.channelPageLimit = 60;
            navigate('live');
          },
          duration: 7500
        });
      } catch (err) {
        if (msgEl) msgEl.textContent = err.message;
      }
      return;
    }

    if (form.id === 'add-xtream-modal-form' || form.id === 'xtream-form') {
      const msgEl = form.id === 'add-xtream-modal-form' ? $('#add-xtream-message') : null;
      if (msgEl) msgEl.textContent = 'Conectando con Xtream Codes…';
      else toast('Conectando con Xtream Codes…');
      try {
        const record = await fetchAndAddXtreamList({
          name: form.elements.name?.value,
          server: form.elements.server.value,
          username: form.elements.username.value,
          password: form.elements.password.value,
          section: form.elements.section.value
        });
        form.elements.password.value = '';
        if (form.id === 'add-xtream-modal-form') closeDialog();
        render();
        showNotification({
          title: '¡Proveedor Xtream Conectado!',
          message: `Se sincronizaron ${record.channels.length} transmisiones en "${record.name}". Listas para disfrutar en Live TV.`,
          type: 'playlist-added',
          icon: 'ϟ',
          badge: `${record.channels.length} CANALES`,
          actionText: '▶ Ver Canales',
          onAction: () => {
            state.listFilter = record.id;
            state.countryFilter = 'Todos';
            state.categoryFilter = 'Todas';
            state.channelPageLimit = 60;
            navigate('live');
          },
          duration: 7500
        });
      } catch (err) {
        if (msgEl) msgEl.textContent = err.message;
        else toast(err.message);
      }
      return;
    }

    if (form.id === 'admin-create-form') {
      if (!canAdmin()) throw new Error('Se necesita una cuenta de administrador conectada.');
      const record = Object.fromEntries(new FormData(form));
      await api('/admin/users', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(record) });
      form.reset(); await showAdminUsers(); toast('Usuario creado.');
    } else if (form.id === 'profile-name-form') {
      const name = form.elements.display_name.value.trim(); if (!name) return;
      state.user = await api('/users/profile', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ display_name: name }) });
      try {
        localStorage.setItem('vault_session', JSON.stringify({ server: state.server, token: state.token, user: state.user }));
      } catch (_) {}
      closeDialog(); render(); toast('Nombre actualizado.');
    } else if (form.id === 'notice-form') {
      const content = form.elements.content.value.trim(); if (!content) return;
      await api('/notifications/?' + new URLSearchParams({ subject: 'Novedades de Vault', content }), { method: 'POST' });
      await sync();
      toast('Aviso enviado.'); navigate('home');
    }
  } catch (error) {
    toast(error.message);
  } finally {
    if (button) button.disabled = false;
  }
});

$('#detail-dialog').addEventListener('cancel', event => { event.preventDefault(); closeDialog(); });

document.addEventListener('keydown', event => {
  if (state.device !== 'tv' || !['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Escape'].includes(event.key)) return;
  if (event.key === 'Escape') { if ($('#detail-dialog').open) closeDialog(); else if (!$('#vault-view').hidden) navigate('home'); return; }
  if (document.activeElement?.tagName === 'SELECT') return;
  if (['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName) && ['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
  const scope = $('#detail-dialog').open ? $('#detail-dialog') : $('#app-screen');
  const controls = [...scope.querySelectorAll('button,a,input,select')].filter(el => !el.disabled && el.getClientRects().length);
  const active = document.activeElement;
  if (!controls.includes(active)) { event.preventDefault(); controls[0]?.focus(); return; }
  const rect = active.getBoundingClientRect(); const x = rect.x + rect.width / 2; const y = rect.y + rect.height / 2;
  const horizontal = ['ArrowLeft', 'ArrowRight'].includes(event.key); const positive = ['ArrowRight', 'ArrowDown'].includes(event.key);
  const candidates = controls.filter(el => el !== active).map(el => { const r = el.getBoundingClientRect(); const dx = r.x + r.width / 2 - x; const dy = r.y + r.height / 2 - y; const forward = horizontal ? dx : dy; return { el, forward, score: Math.abs(forward) + Math.abs(horizontal ? dy : dx) * 3 }; }).filter(c => positive ? c.forward > 8 : c.forward < -8).sort((a, b) => a.score - b.score);
  if (candidates[0]) { event.preventDefault(); candidates[0].el.focus(); candidates[0].el.scrollIntoView({ block: 'nearest', inline: 'nearest' }); }
});

setInterval(async () => {
  if (document.hidden || !state.token || syncing) return;
  await sync();
  if (!state.token || $('#vault-view').hidden || $('#detail-dialog').open || ['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement?.tagName)) return;
  const content = $('#app-content'); const scroll = content.scrollTop;
  if (content.contains(document.activeElement)) return;
  render(); content.scrollTop = scroll;
}, 30000);

function canAdmin() { return state.online && state.user?.admin_status === true; }
async function showAdminUsers() {
  if (!canAdmin()) return;
  const token = state.token;
  const users = await api('/admin/users');
  if (!canAdmin() || state.token !== token) return;
  dialog(`<span class="eyebrow">ADMINISTRACIÓN</span><h2>Usuarios y acceso</h2><p class="muted">${users.length} cuentas · ${users.filter(u => u.account_status === 'active').length} activas</p><label>Buscar usuario<input id="admin-search" type="search" placeholder="Nombre de usuario"></label><div class="admin-users">${users.map(user => `<article class="admin-user" data-username="${escapeHTML(user.custom_username.toLocaleLowerCase('es'))}"><h3>${escapeHTML(user.custom_username)}</h3><p class="muted">${escapeHTML(user.profile_type)} · ${escapeHTML(user.account_status)}${user.admin_status ? ' · Administrador' : ''}</p>${!user.admin_status ? `<div class="settings-actions"><button data-user-action="${user.account_status === 'suspended' ? 'activate' : 'suspend'}" data-user-id="${user.id}">${user.account_status === 'suspended' ? 'Activar' : 'Suspender'}</button><button data-user-action="${user.profile_type === 'kids' ? 'standard' : 'kids'}" data-user-id="${user.id}">${user.profile_type === 'kids' ? 'Perfil normal' : 'Perfil infantil'}</button><button data-user-action="revoke-sessions" data-user-id="${user.id}">Cerrar sesiones</button></div>` : ''}</article>`).join('')}</div><h3>Crear usuario</h3><form id="admin-create-form"><label>Usuario<input name="custom_username" maxlength="80" required autocomplete="off"></label><label>Contraseña<input name="password" type="password" required autocomplete="new-password"></label><label>Perfil<select name="profile_type"><option value="standard">Normal</option><option value="kids">Infantil</option></select></label><button class="primary-button">Crear cuenta</button></form>`);
}
async function handleAdmin(button) {
  if (!canAdmin() || button.disabled) return;
  button.disabled = true;
  try {
    if (button.dataset.admin === 'users') return await showAdminUsers();
    if (button.dataset.admin === 'sync') {
      await api('/iptv/refresh', { method: 'POST' }); await sync();
      return toast('Fuentes IPTV actualizadas.');
    }
    const action = button.dataset.userAction, id = Number(button.dataset.userId);
    if (action === 'revoke-sessions' && !confirm('¿Cerrar sus sesiones? Tendrá que iniciar sesión cuando se conecte. El acceso offline no se puede revocar a distancia.')) return;
    const profile = ['kids', 'standard'].includes(action);
    await api(`/admin/users/${id}/${profile ? 'profile-type' : action}`, { method: action === 'revoke-sessions' ? 'POST' : 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(profile ? { profile_type: action } : {}) });
    await showAdminUsers(); toast('Cambios guardados.');
  } catch (error) { toast(error.message); }
  finally { button.disabled = false; }
}

document.addEventListener('input', event => {
  if (event.target.id !== 'admin-search') return;
  const query = event.target.value.trim().toLocaleLowerCase('es');
  document.querySelectorAll('.admin-user').forEach(user => user.hidden = !user.dataset.username.includes(query));
});

document.addEventListener('keydown', event => {
  if (state.tab === 'player' || $('#detail-dialog.video-dialog')?.open) {
    const video = $('#vault-video-player');
    if (event.key === 'Escape') {
      event.preventDefault();
      if (state.tab === 'player') {
        cleanupPlayer();
        return navigate(state.previousTab || 'live');
      }
      return closeDialog();
    }
    if (['f', 'F'].includes(event.key)) {
      ($('#player-fullscreen-toggle') || $('#player-fullscreen'))?.click();
      return;
    }
    if (['ArrowDown', 'PageDown'].includes(event.key)) {
      event.preventDefault();
      $('#player-zap-next')?.click();
      return;
    }
    if (['ArrowUp', 'PageUp'].includes(event.key)) {
      event.preventDefault();
      $('#player-zap-prev')?.click();
      return;
    }
    if ([' ', 'Spacebar'].includes(event.key) && event.target.tagName !== 'INPUT') {
      event.preventDefault();
      if (video) { video.paused ? video.play() : video.pause(); }
      return;
    }
    if (['m', 'M'].includes(event.key) && event.target.tagName !== 'INPUT') {
      event.preventDefault();
      $('#player-mute-toggle')?.click();
      return;
    }
    if (['r', 'R'].includes(event.key) && event.target.tagName !== 'INPUT') {
      event.preventDefault();
      $('#player-reconnect-btn')?.click();
      return;
    }
    if (['p', 'P'].includes(event.key) && event.target.tagName !== 'INPUT') {
      event.preventDefault();
      $('#player-pip-toggle')?.click();
      return;
    }
    if (['a', 'A'].includes(event.key) && event.target.tagName !== 'INPUT') {
      event.preventDefault();
      $('#player-aspect-toggle')?.click();
      return;
    }
    return;
  }
  if (event.key === 'Escape' && $('#detail-dialog')?.open) {
    event.preventDefault();
    return closeDialog();
  }
  if (state.device === 'tv') {
    const focusable = [...document.querySelectorAll('#vault-view button, #vault-view input, #vault-view [tabindex]:not([tabindex="-1"])')].filter(el => !el.hidden && el.offsetParent !== null);
    if (!focusable.length) return;
    const currentIndex = focusable.indexOf(document.activeElement);
    if (['ArrowDown', 'ArrowRight'].includes(event.key) && currentIndex < focusable.length - 1) {
      event.preventDefault();
      focusable[currentIndex + 1].focus();
    } else if (['ArrowUp', 'ArrowLeft'].includes(event.key) && currentIndex > 0) {
      event.preventDefault();
      focusable[currentIndex - 1].focus();
    }
  }
});

// Inicializar listas de usuario, detectar servidor opcional y abrir la app directamente
window.addEventListener('DOMContentLoaded', async () => {
  const splashStartTime = Date.now();

  const platformMeta = document.querySelector('meta[name="app-platform"]')?.content;
  const isNative = Boolean(
    platformMeta ||
    window.Capacitor ||
    location.protocol === 'capacitor:' ||
    /Android.*wv|Version\/.*Chrome/i.test(navigator.userAgent)
  );
  if (isNative) {
    document.body.classList.add('native-app');
    if (platformMeta === 'tv' || navigator.userAgent.includes('TV') || navigator.userAgent.includes('SmartTV')) {
      setDevice('tv');
    } else {
      setDevice('phone');
    }
  }

  if (window.Capacitor?.Plugins?.App?.addListener) {
    try {
      window.Capacitor.Plugins.App.addListener('backButton', () => {
        if ($('#detail-dialog')?.open) {
          closeDialog();
          return;
        }
        if (state.tab === 'player') {
          cleanupPlayer();
          navigate(state.previousTab || 'live');
          return;
        }
        if (state.tab !== 'home') {
          navigate('home');
          return;
        }
        window.Capacitor?.Plugins?.App?.exitApp?.();
      });
    } catch (_) {}
  }

  loadUserLists();
  loadChannelPreferences();
  loadLibraryPreferences();
  try {
    state.noAds = localStorage.getItem('vault_no_ads') === 'true';
  } catch (_) {}

  await autoDetectServer();

  try {
    const raw = localStorage.getItem('vault_session');
    if (raw) {
      const saved = JSON.parse(raw);
      if (saved && saved.server && saved.token) {
        state.server = saved.server;
        state.token = saved.token;
        state.user = saved.user;
        loadChannelPreferences();
        loadLibraryPreferences();
      }
    }
  } catch (_) {}

  state.tab = 'home';
  showApp();

  if (state.token) {
    sync().catch(() => {});
  }
  checkForOTAUpdates();

  const elapsed = Date.now() - splashStartTime;
  const remaining = Math.max(0, 700 - elapsed);
  setTimeout(() => {
    dismissSplash();
  }, remaining);
});

document.addEventListener('input', event => {
  if (event.target.id === 'web-chapter-filter-input') {
    const q = event.target.value.trim().toLowerCase();
    const container = $('#web-episodes-scroll-container');
    const eps = window._activeWebEpisodes || [];
    if (!container || !eps.length) return;
    const filtered = eps.filter((ep, idx) => {
      if (!q) return true;
      return String(idx + 1).includes(q) || ep.title.toLowerCase().includes(q);
    });
    container.innerHTML = filtered.map((ep, idx) => `
      <div class="web-episode-card" data-play-web-ep="${encodeURIComponent(JSON.stringify(ep))}">
        <div class="web-ep-badge">${idx + 1}</div>
        <div class="web-ep-text">
          <strong>${escapeHTML(ep.title)}</strong>
          <small>${escapeHTML(ep.url)}</small>
        </div>
        <button type="button" class="primary-button compact">▶ Reproducir</button>
      </div>
    `).join('') || '<p class="muted" style="text-align:center;padding:12px">No se encontraron capítulos coincidentes.</p>';
  }
});
