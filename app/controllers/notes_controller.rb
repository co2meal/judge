class NotesController < ApplicationController
   before_action :authenticate_user!, only: [:new, :create, :show]
	def index
	end

	def show
		@problem = Problem.find(params[:problem_id])
		@note = current_user.notes.new
	end

	def create
	@problem = Problem.find(params[:problem_id])
    @note = current_user.submissions.new(note_param)	
    @note.save
    redirect_to submissions_path
	end

private
  def note_param
    params.require(:note).permit(:content, :problem_id)
 end
end
