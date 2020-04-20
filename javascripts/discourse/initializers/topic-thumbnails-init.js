import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "topic-thumbnails-init",
  initialize() {
    withPluginApi("0.8.7", (api) => this.initWithApi(api));
  },

  initWithApi(api) {
    const site = api.container.lookup("site:main");

    api.modifyClass("component:topic-list-item", {
      expandPinned: site.mobileView
        ? settings.show_excerpts_mobile
        : settings.show_excerpts_desktop,
    });

    // Scrap the mobile-specific template, we want the desktop one
    if (settings.enable_grid && settings.show_thumbnails_mobile) {
      delete Discourse.RAW_TEMPLATES["mobile/list/topic-list-item"];
    }
  },
};
