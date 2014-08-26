class SubmissionsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def index
    @submissions = Submission.page(params[:page])
  end

  def new
    @problem = Problem.find(params[:problem_id])
    @submission = current_user.submissions.new(problem: @problem)
  end

  def create
    @problem = Problem.find(params[:problem_id])
    @submission = current_user.submissions.new(submission_param)

    if @submission.save
      redirect_to submissions_path
    else
      render 'new'
    end
  end

  private
  def submission_param
    params.require(:submission).permit(:code, :problem_id)
  end
end
