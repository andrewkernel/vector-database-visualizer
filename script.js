const DIMENSIONS = 300;

const semanticTags = {
  animal: ["dog", "cat", "tiger", "lion", "wolf", "fox", "bear", "horse", "zebra", "leopard", "cheetah", "pet", "animal"],
  mammal: ["dog", "cat", "tiger", "lion", "wolf", "fox", "bear", "horse", "zebra", "leopard", "cheetah"],
  feline: ["cat", "tiger", "lion", "leopard", "cheetah"],
  canine: ["dog", "wolf", "fox"],
  pet: ["dog", "cat", "hamster", "rabbit", "parrot"],
  wild: ["tiger", "lion", "wolf", "fox", "bear", "zebra", "leopard", "cheetah"],
  fruit: ["apple", "banana", "pear", "orange", "grape", "peach", "mango", "fruit"],
  food: ["apple", "banana", "pear", "orange", "pizza", "bread", "rice", "food", "coffee"],
  vehicle: ["car", "truck", "boat", "ship", "plane", "train", "bus", "bike", "vehicle"],
  watercraft: ["boat", "ship", "sailboat", "canoe"],
  sport: ["football", "soccer", "tennis", "basketball", "baseball", "hockey", "sport"],
  tech: ["database", "server", "computer", "ai", "model", "vector", "code", "software"],
  nature: ["tree", "forest", "river", "mountain", "ocean", "flower", "plant"],
  color: ["red", "green", "blue", "yellow", "purple", "black", "white"]
};

const conceptInput = document.getElementById("conceptInput");
const visualizeButton = document.getElementById("visualizeButton");
const canvas = document.getElementById("graphCanvas");
const ctx = canvas.getContext("2d");

const state = {
  points: [],
  selectedIndex: 0,
  hoveredIndex: -1,
  animationStart: performance.now()
};

const anchorCache = new Map();

function hashString(value) {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function mulberry32(seed) {
  return function random() {
    let value = seed += 0x6D2B79F5;
    value = Math.imul(value ^ value >>> 15, value | 1);
    value ^= value + Math.imul(value ^ value >>> 7, value | 61);
    return ((value ^ value >>> 14) >>> 0) / 4294967296;
  };
}

function makeAnchor(name) {
  if (anchorCache.has(name)) return anchorCache.get(name);
  const random = mulberry32(hashString(`anchor:${name}`));
  const vector = Array.from({ length: DIMENSIONS }, () => random() * 2 - 1);
  const normalized = normalize(vector);
  anchorCache.set(name, normalized);
  return normalized;
}

function normalize(vector) {
  const mag = Math.sqrt(vector.reduce((sum, value) => sum + value * value, 0)) || 1;
  return vector.map(value => value / mag);
}

function addScaled(target, source, weight) {
  for (let index = 0; index < target.length; index += 1) {
    target[index] += source[index] * weight;
  }
}

function tokensFor(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, " ")
    .split(/[\s-]+/)
    .filter(Boolean);
}

function tagsForConcept(text) {
  const lower = text.toLowerCase();
  const tokens = tokensFor(text);
  const tags = [];

  Object.entries(semanticTags).forEach(([tag, words]) => {
    if (words.some(word => tokens.includes(word) || lower.includes(word))) {
      tags.push(tag);
    }
  });

  tokens.forEach(token => {
    if (token.endsWith("s") && token.length > 3) {
      Object.entries(semanticTags).forEach(([tag, words]) => {
        if (words.includes(token.slice(0, -1)) && !tags.includes(tag)) {
          tags.push(tag);
        }
      });
    }
  });

  return tags;
}

function embedConcept(text) {
  const vector = Array(DIMENSIONS).fill(0);
  const clean = text.trim().toLowerCase();
  const tokens = tokensFor(clean);
  const tags = tagsForConcept(clean);

  addScaled(vector, makeAnchor("universal-language-space"), 0.32);
  tokens.forEach(token => addScaled(vector, makeAnchor(`token:${token}`), 0.34));
  tags.forEach(tag => addScaled(vector, makeAnchor(`semantic:${tag}`), 1.12));

  for (let index = 0; index < clean.length - 2; index += 1) {
    addScaled(vector, makeAnchor(`ngram:${clean.slice(index, index + 3)}`), 0.045);
  }

  return normalize(vector);
}

function cosine(a, b) {
  return a.reduce((sum, value, index) => sum + value * b[index], 0);
}

function parseConcepts() {
  return conceptInput.value
    .split(/[\n,;]+/)
    .map(value => value.trim())
    .filter(Boolean)
    .slice(0, 12);
}

function initialProjection(vector, label) {
  const xAxis = makeAnchor("projection-axis-x");
  const yAxis = makeAnchor("projection-axis-y");
  const zAxis = makeAnchor("projection-axis-z");
  const jitter = mulberry32(hashString(`projection:${label}`));
  return {
    x: cosine(vector, xAxis) + (jitter() - 0.5) * 0.08,
    y: cosine(vector, yAxis) + (jitter() - 0.5) * 0.08,
    z: cosine(vector, zAxis) + (jitter() - 0.5) * 0.08
  };
}

function distance3d(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z);
}

function projectPoints(concepts) {
  const points = concepts.map(label => {
    const vector = embedConcept(label);
    return {
      label,
      vector,
      pos: initialProjection(vector, label),
      sim: []
    };
  });

  points.forEach((point, index) => {
    point.sim = points.map((other, otherIndex) => index === otherIndex ? 1 : cosine(point.vector, other.vector));
  });

  for (let step = 0; step < 160; step += 1) {
    for (let i = 0; i < points.length; i += 1) {
      for (let j = i + 1; j < points.length; j += 1) {
        const a = points[i];
        const b = points[j];
        const sim = Math.max(-0.1, Math.min(1, a.sim[j]));
        const target = 0.18 + (1 - sim) * 1.52;
        const dx = b.pos.x - a.pos.x;
        const dy = b.pos.y - a.pos.y;
        const dz = b.pos.z - a.pos.z;
        const dist = Math.max(0.001, Math.hypot(dx, dy, dz));
        const force = (dist - target) * 0.018;
        const fx = dx / dist * force;
        const fy = dy / dist * force;
        const fz = dz / dist * force;
        a.pos.x += fx;
        a.pos.y += fy;
        a.pos.z += fz;
        b.pos.x -= fx;
        b.pos.y -= fy;
        b.pos.z -= fz;
      }
    }
  }

  centerAndScale(points);
  return points;
}

function centerAndScale(points) {
  if (!points.length) return;
  const center = points.reduce((acc, point) => ({
    x: acc.x + point.pos.x,
    y: acc.y + point.pos.y,
    z: acc.z + point.pos.z
  }), { x: 0, y: 0, z: 0 });
  center.x /= points.length;
  center.y /= points.length;
  center.z /= points.length;

  let maxDistance = 0.1;
  points.forEach(point => {
    point.pos.x -= center.x;
    point.pos.y -= center.y;
    point.pos.z -= center.z;
    maxDistance = Math.max(maxDistance, distance3d(point.pos, { x: 0, y: 0, z: 0 }));
  });

  points.forEach(point => {
    point.pos.x /= maxDistance;
    point.pos.y /= maxDistance;
    point.pos.z /= maxDistance;
  });
}

function colorForIndex(index) {
  const colors = ["#2457a6", "#0595a8", "#22a7f0", "#444444", "#777777", "#111111"];
  return colors[index % colors.length];
}

function resizeCanvas() {
  const rect = canvas.getBoundingClientRect();
  const scale = window.devicePixelRatio || 1;
  canvas.width = Math.floor(rect.width * scale);
  canvas.height = Math.floor(rect.height * scale);
  ctx.setTransform(scale, 0, 0, scale, 0, 0);
}

function basis(width, height) {
  const unit = Math.min(width, height) * 0.31;
  return {
    origin: { x: width * 0.5, y: height * 0.68 },
    x: { x: -unit * 0.86, y: unit * 0.47 },
    y: { x: 0, y: -unit * 1.08 },
    z: { x: unit * 0.94, y: unit * 0.42 }
  };
}

function toScreen(pos, grid) {
  return {
    x: grid.origin.x + pos.x * grid.x.x + pos.y * grid.y.x + pos.z * grid.z.x,
    y: grid.origin.y + pos.x * grid.x.y + pos.y * grid.y.y + pos.z * grid.z.y
  };
}

function drawLine(a, b, color, width = 1) {
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.beginPath();
  ctx.moveTo(a.x, a.y);
  ctx.lineTo(b.x, b.y);
  ctx.stroke();
}

function drawGraphGrid(width, height, grid) {
  ctx.fillStyle = "#f4f1ea";
  ctx.fillRect(0, 0, width, height);

  const ticks = [-1, -0.5, 0, 0.5, 1];
  ctx.lineCap = "round";

  ticks.forEach(tick => {
    drawLine(toScreen({ x: -1, y: 0, z: tick }, grid), toScreen({ x: 1, y: 0, z: tick }, grid), "#d2d2d2", 2);
    drawLine(toScreen({ x: tick, y: 0, z: -1 }, grid), toScreen({ x: tick, y: 0, z: 1 }, grid), "#d2d2d2", 2);
    drawLine(toScreen({ x: -1, y: tick, z: -1 }, grid), toScreen({ x: -1, y: tick, z: 1 }, grid), "#d2d2d2", 2);
    drawLine(toScreen({ x: 1, y: tick, z: -1 }, grid), toScreen({ x: -1, y: tick, z: -1 }, grid), "#d2d2d2", 2);
  });

  ticks.forEach(tick => {
    drawLine(toScreen({ x: tick, y: 0, z: -1 }, grid), toScreen({ x: tick, y: 1.05, z: -1 }, grid), "#d2d2d2", 2);
    drawLine(toScreen({ x: 1, y: 0, z: tick }, grid), toScreen({ x: 1, y: 1.05, z: tick }, grid), "#d2d2d2", 2);
  });

  drawLine(toScreen({ x: 0, y: 0, z: 0 }, grid), toScreen({ x: -1.22, y: 0, z: 0 }, grid), "#111111", 3);
  drawLine(toScreen({ x: 0, y: 0, z: 0 }, grid), toScreen({ x: 0, y: 1.2, z: 0 }, grid), "#111111", 3);
  drawLine(toScreen({ x: 0, y: 0, z: 0 }, grid), toScreen({ x: 0, y: 0, z: 1.22 }, grid), "#111111", 3);
}

function drawPoint(point, index, grid, progress) {
  const floor = toScreen({ x: point.pos.x, y: 0, z: point.pos.z }, grid);
  const screen = toScreen(point.pos, grid);
  const selected = index === state.selectedIndex;
  const hovered = index === state.hoveredIndex;
  const radius = selected || hovered ? 17 : 13;
  const alpha = Math.max(0, Math.min(1, progress * 1.25 - index * 0.08));

  drawLine(floor, screen, "#b9b9b9", 3);

  ctx.globalAlpha = alpha;
  ctx.fillStyle = colorForIndex(index);
  ctx.beginPath();
  ctx.arc(screen.x, screen.y, radius, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = selected || hovered ? "#111111" : "#f4f1ea";
  ctx.lineWidth = selected || hovered ? 3 : 2;
  ctx.stroke();

  ctx.fillStyle = "#111111";
  ctx.font = "700 14px Arial, Helvetica, sans-serif";
  ctx.textAlign = "left";
  ctx.textBaseline = "middle";
  ctx.fillText(point.label.toUpperCase(), screen.x + radius + 8, screen.y - 4);
  ctx.globalAlpha = 1;
}

function draw() {
  const rect = canvas.getBoundingClientRect();
  const width = rect.width;
  const height = rect.height;
  const grid = basis(width, height);
  const progress = Math.min(1, (performance.now() - state.animationStart) / 700);

  drawGraphGrid(width, height, grid);

  state.points
    .map((point, index) => ({ point, index }))
    .sort((a, b) => (a.point.pos.z + a.point.pos.x) - (b.point.pos.z + b.point.pos.x))
    .forEach(({ point, index }) => drawPoint(point, index, grid, progress));

  requestAnimationFrame(draw);
}

function visualize() {
  state.points = projectPoints(parseConcepts());
  state.selectedIndex = Math.min(state.selectedIndex, Math.max(0, state.points.length - 1));
  state.hoveredIndex = -1;
  state.animationStart = performance.now();
}

function handleCanvasMove(event) {
  const rect = canvas.getBoundingClientRect();
  const grid = basis(rect.width, rect.height);
  const mouse = { x: event.clientX - rect.left, y: event.clientY - rect.top };
  let closestIndex = -1;
  let closestDistance = 28;

  state.points.forEach((point, index) => {
    const screen = toScreen(point.pos, grid);
    const distance = Math.hypot(screen.x - mouse.x, screen.y - mouse.y);
    if (distance < closestDistance) {
      closestDistance = distance;
      closestIndex = index;
    }
  });

  state.hoveredIndex = closestIndex;
}

canvas.addEventListener("mousemove", handleCanvasMove);
canvas.addEventListener("mouseleave", () => {
  state.hoveredIndex = -1;
});
canvas.addEventListener("click", () => {
  if (state.hoveredIndex >= 0) {
    state.selectedIndex = state.hoveredIndex;
  }
});

visualizeButton.addEventListener("click", visualize);
conceptInput.addEventListener("keydown", event => {
  if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
    visualize();
  }
});

window.addEventListener("resize", resizeCanvas);

resizeCanvas();
visualize();
requestAnimationFrame(draw);
