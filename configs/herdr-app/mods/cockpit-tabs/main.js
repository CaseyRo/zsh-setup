// Cockpit: no tab bar. What's left is the CDiT horizon, a 1px accent line the
// window drags by, and an ochre point on it for every agent waiting on you;
// click one to go there. Tabs are Ctrl+1–9 and the agent rows in the sidebar.
// At the right end: the account's 7-day Claude usage, paced like the terminal
// status line (red once more than 15 points ahead of an even split of the week).
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, run, theme, window, layout, settings, shared } from "herdr";

const PINE = "#283128";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

export default class Tabs extends View {
  render() {
    const t = theme();
    const root = layout(), sidebar = find(root, "sidebar"), w = window();
    // Keep the points clear of the macOS window buttons when the sidebar is narrow or hidden.
    const left = w?.platform === "macos" && w.titlebar === "none" && !w.fullscreen && root?.traffic_lights
      ? Math.max(10, (root.traffic_lights[0] + 64) / settings().zoom - (sidebar?.hidden ? 0 : sidebar?.size?.px ?? 0))
      : 10;
    const stop = (_e, cx) => cx.stop_propagation();
    const points = agents().filter(a => a.status === "blocked").map((a, k) =>
      div().id(`horizon-${a.address}`).absolute().top(5).left(left + k * 16)
        .size(9).rounded(5).bg(t.blocked).border(1).border_color(PINE).cursor_pointer()
        .tooltip(`${a.space_name}: needs you`)
        .on_mouse_down("left", stop).on_click(() => run("agent.focus", { terminal: a.address })));
    return div().relative().size_full().bg(t.canvas)
      .child(div().absolute().left(0).right(0).top(9).h(1).bg(t.accent))
      .children(points)
      .when(Boolean(shared("claude.status")?.week), el => el.child(this.week(shared("claude.status").week, t)));
  }

  week(w, t) {
    const used = Math.min(100, Math.max(0, w.used_percentage));
    const elapsed = Math.min(1, Math.max(0, 1 - (w.resets_at - Date.now() / 1000) / 604800));
    const ahead = used - elapsed * 100 > 15;
    const tone = ahead ? t.ansi1 : t.muted;
    const W = 80;
    // Sits on the horizon in the canvas colour, so the line breaks around it.
    return h_flex().absolute().right(12).top(0).h(19).px(8).gap(7).items_center().bg(t.canvas)
      .text_size(11.5).text_color(tone)
      .child("7d")
      .child(div().relative().w(W).h(5).rounded(3).bg(t.border)
        .child(div().absolute().left(0).top(0).h(5).rounded(3).w(Math.round(W * used / 100)).bg(tone))
        .child(div().absolute().top(-2).h(9).w(1).left(Math.round(W * elapsed)).bg(t.foreground)))
      .child(`${Math.round(used)}%`);
  }
}
