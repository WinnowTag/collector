# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AccountController < ApplicationController
  skip_before_filter :login_required, :except => [:edit]
    
  def edit
    if request.post?
      params[:current_user].delete(:login)
      if current_user.update_attributes(params[:current_user])
        flash[:notice] = "Information updated"
        redirect_to :back
      end
    end
  end
    
  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      self.current_user.logged_in_at = Time.now 
      self.current_user.save
      
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default('')
      flash[:notice] = "Logged in successfully"
    else
      if user = User.find_by_login(params[:login])
        flash[:notice] = "Invalid credentials. Please try again."
      end
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to(:action => 'login')
  end
end
