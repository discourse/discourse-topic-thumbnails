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
    "viewingCategoryId",
    "router.currentRoute.metadata.customThumbnailMode"
  )
  displayMode(viewingCategoryId, customThumbnailMode) {
    if (customThumbnailMode) return customThumbnailMode;

    if (masonryCategories.includes(viewingCategoryId)) {
      return "masonry";
    } else if (gridCategories.includes(viewingCategoryId)) {
      return "grid";
    } else if (listCategories.includes(viewingCategoryId)) {
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
