import Component from "@glimmer/component";

export default class InlineUserFeedback extends Component {
  get ratingValue() {
    return this.args.rating ?? 0;
  }

  get hasRating() {
    return this.args.rating !== null && this.args.rating !== undefined;
  }

  get count() {
    return this.args.count ?? 0;
  }

  get hasCount() {
    return this.args.count !== null && this.args.count !== undefined;
  }

  get shouldRender() {
    if (!this.args.shouldRender) {
      return false;
    }

    return this.hasRating || this.hasCount;
  }

  get formattedRating() {
    if (!this.hasRating) {
      return "0";
    }

    const value = Number(this.ratingValue);
    if (!Number.isFinite(value)) {
      return "0";
    }

    if (value === 0) {
      return "0";
    }
    return value.toFixed(1);
  }

  get formattedCount() {
    return this.hasCount ? this.count : 0;
  }

  <template>
    {{#if this.shouldRender}}
      <span class="inline-user-feedback">
        <span class="inline-user-feedback__star">★</span>
        <span class="inline-user-feedback__value">{{this.formattedRating}}</span>
        <span class="inline-user-feedback__count">({{this.formattedCount}})</span>
      </span>
    {{/if}}
  </template>
}
