
import { withPluginApi } from "discourse/lib/plugin-api";
import { findRawTemplate } from "discourse/lib/raw-templates";
import { observes } from "discourse-common/utils/decorators";

export default {
  name: "topic-thumbnails-init",
  initialize(){
    withPluginApi("0.8.7", api => this.initWithApi(api));
  },

  initWithApi(api){
    const site = api.container.lookup("site:main");
    // api.modifyClass("component:topic-list-item", {
    //   templateName(){
    //     if(settings.show_thumbnails){
    //       return "list/thumbnail-topic-list-item"
    //     }else{
    //       return "list/topic-list-item";
    //     }
    //   },

    //   // Override the core method, so that we can change the template dynamically
    //   @observes("topic.pinned")
    //   renderTopicListItem() {
    //     const template = findRawTemplate(this.templateName());
    //     if (template) {
    //       this.set("topicListItemContents", template(this).htmlSafe());
    //     }
    //   },
    // });

    console.log("mobile", site.mobileView)
    api.modifyClass("component:topic-list-item", {
      expandPinned: site.mobileView ? settings.show_excerpts_mobile : settings.show_excerpts_desktop
    })


  }
}

