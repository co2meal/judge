class Problem < ActiveRecord::Base
  has_and_belongs_to_many :tags
  has_many :system_tests

  validates :judge_code, presence: true
  validates :check_code, presence: true
end