class SystemTest < ActiveRecord::Base
  belongs_to :problem
  validates :problem, presence: true
end
