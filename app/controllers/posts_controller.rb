class PostsController < ApplicationController
  def search
    if params[:query].present?
      @posts = Post.search(params[:query], per_page: 30, page: current_page)
    end
  end

  protected

  helper_method :current_page

  def current_page
    [params[:page].to_i, 1].max
  end
end
