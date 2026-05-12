

const { WebSocketServer } = require("ws");

const PORT = 8080;
const wss = new WebSocketServer({ port: PORT });

let nextId = 1;
const clients = new Map();

function broadcast(msg, exceptId) {
  const data = JSON.stringify(msg);
  for (const [id, c] of clients) {
    if (id === exceptId) continue;
    if (c.ws.readyState === c.ws.OPEN) c.ws.send(data);
  }
}

wss.on("connection", (ws) => {
  const id = nextId++;
  const state = { unit_type: null, hp: 0, x: 0, y: 0 };
  clients.set(id, { ws, state });

  ws.send(JSON.stringify({ type: "welcome", id }));

  for (const [otherId, c] of clients) {
    if (otherId === id) continue;
    if (c.state.unit_type === null) continue;
    ws.send(JSON.stringify({
      type: "update",
      id: otherId,
      unit_type: c.state.unit_type,
      hp: c.state.hp,
      x: c.state.x,
      y: c.state.y,
    }));
  }

  broadcast({ type: "join", id }, id);

  ws.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    if (typeof msg !== "object" || msg === null) return;

    const c = clients.get(id);
    if (msg.unit_type !== undefined) c.state.unit_type = String(msg.unit_type);
    if (msg.hp        !== undefined) c.state.hp        = Number(msg.hp);
    if (msg.x         !== undefined) c.state.x         = Number(msg.x);
    if (msg.y         !== undefined) c.state.y         = Number(msg.y);

    broadcast({
      type: "update",
      id,
      unit_type: c.state.unit_type,
      hp: c.state.hp,
      x: c.state.x,
      y: c.state.y,
    }, id);
  });

  ws.on("close", () => {
    clients.delete(id);
    broadcast({ type: "leave", id });
  });
});

console.log(`WebSocket server listening on ws://0.0.0.0:${PORT}`);
