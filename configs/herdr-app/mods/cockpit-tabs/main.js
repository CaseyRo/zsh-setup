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
      div().id(`horizon-${a.address}`).absolute().top(9).left(left + k * 16)
        .size(9).rounded(5).bg(t.blocked).border(1).border_color(PINE).cursor_pointer()
        .tooltip(`${a.space_name}: needs you`)
        .on_mouse_down("left", stop).on_click(() => run("agent.focus", { terminal: a.address })));
    return div().relative().size_full().bg(t.canvas)
      .child(div().absolute().left(0).right(0).top(13).h(1).bg(t.accent))
      .children(points)
      .when(Boolean(shared("claude.status")?.week), el => el.child(this.week(shared("claude.status").week, t)));
  }

  // The week as an instrument on the horizon: the bar rides the line, a tick
  // crosses it where an even split of the week would be now (so the rest of the
  // bar is the week left), and the figure follows. Red only when more than 15
  // points ahead. The exact reset time is in the tooltip.
  week(w, t) {
    const used = Math.min(100, Math.max(0, w.used_percentage));
    const left = w.resets_at - Date.now() / 1000;
    const elapsed = Math.min(1, Math.max(0, 1 - left / 604800));
    const pace = Math.round(elapsed * 100);
    const ahead = used - pace > 15;
    const fill = ahead ? t.ansi1 : t.accent;
    const W = 140;
    const resets = new Date(w.resets_at * 1000);
    // Herdr's JS ignores Intl weekday options, so name the day by hand.
    const hhmm = resets.toTimeString().slice(0, 5);
    const name = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][resets.getDay()];
    return h_flex().id("week").absolute().right(14).top(4).h(19).px(10).gap(9).items_center().bg(t.canvas)
      .tooltip(`${Math.round(used)}% of the 7-day limit used; an even pace would be ${pace}% by now. Resets ${name} ${hhmm}.`)
      .child(div().relative().w(W).h(6).rounded(3).bg(t.border)
        .child(div().absolute().left(0).top(0).h(6).rounded(3).w(Math.max(6, Math.round(W * used / 100))).bg(fill))
        .child(div().absolute().top(-4).h(14).w(2).rounded(1).left(Math.round(W * elapsed) - 1).bg(t.foreground)))
      .child(div().text_size(13).font_semibold().text_color(ahead ? t.ansi1 : t.foreground).child(`${Math.round(used)}%`));
  }
}
