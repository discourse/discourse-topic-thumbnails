import Component from "@glimmer/component";
import EmberObject, { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DropdownMenu from "discourse/components/dropdown-menu";
import UserInfo from "discourse/components/user-info";
import coldAgeClass from "discourse/helpers/cold-age-class";
import concatClass from "discourse/helpers/concat-class";
import categoryLink from "discourse/helpers/category-link";
import dIcon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import FlagModal from "discourse/components/modal/flag";
import { getAbsoluteURL } from "discourse/lib/get-url";
import { clipboardCopy } from "discourse/lib/utilities";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import TopicFlag from "discourse/lib/flag-targets/topic-flag";
import { themePrefix } from "virtual:theme";
import { BookmarkFormData } from "discourse/lib/bookmark-form-data";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Bookmark from "discourse/models/bookmark";
import TopicVoteControls from "./topic-vote-controls";
import DMenu from "discourse/float-kit/components/d-menu";
import InlineUserFeedback from "./inline-user-feedback";

const OVERFLOW_EVENT = "topic-thumbnails:overflow-open";

export default class TopicListThumbnail extends Component {
  topicVoteControlsComponent = TopicVoteControls;
  @service topicThumbnails;
  @service bookmarkApi;
  @service currentUser;
  @service modal;
  @service toasts;

  @tracked bookmarkId;
  @tracked isBookmarkedState = false;
  @tracked isBookmarking = false;
  @tracked isCompactOverflowOpen = false;
  #overflowListener;
  #compactOverflowMenu;

  responsiveRatios = [1, 1.5, 2];

  constructor() {
    super(...arguments);
    this.bookmarkId = this.topic?.bookmark_id;
    this.isBookmarkedState = !!this.topic?.bookmarked;
    this.#overflowListener = (event) => {
      const detail = event?.detail;
      if (detail !== this.#compactOverflowKey()) {
        this.closeOverflowMenus();
      }
    };
    window.addEventListener(OVERFLOW_EVENT, this.#overflowListener);
  }

  willDestroy() {
    super.willDestroy?.();
    window.removeEventListener(OVERFLOW_EVENT, this.#overflowListener);
  }

  get commentsLabel() {
    return "comments";
  }

  get topic() {
    return this.args.topic;
  }

  get hasThumbnail() {
    return !!this.topic.thumbnails;
  }

  get displayWidth() {
    return this.topicThumbnails.displayList ||
      this.topicThumbnails.displayCompactStyle ||
      this.topicThumbnails.displayCardStyle
      ? settings.list_thumbnail_size
      : 400;
  }

  get srcSet() {
    const srcSetArray = [];

    this.responsiveRatios.forEach((ratio) => {
      const target = ratio * this.displayWidth;
      const match = this.topic.thumbnails.find(
        (t) => t.url && t.max_width === target
      );
      if (match) {
        srcSetArray.push(`${match.url} ${ratio}x`);
      }
    });

    if (srcSetArray.length === 0) {
      srcSetArray.push(`${this.original.url} 1x`);
    }

    return srcSetArray.join(",");
  }

  get original() {
    return this.topic.thumbnails[0];
  }

  get width() {
    return this.original.width;
  }

  get height() {
    return this.original.height;
  }

  get fallbackSrc() {
    const largeEnough = this.topic.thumbnails.filter((t) => {
      if (!t.url) {
        return false;
      }
      return t.max_width > this.displayWidth * this.responsiveRatios.lastObject;
    });

    if (largeEnough.lastObject) {
      return largeEnough.lastObject.url;
    }

    return this.original.url;
  }

  get url() {
    return this.topic.get("linked_post_number")
      ? this.topic.urlForPostNumber(this.topic.get("linked_post_number"))
      : this.topic.get("lastUnreadUrl");
  }

  get firstPostUrl() {
    return this.topic.urlForPostNumber(1);
  }

  get shareUrl() {
    const sharePath = this.topic?.shareUrl || this.topic?.url;
    return sharePath ? getAbsoluteURL(sharePath) : null;
  }

  get showCardAuthor() {
    return this.topicThumbnails.displayCardStyle && this.topic?.creator;
  }

  get showCompactAuthor() {
    return this.topicThumbnails.displayCompactStyle && this.topic?.creator;
  }

  get showCategory() {
    return !this.topicThumbnails.isViewingCategory && this.topic?.category;
  }

  get showUserFeedback() {
    return settings.show_user_feedback && this.topic?.creator;
  }

  get isBookmarked() {
    return this.isBookmarkedState;
  }

  get saveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.save"));
  }

  get removeSaveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.remove_saved"));
  }

  get reportLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.report"));
  }

  #compactOverflowKey() {
    return `compact-${this.topic?.id ?? "unknown"}`;
  }

  #announceCompactOverflow() {
    window.dispatchEvent(
      new CustomEvent(OVERFLOW_EVENT, { detail: this.#compactOverflowKey() })
    );
  }

  get compactOverflowIdentifier() {
    return this.#compactOverflowKey();
  }

  get commentsCount() {
    const replies = this.topic.reply_count;
    if (typeof replies === "number" && replies > 0) {
      return replies;
    }

    const posts = this.topic.posts_count;
    if (typeof posts === "number") {
      return Math.max(posts - 1, 0);
    }

    return 0;
  }

  @action
  async copyTopicLink(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.shareUrl) {
      return;
    }

    try {
      await clipboardCopy(this.shareUrl);
      this.toasts.success({
        duration: "short",
        data: { message: i18n("post.controls.link_copied") },
      });
    } catch (error) {
      // clipboard API already surfaces errors
    }
  }

  @action
  handleActionKeydown(callback, event) {
    if (event.key === "Enter" || event.key === " ") {
      callback.call(this, event);
    }
  }

  @action
  async toggleSave(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.currentUser) {
      window.location = "/login";
      return;
    }

    if (this.isBookmarking) {
      return;
    }

    this.isBookmarking = true;
    try {
      if (this.isBookmarked) {
        await this.#removeBookmark();
      } else {
        await this.#createBookmark();
      }
    } finally {
      this.isBookmarking = false;
    }
  }

  async #createBookmark() {
    try {
      const bookmark = Bookmark.createFor(
        this.currentUser,
        "Topic",
        this.topic.id
      );
      const formData = new BookmarkFormData(bookmark);
      const savedData = await this.bookmarkApi.create(formData);
      this.bookmarkId = savedData.id;
      this.topic.bookmarked = true;
      this.isBookmarkedState = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  async #removeBookmark() {
    try {
      if (this.bookmarkId) {
        await this.bookmarkApi.delete(this.bookmarkId);
      } else {
        await ajax(`/t/${this.topic.id}/remove_bookmarks`, { type: "PUT" });
      }
      this.bookmarkId = null;
      this.topic.bookmarked = false;
      this.isBookmarkedState = false;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async reportTopic(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.currentUser) {
      window.location = "/login";
      return;
    }

    let flagModel = this.topic;

    if (!flagModel?.actions_summary) {
      try {
        const response = await ajax(`/t/${this.topic.id}.json`);
        flagModel = EmberObject.create(response);
      } catch (error) {
        popupAjaxError(error);
        return;
      }
    } else {
      flagModel = EmberObject.create(flagModel);
    }

    this.modal.show(FlagModal, {
      model: {
        flagTarget: new TopicFlag(),
        flagModel,
        setHidden: () => {},
      },
    });
  }

  @action
  toggleCompactOverflow(event) {
    event?.preventDefault();
    event?.stopPropagation();
    const willOpen = !this.isCompactOverflowOpen;
    this.closeOverflowMenus();
    if (willOpen) {
      this.isCompactOverflowOpen = true;
      this.#announceCompactOverflow();
    }
  }

  closeOverflowMenus() {
    this.isCompactOverflowOpen = false;
    this.#compactOverflowMenu?.close?.({ focusTrigger: false });
  }

  @action
  overflowShare(event) {
    this.copyTopicLink(event);
    this.closeOverflowMenus();
  }

  @action
  overflowSave(event) {
    this.toggleSave(event);
    this.closeOverflowMenus();
  }

  @action
  overflowReport(event) {
    this.reportTopic(event);
    this.closeOverflowMenus();
  }

  @action
  registerCompactOverflowMenu(menu) {
    this.#compactOverflowMenu = menu;
  }

  @action
  handleCompactOverflowShow() {
    this.isCompactOverflowOpen = true;
    this.#announceCompactOverflow();
  }

  @action
  handleCompactOverflowClose() {
    this.isCompactOverflowOpen = false;
  }

  @action
  handleCardClick(event) {
    const target = event.target;
    const isInteractive = target.closest('a, button, [role="button"], .topic-vote-button, .topic-votes');

    if (!isInteractive) {
      window.location.href = this.firstPostUrl;
    }
  }

  @action
  handleCompactClick(event) {
    const target = event.target;
    const isInteractive = target.closest('a, button, [role="button"], .topic-vote-button, .topic-votes, .d-menu');

    if (!isInteractive) {
      window.location.href = this.firstPostUrl;
    }
  }

  <template>
    {{#if this.topicThumbnails.displayCardStyle}}
      <article class="topic-card" {{on "click" this.handleCardClick}}>
        {{#if this.showCardAuthor}}
          <div class="topic-card__header">
            <div class="topic-card__author topic-author">
              <UserInfo
                @user={{this.topic.creator}}
                @includeLink={{true}}
                @includeAvatar={{true}}
                @size="small"
                class="topic-card__author-user topic-author__user"
              />
              {{#if this.showUserFeedback}}
                <InlineUserFeedback
                  @shouldRender={{true}}
                  @rating={{this.topic.creator.average_rating}}
                  @count={{this.topic.creator.total_trade_count}}
                />
              {{/if}}
              <span class="topic-card__activity topic-author__activity">
                <span
                  class="topic-author__relative-date"
                  style="font-size: inherit; line-height: inherit;"
                >
                  {{formatDate this.topic.createdAt format="tiny" noTitle="true"}}
                </span>
                ago
              </span>
              {{#if this.showCategory}}
                <span class="topic-card__category topic-author__category">
                  {{categoryLink this.topic.category}}
                </span>
              {{/if}}
            </div>
          </div>
        {{/if}}

        <h3 class="topic-card__title">
          {{this.topic.title}}
        </h3>

        {{#if this.hasThumbnail}}
          <div class="topic-card__thumbnail">
            <img
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.displayWidth}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
          </div>
        {{else if this.topic.excerpt}}
          <div class="topic-card__excerpt">
            {{{this.topic.excerpt}}}
          </div>
        {{else}}
          <div class="topic-card__thumbnail">
            <div class="thumbnail-placeholder">
              {{dIcon settings.placeholder_icon}}
            </div>
          </div>
        {{/if}}

        <div class="topic-card__meta topic-meta">
          <this.topicVoteControlsComponent @topic={{this.topic}} />
          <span class="topic-card__meta-comments topic-meta__comments">
            {{dIcon "far-comment"}}
            {{this.commentsCount}}
          </span>
          <div class="topic-card__meta-actions topic-meta__actions">
            <span
              role="button"
              tabindex="0"
              class="topic-card__meta-action topic-meta__action"
              {{on "click" this.copyTopicLink}}
              {{on "keydown" (fn this.handleActionKeydown this.copyTopicLink)}}
            >
              {{dIcon "share"}}
              {{i18n "post.controls.share_action"}}
            </span>
            <span
              role="button"
              tabindex="0"
              class="topic-card__meta-action topic-meta__action"
              {{on "click" this.toggleSave}}
              {{on "keydown" (fn this.handleActionKeydown this.toggleSave)}}
            >
              {{#if this.isBookmarked}}
                {{dIcon "bookmark"}}
              {{else}}
                {{dIcon "far-bookmark"}}
              {{/if}}
            </span>
            <span
              role="button"
              tabindex="0"
              class="topic-card__meta-action topic-meta__action"
              {{on "click" this.reportTopic}}
              {{on "keydown" (fn this.handleActionKeydown this.reportTopic)}}
            >
              {{dIcon "flag"}}
            </span>
          </div>
        </div>
      </article>
    {{else if this.topicThumbnails.displayCompactStyle}}
      <div
        class="topic-thumbnail-compact-link"
        aria-label={{this.topic.title}}
        {{on "click" this.handleCompactClick}}
      >
        <div
          class={{concatClass
            "topic-list-thumbnail"
            (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
          }}
        >
          {{#if this.hasThumbnail}}
            <img
              class="background-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
            <img
              class="main-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
          {{else}}
            <div class="thumbnail-placeholder">
              {{dIcon settings.placeholder_icon}}
            </div>
          {{/if}}
        </div>

        {{#if this.showCompactAuthor}}
          <div class="topic-compact-author topic-author">
            <UserInfo
              @user={{this.topic.creator}}
              @includeLink={{true}}
              @includeAvatar={{true}}
              @size="small"
              class="topic-compact-author__user topic-author__user"
            />
            {{#if this.showUserFeedback}}
              <InlineUserFeedback
                @shouldRender={{true}}
                @rating={{this.topic.creator.average_rating}}
                @count={{this.topic.creator.total_trade_count}}
              />
            {{/if}}
            <span class="topic-compact-author__activity topic-author__activity">
              <span
                class="topic-author__relative-date"
                style="font-size: inherit; line-height: inherit;"
              >
                {{formatDate this.topic.createdAt format="tiny" noTitle="true"}}
              </span>
              ago
            </span>
            {{#if this.showCategory}}
              <span class="topic-compact-author__category topic-author__category">
                {{categoryLink this.topic.category}}
              </span>
            {{/if}}
          </div>
        {{/if}}

        <h3 class="topic-compact__title">
          {{this.topic.title}}
        </h3>

        <div class="topic-compact-meta topic-meta">
          <this.topicVoteControlsComponent @topic={{this.topic}} />
          <span class="topic-compact-meta__comments topic-meta__comments">
            {{this.commentsCount}}
            {{this.commentsLabel}}
          </span>
          <div class="topic-compact-meta__actions topic-meta__actions">
            <span
              role="button"
              tabindex="0"
              class="topic-compact-meta__share topic-meta__action"
              {{on "click" this.copyTopicLink}}
              {{on "keydown" (fn this.handleActionKeydown this.copyTopicLink)}}
            >
              {{i18n "post.controls.share_action"}}
            </span>
            <span
              role="button"
              tabindex="0"
              class="topic-compact-meta__action topic-compact-meta__action--save topic-meta__action"
              {{on "click" this.toggleSave}}
              {{on "keydown" (fn this.handleActionKeydown this.toggleSave)}}
            >
              {{if this.isBookmarked this.removeSaveLabel this.saveLabel}}
            </span>
            <span
              role="button"
              tabindex="0"
              class="topic-compact-meta__action topic-compact-meta__action--report topic-meta__action"
              {{on "click" this.reportTopic}}
              {{on "keydown" (fn this.handleActionKeydown this.reportTopic)}}
            >
              {{this.reportLabel}}
            </span>
          </div>
          <DMenu
            @identifier={{this.compactOverflowIdentifier}}
            @icon="ellipsis"
            @ariaLabel={{i18n "topic_thumbnails.actions.more_actions"}}
            @triggerClass="topic-compact-meta__overflow"
            @modalForMobile={{true}}
            @onRegisterApi={{this.registerCompactOverflowMenu}}
            @onShow={{this.handleCompactOverflowShow}}
            @onClose={{this.handleCompactOverflowClose}}
          >
            <:content>
              <div class="topic-compact-meta__overflow-menu">
                <DropdownMenu as |dropdown|>
                  <dropdown.item>
                    <button
                      type="button"
                      class="topic-compact-meta__overflow-item"
                      {{on "click" this.overflowShare}}
                    >
                      {{dIcon "share"}}
                      {{i18n "post.controls.share_action"}}
                    </button>
                  </dropdown.item>
                  <dropdown.item>
                    <button
                      type="button"
                      class="topic-compact-meta__overflow-item"
                      {{on "click" this.overflowSave}}
                    >
                      {{if this.isBookmarked this.removeSaveLabel this.saveLabel}}
                    </button>
                  </dropdown.item>
                  <dropdown.item>
                    <button
                      type="button"
                      class="topic-compact-meta__overflow-item"
                      {{on "click" this.overflowReport}}
                    >
                      {{dIcon "flag"}}
                      {{this.reportLabel}}
                    </button>
                  </dropdown.item>
                </DropdownMenu>
              </div>
            </:content>
          </DMenu>
        </div>
      </div>
    {{else}}
      <div
        class={{concatClass
          "topic-list-thumbnail"
          (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
        }}
      >
        <a href={{this.url}} role="img" aria-label={{this.topic.title}}>
          {{#if this.hasThumbnail}}
            <img
              class="background-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
            <img
              class="main-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
          {{else}}
            <div class="thumbnail-placeholder">
              {{dIcon settings.placeholder_icon}}
            </div>
          {{/if}}
        </a>
      </div>
    {{/if}}

    {{#if this.topicThumbnails.showLikes}}
      <div class="topic-thumbnail-likes">
        {{dIcon "heart"}}
        <span class="number">
          {{this.topic.like_count}}
        </span>
      </div>
    {{/if}}

    {{#if this.topicThumbnails.displayBlogStyle}}
      <div class="topic-thumbnail-blog-data">
        <div class="topic-thumbnail-blog-data-views">
          {{dIcon "eye"}}
          <span class="number">
            {{this.topic.views}}
          </span>
        </div>
        <div class="topic-thumbnail-blog-data-likes">
          {{dIcon "heart"}}
          <span class="number">
            {{this.topic.like_count}}
          </span>
        </div>
        <div class="topic-thumbnail-blog-data-comments">
          {{dIcon "comment"}}
          <span class="number">
            {{this.topic.reply_count}}
          </span>
        </div>
        <div
          class={{concatClass
            "topic-thumbnail-blog-data-activity"
            "activity"
            (coldAgeClass
              this.topic.createdAt startDate=this.topic.bumpedAt class=""
            )
          }}
          title={{this.topic.bumpedAtTitle}}
        >
          <a class="post-activity" href={{this.topic.lastPostUrl}}>
            {{~formatDate this.topic.bumpedAt format="tiny" noTitle="true"~}}
          </a>
        </div>
      </div>
    {{/if}}
  </template>
}
