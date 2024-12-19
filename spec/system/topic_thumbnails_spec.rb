# frozen_string_literal: true

RSpec.describe "Topic Thumbnails", type: :system do
  fab!(:theme) { upload_theme_component }
  fab!(:topics) { Fabricate.times(5, :topic) }
  fab!(:user)

  before { sign_in user }

  RSpec.shared_examples "topic thumbnails" do
    {
      "grid" => "grid",
      "minimal-grid" => "minimal",
      "list" => "list",
      "blog-style" => "blog-style-grid",
    }.each do |style, class_name|
      it "renders topic thumbnails in #{style} style" do
        theme.update_setting(:default_thumbnail_mode, style)
        theme.save!

        visit "/latest"

        expect(page).to have_css(".topic-list.topic-thumbnails-#{class_name}")
        expect(page).to have_css(".topic-list-thumbnail", count: 5)
      end
    end

    it "renders topic thumbnails in masonry style" do
      theme.update_setting(:default_thumbnail_mode, "masonry")
      theme.save!

      visit "/latest"

      expect(page).to have_css(".topic-list.topic-thumbnails-masonry")
      expect(page).to have_css(".topic-list-thumbnail", count: 5)

      expect(page).to have_css(".topic-list-item.masonry-0")
    end
  end

  context "with default raw-hbs topic list" do
    before do
      SiteSetting.glimmer_topic_list_mode = "disabled"
    end

    it "is using legacy topic list" do
      visit "/latest"
      expect(page).to have_css(".topic-list.ember-view")
      expect(enabled).to eq(false)
    end

    it_behaves_like "topic thumbnails"
  end

  context "with glimmer topic list" do
    before do
      SiteSetting.glimmer_topic_list_mode = "auto"
    end

    it "is using glimmer topic list" do
      visit "/latest"
      expect(page).to have_css(".topic-list:not(.ember-view)")
    end

    it_behaves_like "topic thumbnails"
  end
end
