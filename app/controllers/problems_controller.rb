class ProblemsController < ApplicationController
  def index
  	@problems = Problem.page(params[:page])
  end
  def show
  	@problem = Problem.find(params[:id])
  end
end
