class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :problem

  validates :user, presence: true
  validates :problem, presence: true


  def judge!
    `rake judge:submission[#{id}]`
  end
end
