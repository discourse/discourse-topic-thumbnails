import Service from "@ember/service";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Site from "discourse/models/site";

const listCategories = settings.list_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const gridCategories = settings.grid_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const masonryCategories = settings.masonry_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const listTags = settings.list_tags.split("|");
const gridTags = settings.grid_tags.split("|");
const masonryTags = settings.masonry_tags.split("|");

export default Service.extend({
  router: service("router"),

  @discourseComputed(
    "router.currentRouteName",
    "router.currentRoute.attributes.category.id"
  )
  viewingCategoryId(currentRouteName, categoryId) {
    if (!currentRouteName.match(/^discovery\./)) return;
    return categoryId;
  },

  @discourseComputed(
    "router.currentRouteName",
    "router.currentRoute.attributes.id"
  )
  viewingTagId(currentRouteName, tagId) {
    if (!currentRouteName.match(/^tags?\.show/)) return;
    return tagId;
  },

  @discourseComputed(
    "viewingCategoryId",
    "viewingTagId",
    "router.currentRoute.metadata.customThumbnailMode"
  )
  displayMode(viewingCategoryId, viewingTagId, customThumbnailMode) {
    if (customThumbnailMode) return customThumbnailMode;

    if (masonryCategories.includes(viewingCategoryId)) {
      return "masonry";
    } else if (gridCategories.includes(viewingCategoryId)) {
      return "grid";
    } else if (listCategories.includes(viewingCategoryId)) {
      return "list";
    } else if (masonryTags.includes(viewingTagId)) {
      return "masonry";
    } else if (gridTags.includes(viewingTagId)) {
      return "grid";
    } else if (listTags.includes(viewingTagId)) {
      return "list";
    } else {
      return settings.default_thumbnail_mode;
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
