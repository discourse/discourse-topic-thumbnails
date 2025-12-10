import { tracked } from "@glimmer/tracking";
import { dependentKeyCompat } from "@ember/object/compat";
import Service, { service } from "@ember/service";
import discourseComputed from "discourse/lib/decorators";
import Site from "discourse/models/site";

const SESSION_STORAGE_KEY = "topic-thumbnails-manual-modes";

const minimalGridCategories = settings.minimal_grid_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const listCategories = settings.list_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const compactCategories = settings.compact_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const cardCategories = settings.card_categories
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
const compactTags = settings.compact_tags.split("|");
const cardTags = settings.card_tags.split("|");
const gridTags = settings.grid_tags.split("|");
const masonryTags = settings.masonry_tags.split("|");
const blogStyleTags = settings.blog_style_tags.split("|");

export default class TopicThumbnailService extends Service {
  @service router;
  @service discovery;

  @tracked masonryContainerWidth;
  @tracked manualSelectionsVersion = 0;

  manualSelections = this.#loadManualSelections();

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

  @dependentKeyCompat
  get isViewingCategory() {
    return !!this.viewingCategoryId;
  }

  @dependentKeyCompat
  get currentContextKey() {
    return "global";
  }

  @discourseComputed("manualSelectionsVersion", "currentContextKey")
  manualDisplayMode() {
    if (!this.currentContextKey) {
      return null;
    }
    return this.manualSelections?.[this.currentContextKey] || null;
  }

  @discourseComputed(
    "viewingCategoryId",
    "viewingTagId",
    "router.currentRoute.metadata.customThumbnailMode",
    "isTopicListRoute",
    "isTopicRoute",
    "isDocsRoute",
    "manualDisplayMode"
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
    if (this.manualDisplayMode) {
      return this.manualDisplayMode;
    }
    if (minimalGridCategories.includes(viewingCategoryId)) {
      return "minimal-grid";
    } else if (blogStyleCategories.includes(viewingCategoryId)) {
      return "blog-style";
    } else if (cardCategories.includes(viewingCategoryId)) {
      return "card-style";
    } else if (masonryCategories.includes(viewingCategoryId)) {
      return "masonry";
    } else if (gridCategories.includes(viewingCategoryId)) {
      return "grid";
    } else if (listCategories.includes(viewingCategoryId)) {
      return "list";
    } else if (compactCategories.includes(viewingCategoryId)) {
      return "compact-style";
    } else if (masonryTags.includes(viewingTagId)) {
      return "masonry";
    } else if (minimalGridTags.includes(viewingTagId)) {
      return "minimal-grid";
    } else if (blogStyleTags.includes(viewingTagId)) {
      return "blog-style";
    } else if (cardTags.includes(viewingTagId)) {
      return "card-style";
    } else if (gridTags.includes(viewingTagId)) {
      return "grid";
    } else if (listTags.includes(viewingTagId)) {
      return "list";
    } else if (compactTags.includes(viewingTagId)) {
      return "compact-style";
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

  @discourseComputed("shouldDisplay", "displayMode")
  displayCompactStyle(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "compact-style";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayCardStyle(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "card-style";
  }

  @discourseComputed("displayMinimalGrid")
  showLikes(isMinimalGrid) {
    return isMinimalGrid;
  }

  get availableViewModes() {
    const allModes = [
      "minimal-grid",
      "grid",
      "masonry",
      "list",
      "blog-style",
      "compact-style",
      "card-style",
    ];
    const settingValue = (settings.view_selector_modes || "").trim();
    if (!settingValue) {
      return allModes;
    }

    const allowed = settingValue
      .split("|")
      .map((m) => m.trim())
      .filter(Boolean);

    const filtered = allModes.filter((mode) => allowed.includes(mode));
    return filtered.length ? filtered : allModes;
  }

  setManualDisplayMode(mode) {
    const contextKey = this.currentContextKey;
    if (!contextKey) {
      return;
    }
    const normalizedMode = mode || null;
    const existing = this.manualSelections?.[contextKey] || null;
    if (existing === normalizedMode) {
      return;
    }

    if (normalizedMode) {
      this.manualSelections = {
        ...this.manualSelections,
        [contextKey]: normalizedMode,
      };
    } else if (this.manualSelections?.[contextKey]) {
      const updated = { ...this.manualSelections };
      delete updated[contextKey];
      this.manualSelections = updated;
    }
    this.manualSelectionsVersion++;
    this.#persistManualSelections();

    if (typeof this.router?.refresh === "function") {
      this.router.refresh();
    }
  }

  #persistManualSelections() {
    if (typeof sessionStorage === "undefined") {
      return;
    }
    try {
      sessionStorage.setItem(
        SESSION_STORAGE_KEY,
        JSON.stringify(this.manualSelections || {})
      );
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn("Failed to persist topic thumbnail manual selection", e);
    }
  }

  #loadManualSelections() {
    if (typeof sessionStorage === "undefined") {
      return {};
    }

    try {
      const raw = sessionStorage.getItem(SESSION_STORAGE_KEY);
      if (!raw) {
        return {};
      }
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === "object") {
        return parsed;
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn("Failed to load topic thumbnail manual selections", e);
    }

    return {};
  }
}
