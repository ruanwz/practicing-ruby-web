class RegistrationController < ApplicationController
  skip_before_filter :authenticate_user
  before_filter :ye_shall_not_pass, :except => [:payment]

  def index
    path = case current_user.status
      when "authorized"           then {:action => :edit_profile }
      when "pending_confirmation" then {:action => :update_profile }
      when "confirmed"            then {:action => :payment }
      else library_path
    end

    redirect_to path
  end

  def restart
    current_user.status = "authorized"
    current_user.save

    redirect_to :action => :edit_profile
  end

  def edit_profile
    @user = current_user
  end

  def update_profile
    @user = current_user

    if params[:user]
      if @user.update_attributes(params[:user])
        @user.create_access_token

        RegistrationMailer.email_confirmation(@user).deliver

        @user.update_attribute(:status, "pending_confirmation")
      else
        render :edit_profile
      end
    end
  end

  def confirm_email
    user = User.find_by_access_token(params[:secret])

    if user || current_user.try(:status) == "confirmed"
      user.clear_access_token

      # TODO swtich this to confirmed one we are doing payment processing
      user.update_attribute(:status, "payment_pending")

      return redirect_to(:action => :payment)
    end
  end

  def payment
    # TODO fancy payment stuffs
  end

  private

  def ye_shall_not_pass
    if current_user && current_user.status == "active"
      redirect_to root_path, :notice => "Your account is already setup."
    end
  end
end