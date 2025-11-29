import Component from "@glimmer/component";
import EmberObject, { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import UserInfo from "discourse/components/user-info";
import coldAgeClass from "discourse/helpers/cold-age-class";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import FlagModal from "discourse/components/modal/flag";
import { getAbsoluteURL } from "discourse/lib/get-url";
import { clipboardCopy } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";
import TopicFlag from "discourse/lib/flag-targets/topic-flag";
import { themePrefix } from "virtual:theme";
import { BookmarkFormData } from "discourse/lib/bookmark-form-data";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Bookmark from "discourse/models/bookmark";
import TopicCompactVoteControls from "./topic-compact-vote-controls";

export default class TopicListThumbnail extends Component {
  @service topicThumbnails;
  @service bookmarkApi;
  @service currentUser;
  @service modal;
  @service toasts;

  @tracked bookmarkId;
  @tracked isBookmarkedState = false;
  @tracked isBookmarking = false;

  responsiveRatios = [1, 1.5, 2];

  constructor() {
    super(...arguments);
    this.bookmarkId = this.topic?.bookmark_id;
    this.isBookmarkedState = !!this.topic?.bookmarked;
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

  // Make sure to update about.json thumbnail sizes if you change these variables
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

  <template>
    {{#if this.topicThumbnails.displayCardStyle}}
      <article class="topic-card">
        {{#if this.showCardAuthor}}
          <div class="topic-card__header">
            <UserInfo
              @user={{this.topic.creator}}
              @includeLink={{true}}
              @includeAvatar={{true}}
              @size="small"
              class="topic-card__author"
            />
            <span class="topic-card__activity">
              {{formatDate this.topic.createdAt format="tiny" noTitle="true"}}
              ago
            </span>
          </div>
        {{/if}}

        <h3 class="topic-card__title">
          <a href={{this.url}}>
            {{this.topic.title}}
          </a>
        </h3>

        <a
          href={{this.url}}
          class="topic-card__thumbnail"
          aria-label={{this.topic.title}}
        >
          {{#if this.hasThumbnail}}
            <img
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width="540"
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

        <div class="topic-card__meta">
          <TopicCompactVoteControls @topic={{this.topic}} />
          <span class="topic-card__meta-comments">
            {{dIcon "far-comment"}}
            {{this.commentsCount}}
          </span>
          <span
            role="button"
            tabindex="0"
            class="topic-card__meta-action"
            {{on "click" this.copyTopicLink}}
            {{on "keydown" (fn this.handleActionKeydown this.copyTopicLink)}}
          >
            {{dIcon "share"}}
            {{i18n "post.controls.share_action"}}
          </span>
          <span
            role="button"
            tabindex="0"
            class="topic-card__meta-action"
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
            class="topic-card__meta-action"
            {{on "click" this.reportTopic}}
            {{on "keydown" (fn this.handleActionKeydown this.reportTopic)}}
          >
            {{this.reportLabel}}
          </span>
        </div>
      </article>
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
