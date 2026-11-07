// Cockpit: the CDiT horizon, a 1px accent line the window drags by, with the
// spaces standing on it as stations. Each carries its cmd-number and its name,
// and an ochre point only when something in it needs you — click the point to
// go straight to that agent, the name to go to the space.
// The Casey OS board's station also says what is in what state: the needs-you
// count in ochre, then moving and ready.
// At the right end: the account's 7-day Claude usage, paced like the terminal
// status line (red once more than 15 points ahead of an even split of the week).
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, panes, run, spaces, theme, window, layout, settings, shared } from "herdr";

const PINE = "#283128";
const BOARD = "casey-os"; // the mod whose space gets the task counts

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const clean = (v) => (v ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

// What a space is called up here: the session running in it, by the name that
// session gave itself — Claude Code puts it in the terminal title
// ("dev-handoff-casey-os"). Five spaces are called "dev"; their sessions are
// not, and with the sidebar hidden this bar is the only place that says so.
// A named tab wins over the title; a title that only repeats the program or a
// path says nothing new, so the space's own name stands in.
// The session that needs you is the one named, else the one on screen.
function session(s, waiting, all) {
  const tabs = s.tabs ?? [];
  const active = tabs.find((c) => c.active);
  const mine = all.filter((a) => a.space === s.id);
  const a = waiting ?? mine.find((x) => x.tab === active?.id) ?? mine[0];
  const tab = tabs.find((c) => c.id === a?.tab) ?? active;
  if (tab?.named) return tab.name;
  const title = clean(a?.title);
  const telling = title && title !== a?.program?.name && title !== s.name && !/^[~/]/.test(title) && !title.includes("@");
  return telling ? title : s.name;
}

export default class Tabs extends View {
  render() {
    const t = theme();
    const root = layout(), sidebar = find(root, "sidebar"), w = window();
    // Keep the stations clear of the macOS window buttons when the sidebar is narrow or hidden.
    const left = w?.platform === "macos" && w.titlebar === "none" && !w.fullscreen && root?.traffic_lights
      ? Math.max(10, (root.traffic_lights[0] + 64) / settings().zoom - (sidebar?.hidden ? 0 : sidebar?.size?.px ?? 0))
      : 10;
    const week = shared("claude.status")?.week;
    return div().relative().size_full().bg(t.canvas)
      .child(div().absolute().left(0).right(0).top(13).h(1).bg(t.accent))
      // The gap between stations is where the horizon shows through, so it is
      // wide enough to read as a line rather than as a seam. The row stops short
      // of the week readout and the working stations give space back before the
      // board does: pinning it last is worthless if a crowded bar pushes it off
      // the edge first, which is exactly what eleven spaces did.
      .child(h_flex().absolute().left(left).right(week ? 222 : 14).top(4).h(19).gap(10).items_center()
        .children(this.stations(t)))
      .when(Boolean(week), el => el.child(this.week(week, t)));
  }

  stations(t) {
    const all = agents();
    // Which space holds the board, without knowing what it is called.
    const boardTab = panes().find((p) => p.mod === BOARD)?.tab;
    const onBoard = (s) => Boolean(boardTab) && (s.tabs ?? []).some((c) => c.id === boardTab);
    const stop = (_e, cx) => cx.stop_propagation();
    // Casey OS keeps the end of the horizon whatever its cmd-number: one fixed
    // place to look is what lets the sidebar stay hidden. sort is stable, so
    // every other station keeps the order the spaces list gives it.
    // shortcut: no overflow handling, so past roughly a dozen stations they
    // would run under the week bar; truncate harder or drop the numbers then.
    const ordered = spaces().map((s, i) => ({ s, i })).sort((a, b) => Number(onBoard(a.s)) - Number(onBoard(b.s)));
    return ordered.map(({ s, i }) => {
      const waiting = all.find((a) => a.space === s.id && a.status === "blocked");
      const board = onBoard(s);
      const name = session(s, waiting, all);
      return h_flex()
        .id(`station-${s.id}`)
        .h(19).px(8).gap(6).items_center().rounded(4)
        // When the bar is crowded the names go, but not all of them: the board,
        // the one you are standing in, and anything that needs you keep their
        // full width. Those are the three you have to be able to read.
        .when(board || s.active || Boolean(waiting), (el) => el.flex_none())
        .when(!board && !s.active && !waiting, (el) => el.flex_shrink(1).min_w(34))
        // Masks the horizon so the line runs between the stations, not through
        // them; the one you are standing in is filled, as the sidebar fills its
        // selected row. With the sidebar hidden this is the only thing that says
        // where you are, so weight alone was not enough.
        .bg(s.active ? t.selected : t.canvas)
        .text_size(12)
        .text_color(s.active ? t.foreground : t.muted)
        .when(s.active, (el) => el.font_semibold())
        .when(!s.active, (el) => el.hover((st) => st.bg(t.hover).text_color(t.foreground)))
        .cursor_pointer()
        .tooltip(
          waiting ? `${name}: needs you`
            : name === s.name ? `${s.name} · cmd-${i + 1}`
            : `${name} in ${s.name} · cmd-${i + 1}`,
        )
        .on_mouse_down("left", stop)
        .on_click(() => run("space.select", { id: s.id }))
        // A point only when something in there needs you: the sidebar can afford
        // a coloured avatar per space, a 28px bar cannot — an orange avatar dot
        // beside an ochre one would make ochre stop meaning "needs you".
        .when(Boolean(waiting), (el) =>
          el.child(
            div().id(`waiting-${s.id}`).size(9).flex_none().rounded(5).bg(t.blocked).border(1).border_color(PINE)
              .tooltip(`${s.name}: needs you — click for the agent`)
              .on_mouse_down("left", stop)
              .on_click((_e, cx) => { cx.stop_propagation(); run("agent.focus", { terminal: waiting.address }); }),
          ),
        )
        // The space's own index, not the position on the bar: it is the cmd-key
        // that goes there, so it stays true when Casey OS is moved to the end.
        .when(i < 9, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(String(i + 1))))
        .child(div().flex_shrink(1).min_w(0).max_w(150).truncate().child(name))
        .when(Boolean(board), (el) => el.child(this.counts(t)));
    });
  }

  // What the board found, in the width of a word. The ochre number is the only
  // coloured thing up here when something is waiting; it is absent when nothing is.
  counts(t) {
    const c = shared(BOARD);
    if (!c) return div().flex_none().text_size(11).text_color(t.dim).child("…");
    if (c.error) return div().flex_none().text_size(11).text_color(t.dim).tooltip(c.error).child("—");
    const pair = (n, mark, ink) =>
      h_flex().flex_none().gap(3).items_center()
        .child(div().flex_none().text_size(11).text_color(ink).child(String(n)))
        .child(mark);
    return h_flex().flex_none().gap(9).items_center()
      .when(c.mine > 0, (el) => el.child(pair(c.mine, div().size(7).flex_none().rounded_full().bg(t.blocked).border(1).border_color(PINE), t.blocked)))
      .when(c.doing > 0, (el) => el.child(pair(c.doing, div().size(7).flex_none().rounded_full().bg(t.working), t.muted)))
      .when(c.ready > 0, (el) => el.child(pair(c.ready, div().size(7).flex_none().rounded_full().border(1).border_color(t.idle), t.muted)))
      .when(!c.mine && !c.doing && !c.ready, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child("clear")));
  }

  // The week as an instrument on the horizon: the bar rides the line, a tick
  // crosses it where an even split of the week would be now (so the rest of the
  // bar is the week left), and the figure follows. Red when more than 15 points
  // ahead of pace, or at 90% used whatever the pace. Reset time is in the tooltip.
  week(w, t) {
    const used = Math.min(100, Math.max(0, w.used_percentage));
    const left = w.resets_at - Date.now() / 1000;
    const elapsed = Math.min(1, Math.max(0, 1 - left / 604800));
    const pace = Math.round(elapsed * 100);
    const ahead = used - pace > 15;
    const nearLimit = used >= 90; // nearly out late in the week is the case that matters most
    const warn = ahead || nearLimit;
    const fill = warn ? t.ansi1 : t.accent;
    const W = 140;
    const resets = new Date(w.resets_at * 1000);
    // Herdr's JS ignores Intl weekday options, so name the day by hand.
    const hhmm = resets.toTimeString().slice(0, 5);
    const name = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][resets.getDay()];
    return h_flex().id("week").absolute().right(14).top(4).h(19).px(10).gap(9).items_center().bg(t.canvas)
      .tooltip(`${nearLimit ? "Nearly at the 7-day limit: " : ahead ? "Ahead of pace: " : ""}${Math.round(used)}% used; an even pace would be ${pace}% by now. Resets ${name} ${hhmm}.`)
      .child(div().relative().w(W).h(6).rounded(3).bg(t.border)
        .child(div().absolute().left(0).top(0).h(6).rounded(3).w(Math.max(6, Math.round(W * used / 100))).bg(fill))
        .child(div().absolute().top(-4).h(14).w(2).rounded(1).left(Math.round(W * elapsed) - 1).bg(t.foreground)))
      .child(div().text_size(13).font_semibold().text_color(warn ? t.ansi1 : t.foreground).child(`${Math.round(used)}%`));
  }
}
