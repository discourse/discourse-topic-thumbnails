import { observer } from "@ember/object";
import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import { getResolverOption, setResolverOption } from "discourse/resolver";

export default {
  name: "topic-thumbnails-init",
  initialize() {
    withSilencedDeprecations("discourse.hbr-topic-list-overrides", () => {
      withPluginApi("0.8.7", (api) => this.initWithApi(api));
    });
  },

  initWithApi(api) {
    api.modifyClass("component:topic-list", {
      pluginId: "topic-thumbnails",
      topicThumbnailsService: service("topic-thumbnails"),
      classNameBindings: [
        "isMinimalGrid:topic-thumbnails-minimal",
        "isThumbnailGrid:topic-thumbnails-grid",
        "isThumbnailList:topic-thumbnails-list",
        "isMasonryList:topic-thumbnails-masonry",
        "isBlogStyleGrid:topic-thumbnails-blog-style-grid",
      ],
      isMinimalGrid: readOnly("topicThumbnailsService.displayMinimalGrid"),
      isThumbnailGrid: readOnly("topicThumbnailsService.displayGrid"),
      isThumbnailList: readOnly("topicThumbnailsService.displayList"),
      isMasonryList: readOnly("topicThumbnailsService.displayMasonry"),
      isBlogStyleGrid: readOnly("topicThumbnailsService.displayBlogStyle"),
    });

    api.modifyClass("component:topic-list-item", {
      pluginId: "topic-thumbnails",
      topicThumbnailsService: service("topic-thumbnails"),

      // Hack to disable the mobile topic-list-item template
      // Our grid styling is responsive, and uses the desktop HTML structure
      renderTopicListItem: observer("topic.pinned", function () {
        const wasMobileView = getResolverOption("mobileView");
        if (
          wasMobileView &&
          (this.topicThumbnailsService.displayGrid ||
            this.topicThumbnailsService.displayMasonry ||
            this.topicThumbnailsService.displayMinimalGrid ||
            this.topicThumbnailsService.displayBlogStyle)
        ) {
          setResolverOption("mobileView", false);
        }

        this._super();

        if (wasMobileView) {
          setResolverOption("mobileView", true);
        }
      }),
    });

    api.modifyClass(
      "component:topic-list-item",
      (Superclass) =>
        class extends Superclass {
          @service topicThumbnails;

          get classNames() {
            const result = super.classNames;
            if (this.topicThumbnails.displayMasonry) {
              return [...result, `masonry-${this.index}`];
            }
            return result;
          }
        }
    );
  },
};
