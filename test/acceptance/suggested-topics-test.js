import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";

acceptance("topic list thumbnails | suggested topics", function () {
  test("list the tags", async function (assert) {
    await visit("/t/280");
    assert.true(
      exists("#suggested-topics .topic-list"),
      "suggested topics is displayed"
    );
    const defaultClassNames = Array.from(
      query("#suggested-topics .topic-list").classList
    );
    assert.false(
      defaultClassNames.some((c) => c.startsWith("topic-thumbnails-")),
      "uses the default view"
    );

    settings.suggested_topics_mode = "masonry";

    await visit("/t/280");
    assert.true(
      exists("#suggested-topics .topic-list"),
      "suggested topics is displayed"
    );
    const newClassNames = Array.from(
      query("#suggested-topics .topic-list").classList
    );
    assert.true(newClassNames.includes("topic-thumbnails-masonry"));
  });
});
