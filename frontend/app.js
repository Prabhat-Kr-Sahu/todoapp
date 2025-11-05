const API_BASE = 'http://localhost:5000';

const $ = sel => document.querySelector(sel);
const authMsg = $('#authMsg');
const serverStatus = $('#serverStatus');

function setServerStatus(text) {
    if (serverStatus) serverStatus.textContent = text;
}

async function api(path, opts = {}) {
    const headers = opts.headers || {};
    const token = localStorage.getItem('token');
    if (token) { headers['Authorization'] = token; }
    headers['Content-Type'] = 'application/json';
    const res = await fetch(API_BASE + path, { ...opts, headers });
    if (res.status === 401 || res.status === 422) {
        authMsg.textContent = 'Not authorized — please login';
    }
    return res;
}

async function checkServer() {
    try {
        const res = await fetch(API_BASE + '/');
        if (res.ok) setServerStatus('up'); else setServerStatus('down');
    } catch (e) { setServerStatus('down'); }
}

async function register() {
    const u = $('#username').value.trim();
    const p = $('#password').value;
    if (!u || !p) { authMsg.textContent = 'username & password required'; return; }
    const res = await api('/register', { method: 'POST', body: JSON.stringify({ username: u, password: p }) });
    if (res.ok) { authMsg.textContent = 'Registered — now login'; }
    else { const j = await res.json().catch(() => ({})); authMsg.textContent = j.message || 'Register failed'; }
}

async function login() {
    const u = $('#username').value.trim();
    const p = $('#password').value;
    if (!u || !p) { authMsg.textContent = 'username & password required'; return; }
    const res = await api('/login', { method: 'POST', body: JSON.stringify({ username: u, password: p }) });
    const j = await res.json().catch(() => null);
    if (res.ok && j && j.access_token) {
        localStorage.setItem('token', 'Bearer ' + j.access_token);
        authMsg.textContent = 'Logged in';
        await loadTodos();
    } else {
        authMsg.textContent = j && j.msg ? j.msg : (j && j.message) || 'Login failed';
    }
}

async function loadTodos() {
    const res = await api('/api/todos');
    if (!res.ok) { $('.todo-list').innerHTML = '<div class="muted">Unable to load todos</div>'; return; }
    const todos = await res.json();
    renderTodos(todos);
    updateProgress(todos);
}

function renderTodos(todos) {
    const list = $('#todoList');
    if (!todos || todos.length === 0) { list.innerHTML = '<div class="muted">No todos yet</div>'; return; }
    list.innerHTML = todos.map(t => `
		<div class="todo" data-id="${t.id}">
			<div class="left">
				<input type="checkbox" class="chk" ${t.completed ? 'checked' : ''} />
				<div class="title">${escapeHtml(t.title)}</div>
			</div>
			<div class="controls">
				<button class="del">🗑</button>
			</div>
		</div>
	`).join('');

    document.querySelectorAll('.todo').forEach(node => {
        node.querySelector('.del').addEventListener('click', () => deleteTodo(node.dataset.id));
        node.querySelector('.chk').addEventListener('change', (e) => toggleTodo(node.dataset.id, e.target.checked));
    });
}

function updateProgress(todos) {
    const total = todos ? todos.length : 0;
    const open = todos ? todos.filter(t => !t.completed).length : 0;
    const done = total - open;
    const pct = total === 0 ? 0 : Math.round((done / total) * 100);
    const numEl = document.querySelector('.progress-number');
    const openEl = document.getElementById('openCount');
    if (numEl) numEl.textContent = pct + '%';
    if (openEl) openEl.textContent = open;
}

function escapeHtml(s) { return (s + '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": "&#39;" }[c])); }

async function addTodo() {
    const text = $('#newTodo').value.trim();
    if (!text) return;
    const res = await api('/api/todos', { method: 'POST', body: JSON.stringify({ title: text }) });
    if (res.ok) { $('#newTodo').value = ''; await loadTodos(); }
    else { const j = await res.json().catch(() => ({})); authMsg.textContent = j.error || 'Could not add todo'; }
}

async function deleteTodo(id) {
    const res = await api('/api/todos/' + id, { method: 'DELETE' });
    if (res.ok) loadTodos();
}

async function toggleTodo(id, completed) {
    await api('/api/todos/' + id, { method: 'PUT', body: JSON.stringify({ completed }) });
    loadTodos();
}

// wire up UI
document.addEventListener('DOMContentLoaded', () => {
    checkServer();
    setInterval(checkServer, 5000);
    $('#loginBtn').addEventListener('click', login);
    $('#registerBtn').addEventListener('click', register);
    $('#addBtn').addEventListener('click', addTodo);
    loadTodos();
});

