const InfiniteScroll = {
  page() {
    return parseInt(this.el.dataset.page, 10);
  },
  loadMore(entries) {
    const target = entries[0];
    if (this.pending && target.isIntersecting && this.pending == this.page()) {
      this.pending = this.page() + 1;
      this.pushEvent("load-more", {});
    }
  },
  mounted() {
    this.pending = this.page();

    const opts = {
      root: null,
      rootMargin: "-90% 0px 10% 0px",
      threshold: 1.0,
    };

    this.observer = new IntersectionObserver(this.loadMore.bind(this), opts);
    this.observer.observe(this.el);
  },
  reconnected() {
    this.pending = this.page();
  },
  updated() {
    this.pending = this.page();
  },
  beforeDestroy() {
    this.observer.unobserve(this.el);
  },
};

export default InfiniteScroll;
