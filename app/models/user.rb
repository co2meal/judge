class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
  
  has_many :notifications
  has_many :submissions
  has_many :accepted_submissions, -> { accepted }, class_name: 'Submission'
  has_many :accepted_problems, through: :accepted_submissions, source: :problem
  has_many :notes
  has_many :hacks

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def hackable_submissions 
    # Should refer last submission.
    Submission.where(problem_id: self.accepted_problem_ids).where.not(user_id: self.id).not_accepted.released.group(:user_id).select('*, max(id) as id')
    # If you want to get size, use #size.size instead of #count
    # Ex) user.hackable_submissions.size.size

    # If you want to know inclusion, use #include? instead of #exists?
    # Ex) user.hackable_submissions.include? submission
  end
end
