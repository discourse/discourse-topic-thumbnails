import { htmlSafe } from "@ember/template";

export default class MasonryCalculator {
  masonryTargetColumnWidth = 300;
  gridSpacingPixels = 10;
  masonryTitleSpacePixels = 76;
  masonryDefaultAspect = 1.3;
  masonryMinAspect = 0.7;

  topics;
  masonryContainerWidth;

  constructor(topicThumbnails, topics, masonryContainerWidth) {
    this.topicThumbnails = topicThumbnails;
    this.topics = topics;
    this.masonryContainerWidth = masonryContainerWidth;
  }

  get numColumns() {
    return Math.floor(
      this.masonryContainerWidth / this.masonryTargetColumnWidth
    );
  }

  get columnWidth() {
    return (
      (this.masonryContainerWidth -
        (this.numColumns - 1) * this.gridSpacingPixels) /
      this.numColumns
    );
  }

  calculateMasonryLayout() {
    const numColumns = this.numColumns;
    const gridSpacingPixels = this.gridSpacingPixels;

    const columnHeights = [];
    for (let n = 0; n < numColumns; n++) {
      columnHeights[n] = 0;
    }

    this.topicData = this.topics.map((topic) => {
      // Pick the column with the lowest height
      const smallestColumn = columnHeights.indexOf(Math.min(...columnHeights));

      // Get the height of this topic
      let aspect = this.masonryDefaultAspect;
      if (topic.thumbnails) {
        aspect = topic.thumbnails[0].width / topic.thumbnails[0].height;
      }
      aspect = Math.max(aspect, this.masonryMinAspect);
      const thisHeight =
        this.columnWidth / aspect + this.masonryTitleSpacePixels;

      const dataForTopic = {
        columnIndex: smallestColumn,
        height: thisHeight,
        heightAbove: columnHeights[smallestColumn],
      };

      columnHeights[smallestColumn] += thisHeight + gridSpacingPixels;

      return dataForTopic;
    });

    this.tallestColumn = Math.max(...columnHeights);
  }

  get masonryStyle() {
    return htmlSafe(
      [
        `.topic-list {`,
        `--masonry-num-columns: ${Math.round(this.numColumns)};`,
        `--masonry-grid-spacing: ${this.gridSpacingPixels}px;`,
        `--masonry-tallest-column: ${Math.round(this.tallestColumn)}px;`,
        `--masonry-column-width: ${Math.round(this.columnWidth)}px;`,
        `}`,

        ...this.topicData.map((topicData, index) => {
          return [
            `.masonry-${index} {`,
            `--masonry-column-index: ${topicData.columnIndex};`,
            `--masonry-height: ${Math.round(topicData.height)}px;`,
            `--masonry-height-above: ${Math.round(topicData.heightAbove)}px;`,
            `}`,
          ].join("\n");
        }),
      ].join("\n")
    );
  }
}
