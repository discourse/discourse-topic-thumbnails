import Component from "@glimmer/component";
import { service } from "@ember/service";
import coldAgeClass from "discourse/helpers/cold-age-class";
import concatClass from "discourse/helpers/concat-class";
import formatDate from "discourse/helpers/format-date";
import dIcon from "discourse-common/helpers/d-icon";

export default class TopicListThumbnail extends Component {
  @service topicThumbnails;

  responsiveRatios = [1, 1.5, 2];

  // Make sure to update about.json thumbnail sizes if you change these variables
  get displayWidth() {
    return this.topicThumbnails.displayList
      ? settings.list_thumbnail_size
      : 400;
  }

  get topic() {
    return this.args.topic;
  }

  get hasThumbnail() {
    return !!this.topic.thumbnails;
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

  get isLandscape() {
    return this.original.width >= this.original.height;
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

  <template>
    <div
      class={{concatClass
        "topic-list-thumbnail"
        (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
      }}
    >
      <a href={{this.url}}>
        {{#if this.hasThumbnail}}
          <img
            class="background-thumbnail"
            src={{this.fallbackSrc}}
            srcset={{this.srcSet}}
            width={{this.width}}
            height={{this.height}}
            loading="lazy"
          />
          <img
            class="main-thumbnail"
            src={{this.fallbackSrc}}
            srcset={{this.srcSet}}
            width={{this.width}}
            height={{this.height}}
            loading="lazy"
          />
        {{else}}
          <div class="thumbnail-placeholder">
            {{dIcon settings.placeholder_icon}}
          </div>
        {{/if}}
      </a>
    </div>

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
