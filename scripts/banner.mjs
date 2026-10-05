// The installer banner's data (monica-stack's BN_* settings), drawn from the
// logo's geometry: `node scripts/banner.mjs` prints them, to paste over the
// ones in monica-stack.
//
// Characters are drawn as 2x2 quarter cells. A character is about twice as
// tall as it is wide, so a quarter cell is 0.5 wide and 1 tall in units of a
// character's width; the shapes are laid out in those units.
const COLS = 30, ROWS = 13;   // the banner's size, in characters
const R = 11.4;               // the hexagon's radius (top vertex to centre)
const RR = 13.4;              // the arrows' ring, outside the face
const FEAT = 1.0;             // ears, eye patches and nose, relative to the logo
const SW = COLS * 2, SH = ROWS * 2;
const cx = SW / 2 * 0.5, cy = SH / 2;
const hex = (r) => [0, 60, 120, 180, 240, 300].map(a => [cx + r * Math.sin(a * Math.PI / 180) * (Math.sqrt(3) / 2) / Math.sin(60 * Math.PI / 180) * 1, cy - r * Math.cos(a * Math.PI / 180)]);
const inPoly = (pts, x, y) => { let c = false; for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) { const [xi, yi] = pts[i], [xj, yj] = pts[j]; if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) c = !c; } return c; };
const H = hex(R);
// svg (200-unit logo) → visual: the hexagon's top vertex (100,4), height 192 → 2R
const k = 2 * R / 192, sv = (x, y) => [cx + (x - 100) * k, cy - R + (y - 4) * k];
const ell = (x, y, rx, ry, rot) => { const [ex, ey] = sv(x, y); const a = rot * Math.PI / 180; return (px, py) => { const dx = px - ex, dy = py - ey; const u = (dx * Math.cos(a) + dy * Math.sin(a)) / (rx * k * FEAT), v = (-dx * Math.sin(a) + dy * Math.cos(a)) / (ry * k * FEAT); return u * u + v * v <= 1; }; };
const ink = [ell(78, 108, 13, 20, 32), ell(122, 108, 13, 20, -32), ell(100, 132, 9, 4, 0)];
const earL = [sv(17, 52), sv(58, 28), sv(17, 90)], earR = [sv(183, 52), sv(142, 28), sv(183, 90)];
// 0 empty, 1 white, 2 grey, 3 ink
const px = [];
for (let y = 0; y < SH; y++) { px.push([]); for (let x = 0; x < SW; x++) {
  const vx = (x + 0.5) * 0.5, vy = y + 0.5;
  let v = 0;
  if (inPoly(H, vx, vy)) { v = vx < cx ? 1 : 2; if (inPoly(earL, vx, vy) || inPoly(earR, vx, vy) || ink.some(f => f(vx, vy))) v = 3; }
  px[y].push(v);
} }
// the ring: walk the outer hexagon finely, keep the quarter cells it passes, in order
const HR = hex(RR), path = [];
for (let i = 0; i < 6; i++) { const [x0, y0] = HR[i], [x1, y1] = HR[(i + 1) % 6]; for (let t = 0; t < 1; t += 0.002) {
  const sx = Math.floor((x0 + (x1 - x0) * t) / 0.5), sy = Math.floor(y0 + (y1 - y0) * t);
  const last = path[path.length - 1]; if (!last || last[0] !== sy || last[1] !== sx) path.push([sy, sx]);
} }
while (path.length > 1 && path[0][0] === path[path.length-1][0] && path[0][1] === path[path.length-1][1]) path.pop();
// conflicts: ring quarter cells sharing a character with face quarter cells
let conflicts = 0; for (const [sy, sx] of path) { const r = sy >> 1, c = sx >> 1; for (const [dy, dx] of [[0,0],[0,1],[1,0],[1,1]]) if (px[2*r+dy]?.[2*c+dx]) { conflicts++; break; } }
// face cells as "fg,bg,glyph" (colours: 231 white, 254 grey, 236 ink; - none)
const COL = [null, 231, 254, 236], Q = ' ▘▝▀▖▌▞▛▗▚▐▜▄▙▟█';
const face = [];
for (let r = 0; r < ROWS; r++) { const cells = []; for (let c = 0; c < COLS; c++) {
  const s = [px[2*r][2*c], px[2*r][2*c+1], px[2*r+1][2*c], px[2*r+1][2*c+1]];
  if (s.every(v => !v)) { cells.push('-'); continue; }
  const f = {}; s.forEach(v => f[v] = (f[v] || 0) + 1);
  let order = Object.keys(f).map(Number).sort((a, b) => (b === 3) - (a === 3) || f[b] - f[a]);   // ink first: features win
  let fg = order[0], bg = order[1] ?? 0;
  if (fg === 0) [fg, bg] = [bg, 0];
  let m = 0; s.forEach((v, i) => { if (v === fg) m |= [1, 2, 4, 8][i]; });
  cells.push(`${COL[fg]},${bg ? COL[bg] : '-'},${Q[m]}`);
} face.push(cells.join(' ')); }
if (conflicts) console.error(`warning: the ring shares ${conflicts} characters with the face`);
const out = [
  `BN_COLS=${COLS} BN_ROWS=${ROWS}`,
  `BN_FACE=(`, ...face.map(l => `  "${l}"`), `)`,
  `BN_PATH="${path.map(([sy, sx]) => `${sy >> 1},${sx >> 1},${[1, 2, 4, 8][(sy & 1) * 2 + (sx & 1)]}`).join(' ')}"`,
];
console.log(out.join('\n'));
