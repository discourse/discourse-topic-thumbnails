import Service, { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Site from "discourse/models/site";

const minimalGridCategories = settings.minimal_grid_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const listCategories = settings.list_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const gridCategories = settings.grid_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const masonryCategories = settings.masonry_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const minimalGridTags = settings.minimal_grid_tags.split("|");
const listTags = settings.list_tags.split("|");
const gridTags = settings.grid_tags.split("|");
const masonryTags = settings.masonry_tags.split("|");

export default Service.extend({
  router: service("router"),

  @discourseComputed("router.currentRouteName")
  isTopicListRoute(currentRouteName) {
    return (
      currentRouteName.match(/^discovery\./) ||
      currentRouteName.match(/^tags?\.show/)
    );
  },

  @discourseComputed("router.currentRouteName")
  isTopicRoute(currentRouteName) {
    return currentRouteName.match(/^topic\./);
  },

  @discourseComputed("router.currentRouteName")
  isDocsRoute(currentRouteName) {
    return currentRouteName.match(/^docs\./);
  },

  @discourseComputed(
    "router.currentRouteName",
    "router.currentRoute.attributes.category.id"
  )
  viewingCategoryId(currentRouteName, categoryId) {
    if (!currentRouteName.match(/^discovery\./)) {
      return;
    }
    return categoryId;
  },

  @discourseComputed(
    "router.currentRouteName",
    "router.currentRoute.attributes.id", // For discourse instances earlier than https://github.com/discourse/discourse/commit/f7b5ff39cf
    "router.currentRoute.attributes.tag.id"
  )
  viewingTagId(currentRouteName, legacyTagId, tagId) {
    if (!currentRouteName.match(/^tags?\.show/)) {
      return;
    }
    return tagId || legacyTagId;
  },

  @discourseComputed(
    "viewingCategoryId",
    "viewingTagId",
    "router.currentRoute.metadata.customThumbnailMode",
    "isTopicListRoute",
    "isTopicRoute",
    "isDocsRoute"
  )
  displayMode(
    viewingCategoryId,
    viewingTagId,
    customThumbnailMode,
    isTopicListRoute,
    isTopicRoute,
    isDocsRoute
  ) {
    if (customThumbnailMode) {
      return customThumbnailMode;
    }
    if (minimalGridCategories.includes(viewingCategoryId)) {
      return "minimal-grid";
    } else if (masonryCategories.includes(viewingCategoryId)) {
      return "masonry";
    } else if (gridCategories.includes(viewingCategoryId)) {
      return "grid";
    } else if (listCategories.includes(viewingCategoryId)) {
      return "list";
    } else if (masonryTags.includes(viewingTagId)) {
      return "masonry";
    } else if (minimalGridTags.includes(viewingTagId)) {
      return "minimal-grid";
    } else if (gridTags.includes(viewingTagId)) {
      return "grid";
    } else if (listTags.includes(viewingTagId)) {
      return "list";
    } else if (isTopicRoute && settings.suggested_topics_mode) {
      return settings.suggested_topics_mode;
    } else if (isTopicListRoute || settings.enable_outside_topic_lists) {
      return settings.default_thumbnail_mode;
    } else if (isDocsRoute) {
      return settings.docs_thumbnail_mode;
    } else {
      return "none";
    }
  },

  @discourseComputed("displayMode")
  enabledForRoute(displayMode) {
    return displayMode !== "none";
  },

  @discourseComputed()
  enabledForDevice() {
    return Site.current().mobileView ? settings.mobile_thumbnails : true;
  },

  @discourseComputed("enabledForRoute", "enabledForDevice")
  shouldDisplay(enabledForRoute, enabledForDevice) {
    return enabledForRoute && enabledForDevice;
  },

  @discourseComputed("shouldDisplay", "displayMode")
  displayMinimalGrid(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "minimal-grid";
  },

  @discourseComputed("shouldDisplay", "displayMode")
  displayList(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "list";
  },

  @discourseComputed("shouldDisplay", "displayMode")
  displayGrid(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "grid";
  },

  @discourseComputed("shouldDisplay", "displayMode")
  displayMasonry(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "masonry";
  },
});
