import { withPluginApi } from "discourse/lib/plugin-api";
import { inject as service } from "@ember/service";
import { readOnly } from "@ember/object/computed";

export default {
  name: "topic-thumbnails-init",
  initialize() {
    withPluginApi("0.8.7", (api) => this.initWithApi(api));
  },

  initWithApi(api) {
    api.modifyClass("component:topic-list", {
      topicThumbnailsService: service("topic-thumbnails"),
      classNameBindings: [
        "isThumbnailGrid:topic-thumbnails-grid",
        "isThumbnailList:topic-thumbnails-list",
      ],
      isThumbnailGrid: readOnly("topicThumbnailsService.displayGrid"),
      isThumbnailList: readOnly("topicThumbnailsService.displayList"),
    });

    api.modifyClass("component:topic-list-item", {
      topicThumbnailsService: service("topic-thumbnails"),

      // Hack to disable the mobile topic-list-item template
      // Our grid styling is responsive, and uses the desktop HTML structure
      renderTopicListItem() {
        const templateName = "mobile/list/topic-list-item";
        let templateStorage;

        if (this.site.mobileView && this.topicThumbnailsService.displayGrid) {
          templateStorage = Discourse.RAW_TEMPLATES[templateName];
          delete Discourse.RAW_TEMPLATES[templateName];
        }

        this._super();

        if (templateStorage) {
          Discourse.RAW_TEMPLATES[templateName] = templateStorage;
        }
      },
    });
  },
};
