import { getOwner } from "@ember/owner";
import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import discoveryFixture from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("topic thumbnails | tag route integration", function (needs) {
  needs.settings({ tagging_enabled: true });

  needs.pretender((server, helper) => {
    server.get("/tag/1/l/latest.json", () => {
      return helper.response(
        cloneJSON(discoveryFixture["/tag/important/l/latest.json"])
      );
    });
  });

  test("service correctly identifies tag name from route", async function (assert) {
    await visit("/tag/important/1");

    const topicThumbnailsService = getOwner(this).lookup(
      "service:topic-thumbnails"
    );

    assert.strictEqual(
      topicThumbnailsService.viewingTagName,
      "important",
      "viewingTagName returns the tag name (not id) from the route"
    );
  });
});
