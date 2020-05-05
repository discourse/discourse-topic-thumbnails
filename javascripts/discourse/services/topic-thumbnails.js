import Service from "@ember/service";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Category from "discourse/models/category";

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
    "router.currentRoute.params.category_slug_path_with_id",
    "router.currentRoute.params.slug"
  )
  viewingCategoryId(currentRouteName, categorySlugPathWithId, categorySlug) {
    if (currentRouteName === "discovery.category") {
      return (
        parseInt(categorySlugPathWithId.split("/").lastObject, 10) ||
        Category.findSingleBySlug(categorySlug)
      );
    }
  },

  @discourseComputed("viewingCategoryId")
  displayMode(viewingCategoryId) {
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

  @discourseComputed("site.mobileView")
  enabledForDevice(mobile) {
    return mobile ? settings.mobile_thumbnails : true;
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
