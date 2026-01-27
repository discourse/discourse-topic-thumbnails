import Component from "@glimmer/component";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import MasonryCalculator from "../../lib/masonry-calculator";

export default class TopicListMasonryStyles extends Component {
  @service topicThumbnails;

  attachResizeObserver = modifier((element) => {
    const topicList = element.closest(".topic-list");

    if (!topicList) {
      // eslint-disable-next-line no-console
      console.error(
        "topic-list-thumbnails resize-observer must be inside a topic-list"
      );
      return;
    }

    this.topicThumbnails.masonryContainerWidth =
      topicList.getBoundingClientRect().width;

    const observer = new ResizeObserver(() => {
      this.topicThumbnails.masonryContainerWidth =
        topicList.getBoundingClientRect().width;
    });
    observer.observe(topicList);

    return () => {
      observer.disconnect();
      this.topicThumbnails.masonryContainerWidth = null;
    };
  });

  get masonryStyle() {
    if (!this.topicThumbnails.displayMasonry) {
      return;
    }

    if (!this.topicThumbnails.masonryContainerWidth) {
      return;
    }

    const calculator = new MasonryCalculator(
      this.topicThumbnails,
      this.args.outletArgs.topics,
      this.topicThumbnails.masonryContainerWidth
    );
    calculator.calculateMasonryLayout();
    return calculator.masonryStyle;
  }

  <template>
    {{#if this.topicThumbnails.displayMasonry}}
      {{! template-lint-disable no-forbidden-elements }}
      <style {{this.attachResizeObserver}}>
        {{this.masonryStyle}}
      </style>
    {{/if}}
  </template>
}
