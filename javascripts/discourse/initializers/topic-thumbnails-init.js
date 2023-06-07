import { withPluginApi } from "discourse/lib/plugin-api";
import { inject as service } from "@ember/service";
import { readOnly } from "@ember/object/computed";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { once } from "@ember/runloop";
import {
  getResolverOption,
  setResolverOption,
} from "discourse-common/resolver";
import { htmlSafe } from "@ember/template";

export default {
  name: "topic-thumbnails-init",
  initialize() {
    this.applyViewClassWorkaround();
    withPluginApi("0.8.7", (api) => this.initWithApi(api));
  },

  applyViewClassWorkaround() {
    // Workaround for https://github.com/discourse/discourse/pull/12685
    // Can be removed once that has been merged, and sites have had time to update
    const viewClassKey = Object.keys(requirejs.entries).find((k) =>
      k.endsWith("raw-views/topic-list-thumbnail")
    );
    requirejs.entries["discourse/raw-views/topic-list-thumbnail"] =
      requirejs.entries[viewClassKey];
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
      ],
      isMinimalGrid: readOnly("topicThumbnailsService.displayMinimalGrid"),
      isThumbnailGrid: readOnly("topicThumbnailsService.displayGrid"),
      isThumbnailList: readOnly("topicThumbnailsService.displayList"),
      isMasonryList: readOnly("topicThumbnailsService.displayMasonry"),
    });

    if (settings.docs_thumbnail_mode !== "none") {
      api.modifyClass("component:docs-topic-list", {
        pluginId: "topic-thumbnails",
        topicThumbnailsService: service("topic-thumbnails"),
        classNameBindings: [
          "isMinimalGrid:topic-thumbnails-minimal",
          "isThumbnailGrid:topic-thumbnails-grid",
          "isThumbnailList:topic-thumbnails-list",
          "isMasonryList:topic-thumbnails-masonry",
        ],
        isMinimalGrid: readOnly("topicThumbnailsService.displayMinimalGrid"),
        isThumbnailGrid: readOnly("topicThumbnailsService.displayGrid"),
        isThumbnailList: readOnly("topicThumbnailsService.displayList"),
        isMasonryList: readOnly("topicThumbnailsService.displayMasonry")
      });
    }

    api.modifyClass("component:topic-list-item", {
      pluginId: "topic-thumbnails",
      topicThumbnailsService: service("topic-thumbnails"),

      // Hack to disable the mobile topic-list-item template
      // Our grid styling is responsive, and uses the desktop HTML structure
      @observes("topic.pinned")
      renderTopicListItem() {
        const wasMobileView = getResolverOption("mobileView");
        if (
          wasMobileView &&
          (this.topicThumbnailsService.displayGrid ||
            this.topicThumbnailsService.displayMasonry ||
            this.topicThumbnailsService.displayMinimalGrid)
        ) {
          setResolverOption("mobileView", false);
        }

        this._super();

        if (wasMobileView) {
          setResolverOption("mobileView", true);
        }
      },
    });

    //////////////////////////
    /////////// Masonry Layout
    //////////////////////////
    api.modifyClass("component:topic-list", {
      pluginId: "topic-thumbnails-masonry",
      topicThumbnailsService: service("topic-thumbnails"),

      masonryTargetColumnWidth: 300,
      masonryGridSpacingPixels: 10,
      masonryTitleSpacePixels: 76,
      masonryDefaultAspect: 1.3,
      masonryMinAspect: 0.7,

      @discourseComputed("masonryContainerWidth")
      masonryNumColumns(width) {
        return Math.floor(width / this.masonryTargetColumnWidth);
      },

      @discourseComputed(
        "masonryNumColumns",
        "masonryContainerWidth",
        "masonryGridSpacingPixels"
      )
      masonryColumnWidth(numColumns, containerWidth, gridSpacing) {
        return (containerWidth - (numColumns - 1) * gridSpacing) / numColumns;
      },

      didInsertElement() {
        this._super();
        if (!this.topicThumbnailsService.displayMasonry) {
          return;
        }
        this.updateElementHeight();

        if (window.ResizeObserver) {
          const observer = new ResizeObserver(() => this.updateElementHeight());
          observer.observe(this.element);
          this.set("resizeObserver", observer);
        }
      },

      willDestroyElement() {
        this._super();
        if (this.resizeObserver) {
          this.resizeObserver.unobserve(this.element);
        }
      },

      updateElementHeight() {
        this.set(
          "masonryContainerWidth",
          this.element.getBoundingClientRect().width
        );
      },

      @observes("topics.[]", "masonryContainerWidth")
      masonryTopicsChanged() {
        if (!this.topicThumbnailsService.displayMasonry) {
          return;
        }
        if (!this.masonryContainerWidth) {
          return;
        }
        once(this, this.calculateMasonryLayout);
      },

      calculateMasonryLayout() {
        const numColumns = this.masonryNumColumns;
        const gridSpacingPixels = this.masonryGridSpacingPixels;

        const columnHeights = [];
        for (let n = 0; n < numColumns; n++) {
          columnHeights[n] = 0;
        }

        this.filteredTopics.forEach((topic) => {
          // Pick the column with the lowest height
          const smallestColumn = columnHeights.indexOf(
            Math.min(...columnHeights)
          );

          // Get the height of this topic
          let aspect = this.masonryDefaultAspect;
          if (topic.thumbnails) {
            aspect = topic.thumbnails[0].width / topic.thumbnails[0].height;
          }
          aspect = Math.max(aspect, this.masonryMinAspect);
          const thisHeight =
            this.masonryColumnWidth / aspect + this.masonryTitleSpacePixels;

          topic.set("masonryData", {
            columnIndex: smallestColumn,
            height: thisHeight,
            heightAbove: columnHeights[smallestColumn],
          });

          columnHeights[smallestColumn] += thisHeight + gridSpacingPixels;
        });

        this.set("masonryTallestColumn", Math.max(...columnHeights));
      },

      attributeBindings: ["masonryStyle:style"],

      @discourseComputed(
        "topicThumbnailsService.displayMasonry",
        "masonryNumColumns",
        "masonryGridSpacingPixels",
        "masonryTallestColumn",
        "masonryColumnWidth"
      )
      masonryStyle(
        useMasonry,
        numColumns,
        gridSpacingPixels,
        tallestColumn,
        columnWidth
      ) {
        if (!useMasonry) {
          return;
        }

        return htmlSafe(
          `--masonry-num-columns: ${Math.round(numColumns)}; ` +
            `--masonry-grid-spacing: ${gridSpacingPixels}px; ` +
            `--masonry-tallest-column: ${Math.round(tallestColumn)}px; ` +
            `--masonry-column-width: ${Math.round(columnWidth)}px; `
        );
      },
    });

    api.modifyClass("component:topic-list-item", {
      pluginId: "topic-thumbnails-masonry",
      attributeBindings: ["masonryStyle:style"],

      @discourseComputed("topic.masonryData")
      masonryStyle(masonryData) {
        if (!masonryData) {
          return;
        }

        return htmlSafe(
          `--masonry-height: ${Math.round(masonryData.height)}px; ` +
            `--masonry-height-above: ${Math.round(
              masonryData.heightAbove
            )}px; ` +
            `--masonry-column-index: ${masonryData.columnIndex};`
        );
      },
    });
  },
};
