import { render, cancel } from "../vendor/timeago.js";

const TimeAgo = {
  mounted() {
    render(this.el, "en_short");
  },
  updated() {
    render(this.el, "en_short");
  },
  destroyed() {
    cancel(this.el);
  },
};

export default TimeAgo;
