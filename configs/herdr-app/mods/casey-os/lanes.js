// What the board makes of Linear's answer: no drawing, no herdr, so it can be
// asserted on its own against a recorded response.

// A gate label said in words, as the sidebar says agent state in words.
// gate:none is the normal case and says nothing worth a line.
const GATE = {
  "gate:questions": "questions open",
  "gate:openspec": "openspec gate",
  "gate:wayfinder": "wayfinder gate",
};

// Ochre means "needs you" and nothing else, as on the agent rows.
export const MINE = { "Needs me": "needs you", "In Review": "in review" };

// Why an issue is Casey's own move, in words, or null when it is not.
// Needs me and In Review say so outright. Beyond that: work already committed
// to that carries gate:questions is stalled waiting for an answer from him,
// which is the same thing by another name and far more common — across all 77
// COS issues the Needs me status has only ever held the daily intake card,
// while five of the eight committed cards sit on an open question.
export function needsYou(i) {
  if (MINE[i.status]) return MINE[i.status];
  return committed(i) && i.gateLabel === "gate:questions" ? "questions open" : null;
}

export const committed = (i) => i.type === "started" || i.type === "unstarted";
// Where a card would sit if it were not in the ochre band.
export const laneWord = (i) => (i.type === "started" ? "moving" : i.type === "unstarted" ? "ready" : null);

export function since(ms) {
  const m = Math.floor((Date.now() - ms) / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

// Projects are named for people to read in Linear ("Klosterdorf — Dorf-Website
// (klosterdorf.de)"); a row tail has room for the first part only.
export function shortProject(name) {
  if (!name) return null;
  return name.split(/\s+[—–-]\s+/)[0].replace(/\s*\(.*\)\s*$/, "").trim() || null;
}

export function norm(node) {
  const labels = (node.labels?.nodes ?? []).map((l) => l.name);
  const gate = labels.find((l) => l.startsWith("gate:") && l !== "gate:none");
  return {
    id: node.identifier,
    uuid: node.id ?? null, // what issueUpdate takes
    title: node.title,
    url: node.url,
    status: node.state?.name ?? "",
    type: node.state?.type ?? "",
    gate: GATE[gate] ?? (gate ? gate.slice(5) : null),
    gateLabel: gate ?? null,
    labelIds: (node.labels?.nodes ?? []).map((l) => l.id).filter(Boolean),
    labels,
    risk: labels.includes("risk:high"),
    waiting: labels.includes("waiting"),
    project: shortProject(node.project?.name),
    at: Date.parse(node.updatedAt ?? "") || null,
  };
}

// The stream, in the order it is read: what needs Casey, what is moving, what is
// next, what is stuck on someone else. Everything else is the gate queue, which
// is a count in the ledger rather than rows.
export function lanes(issues) {
  const mine = [], doing = [], ready = [], waiting = [], gate = [];
  for (const i of issues) {
    if (needsYou(i)) mine.push(i);
    // `waiting` only lifts work that was already committed to. A parked
    // candidate is still just a candidate and stays in the queue's count,
    // or nine of them would crowd out the four things actually moving.
    else if (i.waiting && committed(i)) waiting.push(i);
    else if (i.type === "started") doing.push(i);
    else if (i.type === "unstarted") ready.push(i);
    else gate.push(i);
  }
  const recent = (a, b) => (b.at ?? 0) - (a.at ?? 0);
  // A status that says "needs you" outright stands above one inferred from a gate.
  mine.sort((a, b) => (MINE[b.status] ? 1 : 0) - (MINE[a.status] ? 1 : 0) || recent(a, b));
  return {
    mine,
    doing: doing.sort(recent),
    ready: ready.sort(recent),
    waiting: waiting.sort(recent),
    gate: gate.sort(recent),
  };
}

// The gate queue by what is holding each one up, biggest first, and how much of
// it is parked on someone else.
export function gates(queue) {
  const by = new Map();
  for (const i of queue) by.set(i.gate ?? "no gate", (by.get(i.gate ?? "no gate") ?? 0) + 1);
  return {
    groups: [...by].map(([words, count]) => ({ words, count })).sort((a, b) => b.count - a.count),
    parked: queue.filter((i) => i.waiting).length,
  };
}

// The workspace this board belongs to, taken from any issue link rather than
// written down twice.
export function teamUrl(issues, team) {
  const host = issues.find((i) => i.url)?.url?.match(/^(https:\/\/linear\.app\/[^/]+)\//);
  return host ? `${host[1]}/team/${team}/active` : null;
}
