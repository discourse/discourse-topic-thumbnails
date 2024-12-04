import { tracked } from "@glimmer/tracking";
import { dependentKeyCompat } from "@ember/object/compat";
import Service, { service } from "@ember/service";
import Site from "discourse/models/site";
import discourseComputed from "discourse-common/utils/decorators";

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

const blogStyleCategories = settings.blog_style_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const minimalGridTags = settings.minimal_grid_tags.split("|");
const listTags = settings.list_tags.split("|");
const gridTags = settings.grid_tags.split("|");
const masonryTags = settings.masonry_tags.split("|");
const blogStyleTags = settings.blog_style_tags.split("|");

export default class TopicThumbnailService extends Service {
  @service router;
  @service discovery;

  @tracked masonryContainerWidth;

  @dependentKeyCompat
  get isTopicListRoute() {
    return this.discovery.onDiscoveryRoute;
  }

  @discourseComputed("router.currentRouteName")
  isTopicRoute(currentRouteName) {
    return currentRouteName.match(/^topic\./);
  }

  @discourseComputed("router.currentRouteName")
  isDocsRoute(currentRouteName) {
    return currentRouteName.match(/^docs\./);
  }

  @dependentKeyCompat
  get viewingCategoryId() {
    return this.discovery.category?.id;
  }

  @dependentKeyCompat
  get viewingTagId() {
    return this.discovery.tag?.id;
  }

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
    } else if (blogStyleCategories.includes(viewingCategoryId)) {
      return "blog-style";
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
    } else if (blogStyleTags.includes(viewingTagId)) {
      return "blog-style";
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
  }

  @discourseComputed("displayMode")
  enabledForRoute(displayMode) {
    return displayMode !== "none";
  }

  @discourseComputed()
  enabledForDevice() {
    return Site.current().mobileView ? settings.mobile_thumbnails : true;
  }

  @discourseComputed("enabledForRoute", "enabledForDevice")
  shouldDisplay(enabledForRoute, enabledForDevice) {
    return enabledForRoute && enabledForDevice;
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayMinimalGrid(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "minimal-grid";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayList(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "list";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayGrid(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "grid";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayMasonry(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "masonry";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayBlogStyle(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "blog-style";
  }

  @discourseComputed("displayMinimalGrid", "displayBlogStyle")
  showLikes(isMinimalGrid) {
    return isMinimalGrid;
  }
}
