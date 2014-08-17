class NotesController < ApplicationController
   before_action :authenticate_user!, only: [:new, :create, :show]
  def index
  end

  def show
    @problem = Problem.find(params[:problem_id])
    @note = current_user.notes.find_or_initialize_by(problem: @problem)
  end

  def create
    @note = current_user.notes.new(note_param)
    @note.save!
    redirect_to problem_notes_path(@note.problem)
  end

  def update
    @problem = Problem.find(note_param[:problem_id])
    @note = current_user.notes.find_by(problem: @problem)
    @note.update(note_param)

    redirect_to problem_notes_path(@note.problem)
  end

private
  def note_param
    params.require(:note).permit(:content, :problem_id)
 end
end
