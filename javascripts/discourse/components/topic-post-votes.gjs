/* global requirejs */

import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import concatClass from "discourse/helpers/concat-class";
import { i18n } from "discourse-i18n";

const POST_VOTE_CONTROLS_PATHS = [
  "discourse/plugins/discourse-post-voting-reddit-mode/discourse/components/post-votes-vote-controls",
  "discourse/plugins/discourse-post-voting/discourse/components/post-votes-vote-controls",
];

function moduleExists(name) {
  if (typeof requirejs === "undefined") {
    return false;
  }

  if (typeof requirejs.has === "function") {
    return requirejs.has(name);
  }

  return Boolean(requirejs.entries?.[name]);
}

function loadPostVoteControls() {
  for (const path of POST_VOTE_CONTROLS_PATHS) {
    if (!moduleExists(path)) {
      continue;
    }

    try {
      return requirejs(path).default;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn(
        `topic-thumbnails: failed to load post voting controls module at ${path}`,
        e
      );
    }
  }

  return null;
}

const BasePostVotesControls = loadPostVoteControls();

export const hasPostVoteControls = !!BasePostVotesControls;

const circleUpSvg = `<svg class="topic-vote-icon" viewBox="0 0 20 20" aria-hidden="true" focusable="false"><path fill="currentColor" d="M10 19a3.966 3.966 0 01-3.96-3.962V10.98H2.838a1.731 1.731 0 01-1.605-1.073 1.734 1.734 0 01.377-1.895L9.364.254a.925.925 0 011.272 0l7.754 7.759c.498.499.646 1.242.376 1.894-.27.652-.9 1.073-1.605 1.073h-3.202v4.058A3.965 3.965 0 019.999 19zm-7.01-9.821H7.84v5.731c0 1.13.81 2.163 1.934 2.278a2.163 2.163 0 002.386-2.15V9.179h4.851L10 2.163 2.989 9.179z"></path></svg>`;
const circleDownSvg = `<svg class="topic-vote-icon" viewBox="0 0 20 20" aria-hidden="true" focusable="false"><path fill="currentColor" d="M10 1a3.966 3.966 0 013.96 3.962V9.02h3.202c.706 0 1.335.42 1.605 1.073.27.652.122 1.396-.377 1.895l-7.754 7.759a.925.925 0 01-1.272 0l-7.754-7.76a1.734 1.734 0 01-.376-1.894c.27-.652.9-1.073 1.605-1.073h3.202V4.962A3.965 3.965 0 0110 1zm7.01 9.82h-4.85V5.09c0-1.13-.81-2.163-1.934-2.278a2.163 2.163 0 00-2.386 2.15v5.859H2.989l7.01 7.016 7.012-7.016z"></path></svg>`;

class EmptyTopicPostVotes extends Component {
  <template></template>
}

let TopicPostVotesClass;

if (!BasePostVotesControls) {
  TopicPostVotesClass = EmptyTopicPostVotes;
} else {
  TopicPostVotesClass = class TopicPostVotes extends BasePostVotesControls {
    get disableButtons() {
      return this.disabled || this.loading;
    }

    get upvoteButtonClass() {
      return concatClass(
        "topic-vote-button",
        "topic-vote-button--up",
        this.votedUp && "is-active"
      );
    }

    get downvoteButtonClass() {
      return concatClass(
        "topic-vote-button",
        "topic-vote-button--down",
        this.votedDown && "is-active"
      );
    }

    get upIcon() {
      return htmlSafe(circleUpSvg);
    }

    get downIcon() {
      return htmlSafe(circleDownSvg);
    }

    @action
    handleVote(direction, event) {
      event?.preventDefault();
      event?.stopPropagation();

      if (this.disableButtons) {
        return;
      }

      if (
        (direction === "up" && this.votedUp) ||
        (direction === "down" && this.votedDown)
      ) {
        return this.removeVote(direction);
      }

      return this.vote(direction);
    }

    <template>
      <div class="topic-votes__stack">
        <button
          type="button"
          class={{this.upvoteButtonClass}}
          disabled={{this.disableButtons}}
          aria-label={{i18n "topic_thumbnails.votes.upvote"}}
          {{on "click" (fn this.handleVote "up")}}
        >
          {{this.upIcon}}
        </button>

        <span class="topic-vote-count">
          {{this.count}}
        </span>

        <button
          type="button"
          class={{this.downvoteButtonClass}}
          disabled={{this.disableButtons}}
          aria-label={{i18n "topic_thumbnails.votes.downvote"}}
          {{on "click" (fn this.handleVote "down")}}
        >
          {{this.downIcon}}
        </button>
      </div>
    </template>
  };
}

export default TopicPostVotesClass;
