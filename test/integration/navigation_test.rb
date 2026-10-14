require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "anonymous logo opens landing page with public navigation" do
    get root_path
    assert_response :success
    assert_select "a.brand[href='#{root_path}']", count: 1
    get brand_destination
    assert_response :success
    assert_public_navigation
  end

  test "authenticated sidebar and public header logos both open dashboard" do
    login
    get dashboard_path
    assert_select "aside a.brand[href='#{dashboard_path}']", count: 1
    get brand_destination
    assert_response :success
    assert_select "h1", /Merhaba/
    get root_path
    assert_response :success
    assert_select "header a.brand[href='#{dashboard_path}']", count: 1
    get brand_destination
    assert_response :success
    assert_select "h1", /Merhaba/
  end

  test "authenticated landing page replaces signup and login calls to action" do
    login
    get root_path
    assert_response :success
    assert_select "a[href='#{new_session_path}']", count: 0
    assert_select "a[href='#{new_registration_path}']", count: 0
    assert_select "main a[href='#{dashboard_path}']", text: /Çalışma alanına dön/
    assert_select "nav a[href='#{dashboard_path}']", count: 1
  end

  test "logout restores public logo destination and landing calls to action" do
    login
    get dashboard_path
    delete session_path
    assert_redirected_to root_path
    follow_redirect!
    assert_public_navigation
    get brand_destination
    assert_response :success
    assert_public_navigation
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "expired session restores public navigation using server side authentication" do
    login
    travel 12.hours + 1.second do
      get root_path
      assert_response :success
      assert_public_navigation
      get dashboard_path
      assert_redirected_to new_session_path
    end
  end

  private

  def login
    user = create_user
    post session_path, params: { email: user.email, password: "secure-password-123" }
    assert_redirected_to dashboard_path
  end

  def brand_destination
    Nokogiri::HTML(response.body).at_css("a.brand")["href"]
  end

  def assert_public_navigation
    assert_select "a.brand[href='#{root_path}']", count: 1
    assert_select "nav a[href='#{new_session_path}']", text: "Giriş yap"
    assert_select "nav a[href='#{new_registration_path}']", text: "Hesap oluştur"
    assert_select "main a[href='#{new_registration_path}']", text: /Ücretsiz başlayın/
    assert_select "main a[href='#{new_session_path}']", text: "Hesabınıza giriş yapın"
    assert_select "main a[href='#{dashboard_path}']", count: 0
  end
end
