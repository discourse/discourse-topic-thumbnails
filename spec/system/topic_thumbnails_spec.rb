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
    "compact-style" => "compact",
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

  it "shows metadata actions in compact style" do
    theme.update_setting(:default_thumbnail_mode, "compact-style")
    theme.save!

    visit "/latest"

    expect(page).to have_css(".topic-compact-meta__share", text: "Share")
    expect(page).to have_css(".topic-compact-meta__action--save", text: "Save")
    expect(page).to have_css(".topic-compact-meta__action--report", text: "Report")
  end

  it "allows selecting a manual view from the navigation dropdown" do
    visit "/latest"

    expect(page).to have_css(".topic-view-mode-selector__trigger")
    expect(page).to have_css(".topic-list.topic-thumbnails-grid")

    find(".topic-view-mode-selector__trigger").click
    find(".topic-view-mode-selector__option", text: "List").click

    expect(page).to have_css(".topic-list.topic-thumbnails-list")
  end
end
