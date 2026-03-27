function hexToRgb(hex) {
  const r = parseInt(hex.slice(1,3), 16);
  const g = parseInt(hex.slice(3,5), 16);
  const b = parseInt(hex.slice(5,7), 16);
  return [r, g, b];
}

function luminance(r, g, b) {
  const [rs, gs, bs] = [r, g, b].map(c => {
    c = c / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

function contrastRatio(hex1, hex2) {
  const [r1,g1,b1] = hexToRgb(hex1);
  const [r2,g2,b2] = hexToRgb(hex2);
  const l1 = luminance(r1, g1, b1);
  const l2 = luminance(r2, g2, b2);
  return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
}

// Default brand checks — customize per project
const checks = [
  { name: 'Primary text on base', fg: '#E8ECF4', bg: '#080C18' },
  { name: 'Secondary text on base', fg: '#7B8BA3', bg: '#080C18' },
  { name: 'Muted text on base', fg: '#4A5568', bg: '#080C18' },
  { name: 'Primary text on card', fg: '#E8ECF4', bg: '#0F1628' },
  { name: 'Accent on base', fg: '#00D4FF', bg: '#080C18' },
  { name: 'Accent on card', fg: '#00D4FF', bg: '#0F1628' },
  { name: 'Primary text on elevated', fg: '#E8ECF4', bg: '#1A2138' },
  { name: 'White on navy (Perlantir)', fg: '#FFFFFF', bg: '#0A1628' },
];

console.log('=== Contrast Ratio Report ===\n');
checks.forEach(c => {
  const ratio = contrastRatio(c.fg, c.bg).toFixed(2);
  const pass = ratio >= 4.5 ? '✅ PASS' : ratio >= 3 ? '⚠️ WARN (large text only)' : '❌ FAIL';
  console.log(`${c.name}: ${ratio}:1 — ${pass}`);
});
