class HomeController < ApplicationController
  def index
  end
  
  def log_in
    session[:user] = "John"
    redirect_to root_url
  end
  
  def log_out
    session[:user] = nil
    redirect_to root_url
  end

end
