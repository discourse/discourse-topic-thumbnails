import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "discourse/float-kit/components/d-menu";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import I18n from "I18n";
import { themePrefix } from "virtual:theme";

export default class TopicViewModeSelector extends Component {
  @service topicThumbnails;

  menuApi = null;

  get showSelector() {
    const tt = this.topicThumbnails;
    return (
      tt?.enabledForRoute &&
      tt?.enabledForDevice &&
      (tt?.availableViewModes?.length || 0) > 1
    );
  }

  get buttonLabel() {
    return I18n.t(themePrefix("topic_thumbnails.view_selector.label"));
  }

  get manualMode() {
    return this.topicThumbnails?.manualDisplayMode || null;
  }

  get activeMode() {
    return this.topicThumbnails?.displayMode || null;
  }

  get modeOptions() {
    const modes = this.topicThumbnails?.availableViewModes || [];
    return modes.map((mode) => ({
      value: mode,
      label: I18n.t(themePrefix(`topic_thumbnails.view_modes.${mode}`), {
        defaultValue: mode,
      }),
      active: this.activeMode === mode,
    }));
  }

  @action
  registerMenu(api) {
    this.menuApi = api;
  }

  @action
  selectMode(mode) {
    if (this.manualMode === mode) {
      this.topicThumbnails?.setManualDisplayMode(null);
    } else {
      this.topicThumbnails?.setManualDisplayMode(mode);
    }
    this.menuApi?.close?.();
  }

  <template>
    {{#if this.showSelector}}
      <DMenu
        @identifier="topic-view-mode-selector"
        @title={{this.buttonLabel}}
        @icon="discourse-table"
        @ariaLabel={{this.buttonLabel}}
        @modalForMobile={{true}}
        @onRegisterApi={{this.registerMenu}}
        @triggerClass="btn-default topic-view-mode-selector__trigger"
        @contentClass="topic-view-mode-selector__content"
      >
        <:content>
          <DropdownMenu class="topic-view-mode-selector__list" as |dropdown|>
            {{#each this.modeOptions as |mode|}}
              <dropdown.item>
                <button
                  type="button"
                  class={{concatClass
                    "topic-view-mode-selector__option"
                    (if mode.active "-active")
                  }}
                  {{on "click" (fn this.selectMode mode.value)}}
                  role="menuitemradio"
                  aria-checked={{if mode.active "true" "false"}}
                >
                  <span>{{mode.label}}</span>
                  {{#if mode.active}}
                    {{icon "check"}}
                  {{/if}}
                </button>
              </dropdown.item>
            {{/each}}
          </DropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
