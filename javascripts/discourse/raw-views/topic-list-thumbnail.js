import discourseComputed from "discourse-common/utils/decorators";
import EmberObject from "@ember/object";

export default EmberObject.extend({
  // Make sure to update about.json thumbnail sizes if you change these variables
  displayWidth: 200, 
  responsiveRatios: [1, 1.5, 2],

  @discourseComputed("topic.thumbnails")
  srcSet(thumbnails){
    const srcSetArray = [];

    this.responsiveRatios.forEach(ratio => {      
      const target = ratio * this.displayWidth;
      const match = thumbnails.find(t => t.url && t.max_width === target)
      if(match){
        srcSetArray.push(`${match.url} ${ratio}x`);
      }
    })
    
    if(srcSetArray.length === 0){
      srcSetArray.push(`${this.original.url} 1x`)
    }

    return srcSetArray.join(",")
  },

  @discourseComputed("topic.thumbnails")
  original(thumbnails){
    return thumbnails[0];
  },

  @discourseComputed("original")
  width(original){
    return original.width;
  },
  
  @discourseComputed("original")
  height(original){
    return original.height;
  },

  @discourseComputed("topic.thumbnails")
  fallbackSrc(thumbnails){
    const largeEnough = thumbnails.filter(t => {
      if(!t.url) return false;
      return t.max_width > (this.displayWidth * this.responsiveRatios.lastObject)
    });

    if(largeEnough.lastObject){
      return largeEnough.lastObject.url;
    }

    return this.original.url;
  },

  @discourseComputed("topic")
  url(topic){
    return topic.linked_post_number
      ? topic.urlForPostNumber(topic.linked_post_number)
      : topic.get("lastUnreadUrl");
  },

  @discourseComputed("site.mobileView")
  shouldDisplay(mobile){
    return mobile ? settings.show_thumbnails_mobile : settings.show_thumbnails_desktop;
  }
});