module Features
  module SessionHelpers
    def sign_in_as(user)
      visit "/users/sign_in"

      fill_in 'example@gmail.com', :with => user.email
      fill_in '******', :with => user.password

      click_button "Log in"

      login_as(user, :scope => :user)
    end

    def sign_out
      visit root_path
      click_link "Sign out"
    end

    def sign_up_with(user_params)
      visit root_path

      find("a[href='/users/sign_up']").click
      fill_in 'Username', with: user_params[:username]
      fill_in 'Email',    with: user_params[:email]
      fill_in 'Password', with: user_params[:password]
      fill_in 'Password Confirmation', with: user_params[:password_confirmation]

      click_button "SIGN UP"
    end
  end
end