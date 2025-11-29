# frozen_string_literal: true

RSpec.describe "Topic Thumbnails", type: :system do
  fab!(:theme) { upload_theme_component }
  fab!(:topics) { Fabricate.times(5, :topic) }
  fab!(:user)

  before { sign_in user }

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

  it "renders topic thumbnails in card style with metadata actions" do
    theme.update_setting(:default_thumbnail_mode, "card-style")
    theme.save!

    visit "/latest"

    expect(page).to have_css(".topic-thumbnails-card-style .topic-card", count: 5)
    expect(page).to have_css(".topic-card__meta-action", text: "Save")
  end
end
