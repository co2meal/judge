# coding: utf-8

class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :problem

  has_many :hacks

  validates :user, presence: true
  validates :problem, presence: true
  validates :scope, inclusion: %w(public private)

  scope :accepted, -> { where status: '정답' }
  scope :not_accepted, -> { where status: ['오답', '시간 초과', '메모리 초과', '실행중 오류'] }
  scope :released, -> { where scope: 'public' }

  after_create do
    self.delay.judge!
  end

  def judge!
    #`rake judge:submission[#{id}] --rules`
    `rake judge:submission[#{id}]`
  end
end
