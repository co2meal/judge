class SubmissionsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :show]

  def index
    @submissions = Submission.order('id DESC').page(params[:page])
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

  def show
    # Should authorize!!!!
    @submission = Submission.find(params[:id])
    @hack = @submission.hacks.new
  end

  private

  def submission_param
    params.require(:submission).permit(:code, :problem_id, :scope)
  end
end
