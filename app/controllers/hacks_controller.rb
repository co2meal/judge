class HacksController < ApplicationController
  before_action :authenticate_user!, only: [:create, :show]

  def show
    @hack = Hack.find(params[:id])
  end

  def create
    @submission = Submission.find(params[:submission_id])
    @hack = current_user.hacks.new(hack_param)

    if @hack.save
      redirect_to @submission
    else
      render 'new'
    end
  end

  private

  def hack_param
    params.require(:hack).permit(:input_data, :submission_id)
  end
end
