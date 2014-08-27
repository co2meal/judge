class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :problem

  validates :user, presence: true
  validates :problem, presence: true

  scope :accepted, -> { where status: '정답' }

  after_create do
    self.delay.judge!
  end

  def judge!
    #`rake judge:submission[#{id}] --rules`
    `rake judge:submission[#{id}]`
  end
end
