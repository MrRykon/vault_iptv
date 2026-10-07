'use strict';
const $ = (selector) => document.querySelector(selector);
const escapeHTML = (value) => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const movies = [
  {title:'Más allá del horizonte', type:'movie', genre:'Ciencia ficción', year:'2026', color:'linear-gradient(155deg,#62638e,#32334a 45%,#171821)', mock:true},
  {title:'La última luz', type:'movie', genre:'Drama', year:'2026', color:'linear-gradient(145deg,#a9754b,#4f332a 50%,#19121a)', mock:true},
  {title:'Ecos del bosque', type:'show', genre:'Misterio · Serie', year:'2025', color:'linear-gradient(155deg,#5b7b69,#244b42 50%,#101c20)', mock:true},
  {title:'Ciudad nocturna', type:'movie', genre:'Suspenso', year:'2026', color:'linear-gradient(155deg,#805984,#35243d 50%,#161120)', mock:true},
  {title:'Bajo el azul', type:'show', genre:'Aventura · Serie', year:'2025', color:'linear-gradient(155deg,#5c8ea6,#284557 50%,#0e1d2c)', mock:true}
];
const demoChannels = [
  {channel_name:'Vault Cinema', category:'Películas', initials:'VC'},
  {channel_name:'Mundo Documental', category:'Documentales', initials:'MD'},
  {channel_name:'Arena Sports', category:'Deportes', initials:'AS'},
  {channel_name:'Pequeños mundos', category:'Infantil', initials:'PM'},
  {channel_name:'Music Sessions', category:'Música', initials:'MS'},
  {channel_name:'Noticias 24', category:'Noticias', initials:'N24'}
];
const state = {demo:true, device:'web', tab:'home', filter:'Todos', online:true, server:'', token:'', user:null, channels:demoChannels, library:movies, notes:[], xtream:[], previewNotice:'', favorites:new Set(), recent:[], channelView:'Todos', query:'', alphabetical:false, channelEtag:''};
let toastTimer;
let syncing = false;
function channelId(channel) { return String(channel.channel_id || channel.channel_name); }
function preferenceKey() { return 'vault_channels_' + JSON.stringify(state.demo ? ['demo'] : [state.server,state.user?.custom_username]); }
function loadChannelPreferences() {
  state.favorites = new Set(); state.recent = []; state.channelView = 'Todos'; state.query = ''; state.channelEtag = '';
  try {
    const saved = JSON.parse(localStorage.getItem(preferenceKey()) || '{}');
    if (Array.isArray(saved.favorites)) state.favorites = new Set(saved.favorites.filter(id => typeof id === 'string'));
    if (Array.isArray(saved.recent)) state.recent = saved.recent.filter(id => typeof id === 'string').slice(0,20);
  } catch { /* Private browsing or malformed preferences must not block the app. */ }
}
function saveChannelPreferences() {
  try { localStorage.setItem(preferenceKey(),JSON.stringify({favorites:[...state.favorites],recent:state.recent})); }
  catch { toast('No se pudieron guardar las preferencias en este navegador.'); }
}
function markRecent(channel) {
  const id = channelId(channel); state.recent = [id,...state.recent.filter(value => value !== id)].slice(0,20); saveChannelPreferences();
}
function toast(message) { $('#toast').textContent = message; $('#toast').hidden = false; clearTimeout(toastTimer); toastTimer = setTimeout(() => $('#toast').hidden = true, 4500); }
function safeURL(value) { try { const url = new URL(value); return ['http:','https:'].includes(url.protocol) && !url.username && !url.password ? url.href : ''; } catch { return ''; } }
function serverURL(value) {
  const url = new URL(value);
  if (!safeURL(value) || url.search || url.hash || !['','/'].includes(url.pathname)) throw new Error('Usa la dirección del servidor sin rutas: https://host:puerto');
  if (location.protocol === 'https:' && url.protocol !== 'https:') throw new Error('Esta web HTTPS necesita un servidor HTTPS. Para una red local abre la vista desde tu servidor Vault.');
  return url.origin;
}
async function api(path, options = {}) {
  const server = state.server, token = state.token;
  const response = await fetch(server + path, {...options, signal:AbortSignal.timeout(12000), headers:{...(token ? {Authorization:`Bearer ${token}`} : {}), ...options.headers}});
  if (server !== state.server || token !== state.token) throw new Error('La sesión cambió mientras se cargaba el contenido.');
  if (path === '/iptv/channels' && response.status === 304) return state.channels;
  if (!response.ok) {
    if (state.token && [401,403].includes(response.status) && !path.startsWith('/xtream/')) {
      state.token = ''; state.user = null; showLogin();
      throw new Error('Tu sesión no está activa. Vuelve a iniciar sesión.');
    }
    const error = await response.json().catch(() => ({}));
    throw new Error(typeof error.detail === 'string' ? error.detail : `No se pudo completar la solicitud (${response.status}).`);
  }
  if (path === '/iptv/channels') state.channelEtag = response.headers.get('etag') || '';
  return response.json();
}
function showLogin() { $('#login-view').hidden = false; $('#vault-view').hidden = true; $('#screen-toggle').textContent = 'Ver inicio'; }
function showApp() { $('#login-view').hidden = true; $('#vault-view').hidden = false; $('#screen-toggle').textContent = 'Ver login'; render(); }
function enterDemo() {
  state.demo = true; state.token = ''; state.user = null; state.online = true; state.channels = demoChannels; state.library = movies; state.notes = []; state.xtream = []; state.tab = 'home'; state.filter = 'Todos'; loadChannelPreferences(); showApp();
}
function setDevice(device) {
  state.device = device; $('#device-frame').dataset.device = device;
  document.querySelectorAll('[data-device]').forEach(button => { if (button.tagName === 'BUTTON') button.setAttribute('aria-pressed', String(button.dataset.device === device)); });
  $('#device-caption').textContent = {web:'Vista web adaptable', phone:'Teléfono Android · 390 px', tv:'Chromecast con Google TV · formato 16:9'}[device];
  $('#preview-help').textContent = device === 'tv' ? 'Usa las flechas del teclado y Enter como un mando. En pantallas pequeñas, desplaza el marco horizontalmente. Esta vista no transmite a un Chromecast.' : 'Cambia de formato para explorar el diseño. El contenido de demostración es ilustrativo.';
}
function connection() {
  $('#connection').className = `connection ${state.online ? (state.demo ? '' : 'online') : 'offline'}`;
  $('#connection').innerHTML = `<i></i>${state.demo ? (state.online ? 'Demostración' : 'Sin servidor · Demo') : (state.online ? 'Servidor conectado' : 'Servidor desconectado')}`;
}
function card(item, index) {
  const fallback = movies[index % movies.length];
  return `<button class="movie-card" data-movie="${index}" aria-label="Ver ${escapeHTML(item.title)}"><div class="poster" style="--poster:${fallback.color}">${item.mock || state.demo ? '<span class="badge">PRÓXIMAMENTE</span>' : ''}<span class="poster-title">${escapeHTML(item.title)}</span></div><h3>${escapeHTML(item.title)}</h3><p>${escapeHTML(item.genre || (item.type === 'show' ? 'Serie' : 'Película'))} · ${escapeHTML(item.year || 'Plex')}</p></button>`;
}
function home() {
  const note = state.previewNotice || (state.demo ? 'Bienvenido a tu nuevo espacio de entretenimiento.' : state.notes[0]?.content || 'Tu biblioteca se actualiza cuando el servidor está conectado.');
  const hero = state.library[0] || movies[0];
  return `<div class="notice"><span aria-hidden="true">✧</span><div><strong>${escapeHTML(state.demo ? 'Novedades de Vault' : state.notes[0]?.subject || 'Vault')}</strong><br>${escapeHTML(note)}</div><span class="tag">${state.demo ? 'DEMO' : 'AVISOS'}</span></div>
  <section class="hero"><div class="hero-moon"></div><div class="hero-landscape"></div><div class="hero-copy"><span class="eyebrow">${state.demo || hero.mock ? 'TU PRÓXIMA HISTORIA · PRÓXIMAMENTE' : 'EN TU BIBLIOTECA PLEX'}</span><h2>${escapeHTML(hero.title)}</h2><p>${state.demo || hero.mock ? 'Hay historias que nos llevan más lejos. Descubre lo que te espera en tu biblioteca.' : 'Películas y series de tu servidor, reunidas en tu espacio.'}</p><div class="hero-buttons"><button data-movie="0">▷ Ver detalles</button><button data-nav="live">▣ Ir a Live TV</button></div></div></section>
  <div class="section-heading"><h2>Tu biblioteca</h2><small>${state.demo ? 'Plex · contenido ilustrativo' : `${state.library.length} títulos · Plex`}</small></div><div class="cards">${state.library.map(card).join('') || '<p class="empty-state">No hay contenido disponible en Plex.</p>'}</div>`;
}
function live() {
  const categories = ['Todos', ...new Set(state.channels.map(c => c.category || 'General'))];
  let visible = state.channels.map((channel,index) => ({channel,index})).filter(({channel:c}) =>
    (state.filter === 'Todos' || (c.category || 'General') === state.filter) &&
    (state.channelView !== 'Favoritos' || state.favorites.has(channelId(c))) &&
    (state.channelView !== 'Recientes' || state.recent.includes(channelId(c))));
  if (state.channelView === 'Recientes') visible.sort((a,b) => state.recent.indexOf(channelId(a.channel)) - state.recent.indexOf(channelId(b.channel)));
  else if (state.alphabetical) visible.sort((a,b) => a.channel.channel_name.localeCompare(b.channel.channel_name,'es'));
  return `<span class="eyebrow">TU TELEVISIÓN, A TU RITMO</span><h1 class="page-title">Live TV</h1><p class="page-subtitle">${state.demo ? 'Canales ilustrativos para explorar la interfaz.' : 'Catálogo IPTV de tu servidor Vault.'} ${!state.online ? 'Puedes intentar reproducir las fuentes cargadas mientras tengan Internet.' : ''}</p><label>Buscar canal<input id="channel-search" type="search" value="${escapeHTML(state.query)}" placeholder="Nombre del canal" autocomplete="off"></label>
  <div class="filters">${['Todos','Favoritos','Recientes'].map(view => `<button data-channel-view="${view}" class="filter ${view === state.channelView ? 'active' : ''}">${view}</button>`).join('')}<button id="sort-channels" class="filter ${state.alphabetical ? 'active' : ''}" aria-pressed="${state.alphabetical}">Ordenar A–Z</button></div>
  <div class="filters">${categories.map(category => `<button data-filter="${escapeHTML(category)}" class="filter ${category === state.filter ? 'active' : ''}">${escapeHTML(category)}</button>`).join('')}</div>
  <div class="channels">${visible.map(({channel:c,index}) => `<div class="channel" ${!`${c.channel_name} ${c.category || 'General'}`.toLocaleLowerCase('es').includes(state.query.toLocaleLowerCase('es')) ? 'hidden' : ''}><button class="channel-main" data-channel="${index}"><span class="channel-logo">${escapeHTML(c.initials || c.channel_name.slice(0,2).toUpperCase())}</span><span><strong>${escapeHTML(c.channel_name)}</strong><small>${escapeHTML(c.category || 'General')}</small></span></button><button class="favorite-button ${state.favorites.has(channelId(c)) ? 'saved' : ''}" data-star="${index}" aria-label="${state.favorites.has(channelId(c)) ? 'Quitar de favoritos' : 'Agregar a favoritos'}: ${escapeHTML(c.channel_name)}" aria-pressed="${state.favorites.has(channelId(c))}">${state.favorites.has(channelId(c)) ? '★' : '☆'}</button></div>`).join('') || '<p class="empty-state">No hay canales con estos filtros. Marca estrellas para crear tus favoritos; abre un canal para verlo en recientes.</p>'}</div>`;
}
function xtream() {
  if (!state.online) return '<h1 class="page-title">Xtream Codes</h1><div class="empty-state">Conecta el servidor Vault para usar Xtream Codes.</div>';
  return `<span class="eyebrow">UN ESPACIO PARA TU PROVEEDOR</span><h1 class="page-title">Xtream Codes</h1><p class="page-subtitle">Conecta tu TV, películas y series en una sección independiente.</p><div class="settings-card"><h2>Tu conexión Xtream</h2><p class="muted">${state.demo ? 'Vista de diseño. No escribas credenciales reales en la demostración.' : 'Las credenciales se envían a tu servidor Vault y no se guardan en esta web.'}</p><form id="xtream-form"><label>URL del proveedor<input name="server" type="url" placeholder="https://proveedor.com:puerto" required ${state.demo ? 'disabled' : ''}></label><label>Usuario<input name="username" autocomplete="off" required placeholder="Usuario del proveedor" ${state.demo ? 'disabled' : ''}></label><label>Contraseña<input name="password" type="password" autocomplete="off" required placeholder="Contraseña del proveedor" ${state.demo ? 'disabled' : ''}></label><label>Contenido<select name="section"><option value="live">Televisión en vivo</option><option value="vod">Películas</option><option value="series">Series</option></select></label><button class="primary-button" ${state.demo ? 'type="button" data-toast="Conecta un servidor Vault desde el login para usar Xtream."' : 'type="submit"'}>Conectar proveedor <span>→</span></button></form></div><div class="channels">${state.xtream.map((item,index) => `<button class="channel" data-xtream="${index}"><span class="channel-logo">ϟ</span><div><h3>${escapeHTML(item.title)}</h3><small>${escapeHTML(item.type)}</small></div></button>`).join('')}</div>`;
}
function profile() {
  const name = state.demo ? 'Explorador Vault' : state.user?.display_name || state.user?.custom_username || 'Usuario';
  const admin = state.demo || state.user?.admin_status;
  return `<div class="profile-summary"><div class="profile-avatar">${escapeHTML(name.slice(0,1).toUpperCase())}</div><h1 class="page-title">${escapeHTML(name)}</h1><p class="page-subtitle">${state.demo ? 'Perfil de demostración' : state.user?.admin_status ? 'Administrador' : 'Tu espacio personal'}</p></div><div class="settings-card"><h2>Tu Vault</h2><div class="settings-row"><span>Servidor</span><small>${state.demo ? 'Simulado' : state.online ? 'Conectado' : 'Desconectado'}</small></div><div class="settings-row"><span>Versión de la app</span><small>0.2.0 · Vista HTML</small></div><div class="settings-row"><span>Formato de pantalla</span><small>${escapeHTML({web:'Web',phone:'Android',tv:'Chromecast / TV'}[state.device])}</small></div><div class="settings-row"><span>Actualizaciones OTA</span><small>Disponibles en Android</small></div>${state.demo ? '<div class="demo-banner">Puedes simular una desconexión y probar los avisos de administrador. Los cambios se borran al recargar.</div><button class="secondary-button" id="simulate-server">'+(state.online ? 'Simular servidor desconectado' : 'Reconectar servidor simulado')+'</button>' : ''}<div class="settings-actions"><button id="about-button">Información</button><button id="logout">Cerrar sesión</button></div></div>${admin && state.online ? `<div class="settings-card"><h2>Notificaciones ${state.demo ? '· Demo' : '· Admin'}</h2><p class="muted">${state.demo ? 'Prueba cómo se verá un aviso en la pantalla principal.' : 'Envía un aviso a los usuarios de Vault.'}</p><form id="notice-form"><label>Mensaje<input name="content" maxlength="500" placeholder="Escribe un aviso para tus usuarios" required></label><button class="primary-button">${state.demo ? 'Previsualizar aviso' : 'Enviar aviso'}</button></form></div>` : ''}`;
}
function render() {
  connection();
  document.querySelectorAll('.bottom-nav [data-nav]').forEach(button => { if (button.dataset.nav === state.tab) button.setAttribute('aria-current','page'); else button.removeAttribute('aria-current'); });
  $('#app-content').innerHTML = ({home,live,xtream,profile}[state.tab] || home)();
}
function navigate(tab) { state.tab = tab; render(); $('#app-content').scrollTop = 0; if (state.device === 'tv') $('#app-content button, #app-content input')?.focus(); }
function dialog(html) { $('#dialog-content').innerHTML = html; $('#detail-dialog').showModal(); }
function closeDialog() { $('#detail-dialog video')?.pause(); $('#dialog-content').replaceChildren(); $('#detail-dialog').close(); }
function play(item) {
  if (!item?.stream_url || state.demo) return dialog(`<span class="eyebrow">VISTA DE DEMOSTRACIÓN</span><h2>${escapeHTML(item?.channel_name || item?.title || 'Vault')}</h2><p class="muted">Este contenido es ilustrativo. Conecta tu servidor y agrega tus fuentes IPTV o tu proveedor Xtream para reproducir contenido real.</p>`);
  const url = safeURL(item.stream_url);
  if (!url || (location.protocol === 'https:' && new URL(url).protocol !== 'https:')) return toast('La fuente debe usar una URL compatible. Una web HTTPS no puede reproducir una fuente HTTP.');
  dialog(`<span class="eyebrow">REPRODUCTOR WEB</span><h2>${escapeHTML(item.channel_name || item.title)}</h2><video controls autoplay playsinline></video><p class="muted" id="playback-message">La reproducción depende del formato, los permisos de la fuente y el navegador. Para HLS sin soporte nativo utiliza la app Android.</p>`);
  const video = $('#detail-dialog video'); video.src = url; video.addEventListener('error', () => { $('#playback-message').textContent = 'El navegador no pudo reproducir esta fuente. Comprueba su disponibilidad o utiliza la app Android.'; });
}
async function sync() {
  if (state.demo || !state.token || syncing) return;
  syncing = true;
  try {
    await api('/health'); state.online = true;
    state.user = await api('/auth/me');
    const results = await Promise.allSettled([api('/iptv/channels',{headers:state.channelEtag ? {'If-None-Match':state.channelEtag} : {}}),api('/plex/library'),api('/notifications/')]);
    if (!state.token) return;
    if (results[0].status === 'fulfilled') state.channels = results[0].value;
    if (results[1].status === 'fulfilled') state.library = results[1].value;
    if (results[2].status === 'fulfilled') state.notes = results[2].value;
    connection();
  } catch { if (state.token) { state.online = false; connection(); } }
  finally { syncing = false; }
}
$('#login-form').addEventListener('submit', async event => {
  event.preventDefault(); const form = event.currentTarget; const button = form.querySelector('button'); button.disabled = true; $('#login-message').textContent = 'Conectando…';
  state.demo = false; state.token = ''; state.channels = []; state.library = []; state.notes = []; state.previewNotice = ''; state.xtream = [];
  try {
    state.server = serverURL(form.elements.server.value.trim());
    const result = await api('/auth/login',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({username:form.elements.username.value,password:form.elements.password.value})});
    state.token = result.access_token; state.user = await api('/auth/me'); loadChannelPreferences(); form.elements.password.value = ''; state.online = true; state.tab = 'home'; state.filter = 'Todos'; await sync(); if (state.token) showApp(); $('#login-message').textContent = '';
  } catch (error) { state.token = ''; $('#login-message').textContent = error instanceof TypeError ? 'No se pudo conectar. Revisa la dirección, HTTPS y que el servidor esté encendido.' : error.message; }
  finally { button.disabled = false; }
});
document.addEventListener('click', async event => {
  const button = event.target.closest('button,a[data-nav]'); if (!button) return;
  if (button.dataset.device) return setDevice(button.dataset.device);
  if (button.dataset.nav) { event.preventDefault(); return navigate(button.dataset.nav); }
  if (button.dataset.toast) return toast(button.dataset.toast);
  if (button.dataset.channelView) { state.channelView = button.dataset.channelView; return render(); }
  if (button.id === 'sort-channels') { state.alphabetical = !state.alphabetical; return render(); }
  if (button.dataset.star !== undefined) {
    const id = channelId(state.channels[Number(button.dataset.star)]);
    if (!state.favorites.delete(id)) state.favorites.add(id);
    saveChannelPreferences(); render();
    document.querySelector(`[data-star="${button.dataset.star}"]`)?.focus(); return;
  }
  if (button.dataset.filter) { state.filter = button.dataset.filter; return render(); }
  if (button.dataset.channel !== undefined) { const channel = state.channels[Number(button.dataset.channel)]; markRecent(channel); return play(channel); }
  if (button.dataset.xtream !== undefined) {
    const item = state.xtream[Number(button.dataset.xtream)];
    if (item.type === 'series') return toast('Para navegar los episodios utiliza la app Vault.');
    return play(item);
  }
  if (button.dataset.movie !== undefined) {
    const item = state.library[Number(button.dataset.movie)] || movies[0];
    return dialog(`<span class="eyebrow">${state.demo || item.mock ? 'PLEX · PRÓXIMAMENTE' : 'TU BIBLIOTECA PLEX'}</span><h2>${escapeHTML(item.title)}</h2><p class="muted">${state.demo || item.mock ? 'Aquí aparecerán las películas y series de tu servidor Plex. Este título es una muestra visual y no tiene reproducción.' : 'Título disponible en tu biblioteca. Para reproducir Plex con autenticación y navegar temporadas, utiliza el cliente Vault de Android.'}</p>`);
  }
  switch (button.id) {
    case 'demo-login': return enterDemo();
    case 'screen-toggle': return $('#vault-view').hidden ? (state.token ? showApp() : enterDemo()) : showLogin();
    case 'close-dialog': return closeDialog();
    case 'simulate-server': state.online = !state.online; return render();
    case 'about-button': return dialog('<span class="eyebrow">TU ESPACIO DE ENTRETENIMIENTO</span><h2>Vault</h2><p class="muted">IPTV, Plex y Xtream en una sola app. Esta vista HTML te permite explorar su diseño en web, teléfono Android y Chromecast con Google TV. El marco TV simula la interfaz; no es una función de casting.</p><p class="muted">Las actualizaciones OTA y el acceso offline con contraseña están implementados en el cliente Android. Esta web no almacena contraseñas ni sesiones al cerrarse.</p>');
    case 'logout':
      if (!state.demo && state.token) await api('/auth/logout',{method:'POST'}).catch(() => {});
      state.token = ''; state.user = null; state.channels = []; state.library = []; state.xtream = []; state.notes = []; showLogin(); return;
  }
});
document.addEventListener('input', event => {
  if (event.target.id !== 'channel-search') return;
  state.query = event.target.value;
  const query = state.query.toLocaleLowerCase('es');
  document.querySelectorAll('.channel').forEach(channel => channel.hidden = !channel.textContent.toLocaleLowerCase('es').includes(query));
});
document.addEventListener('submit', async event => {
  const form = event.target;
  if (!['xtream-form','notice-form'].includes(form.id)) return;
  event.preventDefault(); const button = form.querySelector('button'); button.disabled = true;
  try {
    if (form.id === 'notice-form') {
      const content = form.elements.content.value.trim(); if (!content) return;
      if (state.demo) state.previewNotice = content;
      else { await api('/notifications/?'+new URLSearchParams({subject:'Novedades de Vault',content}),{method:'POST'}); await sync(); }
      toast(state.demo ? 'Aviso de demostración actualizado.' : 'Aviso enviado.'); navigate('home');
    } else {
      if (state.demo || !state.online) return toast('Conecta tu servidor Vault para usar Xtream.');
      const result = await api('/xtream/catalog',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(Object.fromEntries(new FormData(form)))});
      form.elements.password.value = ''; state.xtream = result.items; render(); toast(`${result.items.length} elementos disponibles.`);
    }
  } catch (error) { toast(error.message); }
  finally { button.disabled = false; }
});
$('#detail-dialog').addEventListener('cancel', event => { event.preventDefault(); closeDialog(); });
document.addEventListener('keydown', event => {
  if (state.device !== 'tv' || !['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Escape'].includes(event.key)) return;
  if (event.key === 'Escape') { if ($('#detail-dialog').open) closeDialog(); else if (!$('#vault-view').hidden) navigate('home'); return; }
  if (document.activeElement?.tagName === 'SELECT') return;
  if (['INPUT','TEXTAREA'].includes(document.activeElement?.tagName) && ['ArrowLeft','ArrowRight'].includes(event.key)) return;
  const scope = $('#detail-dialog').open ? $('#detail-dialog') : $('#app-screen');
  const controls = [...scope.querySelectorAll('button,a,input,select')].filter(el => !el.disabled && el.getClientRects().length);
  const active = document.activeElement;
  if (!controls.includes(active)) { event.preventDefault(); controls[0]?.focus(); return; }
  const rect = active.getBoundingClientRect(); const x = rect.x + rect.width/2; const y = rect.y + rect.height/2;
  const horizontal = ['ArrowLeft','ArrowRight'].includes(event.key); const positive = ['ArrowRight','ArrowDown'].includes(event.key);
  const candidates = controls.filter(el => el !== active).map(el => { const r = el.getBoundingClientRect(); const dx = r.x+r.width/2-x; const dy = r.y+r.height/2-y; const forward = horizontal ? dx : dy; return {el,forward,score:Math.abs(forward)+Math.abs(horizontal?dy:dx)*3}; }).filter(c => positive ? c.forward > 8 : c.forward < -8).sort((a,b) => a.score-b.score);
  if (candidates[0]) { event.preventDefault(); candidates[0].el.focus(); candidates[0].el.scrollIntoView({block:'nearest',inline:'nearest'}); }
});
try { if (/^https?:$/.test(location.protocol) && location.pathname.startsWith('/preview')) $('#login-form').elements.server.value = location.origin; } catch { /* File preview also works. */ }
setInterval(async () => {
  if (document.hidden || state.demo || !state.token || syncing) return;
  await sync();
  if (!state.token || $('#vault-view').hidden || $('#detail-dialog').open || ['INPUT','TEXTAREA','SELECT'].includes(document.activeElement?.tagName)) return;
  const content = $('#app-content'); const scroll = content.scrollTop;
  // Keep editing uninterrupted; refreshed catalogues appear on the next navigation.
  if (content.contains(document.activeElement)) return;
  render(); content.scrollTop = scroll;
},30000);
