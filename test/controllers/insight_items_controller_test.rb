require "test_helper"

class InsightItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:default)
    sign_in_as identities(:member)

    # Enough published insights to spill onto a second page (limit is 12)
    14.times do |n|
      @account.insight_items.create!(
        user: users(:member_user),
        title: "Scroll Insight #{n}",
        description: "Filler insight #{n}",
        audience: :developer,
        status: :published,
        published_at: n.hours.ago
      )
    end
  end

  test "index renders first page of cards with a preload sentinel" do
    get "/#{@account.external_id}/insight_items"

    assert_response :success
    assert_select "#insights_list .card", 12
    assert_select "#insights_next_page[data-controller='infinite-scroll']" do
      assert_select "[data-infinite-scroll-url-value=?], [data-infinite-scroll-url-value]", /page=2/
    end
  end

  test "next page request returns turbo stream that appends cards and advances the sentinel" do
    get "/#{@account.external_id}/insight_items?page=2",
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_select "turbo-stream[action='append'][target='insights_list']" do
      assert_select ".card"
    end
    assert_select "turbo-stream[action='replace'][target='insights_next_page']"
  end

  test "last page's turbo stream leaves an inert sentinel" do
    get "/#{@account.external_id}/insight_items?page=2",
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_select "turbo-stream[action='replace'][target='insights_next_page']" do
      assert_select "[data-controller='infinite-scroll']", false
    end
  end

  test "sentinel preserves active filters in the next page url" do
    get "/#{@account.external_id}/insight_items?audience=developer"

    assert_response :success
    assert_select "#insights_next_page[data-infinite-scroll-url-value*='audience=developer']"
    assert_select "#insights_next_page[data-infinite-scroll-url-value*='page=2']"
  end

  private

  def sign_in_as(identity)
    post session_path, params: { email_address: identity.email_address, password: "password123" }
  end
end
