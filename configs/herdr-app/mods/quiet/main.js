// Notifications off. Herdr draws a toast for everything notify() posts — its own
// agent done/blocked messages and every mod's — and the layout root's "toast"
// field picks the mod that draws them. This one draws nothing and closes the
// overlay in init, the pattern AGENTS.md gives for handing notifications
// somewhere else; here that somewhere is nowhere. Casey, 20 Nov 2026:
// "disable all notifications".
//
// What silence costs: the shipped toast is the only place two messages surface —
// "<machine> needs login; run hc machine login <machine>" and a core-update
// error. Both still show in `herdr-app status`. Flip ERRORS_TOO to true to let
// those back in and keep everything else quiet.
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { props, closeOverlay, theme } from "herdr";

const ERRORS_TOO = false;

export default class Quiet extends View {
  init(p) {
    this.show = ERRORS_TOO && p?.level === "error";
    if (!this.show && p?.overlay) closeOverlay(p.overlay);
  }

  render() {
    if (!this.show) return div();
    const t = theme();
    const p = props() ?? {};
    return h_flex()
      .id("quiet")
      .size_full()
      .px(18)
      .gap(12)
      .items_center()
      .bg(t.popover)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click(() => closeOverlay(p.overlay))
      .child(div().size(8).rounded(4).flex_none().bg(t.blocked))
      .child(div().flex_1().truncate().text_size(13).text_color(t.foreground).child(p.title ?? ""));
  }
}
