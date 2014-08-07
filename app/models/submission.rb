class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :problem

  validates :user, presence: true
  validates :problem, presence: true

  def judge!
    judge_dir = "#{Rails.root}/tmp/judge"
    codefile_path = "#{judge_dir}/#{id}.cpp"
    binfile_path = codefile_path.ext('')

    `mkdir -p #{judge_dir}`

    File.open(codefile_path, "w") do |f|
      f.write code
    end

    compile_output = `#{"g++ %s -o %s 2>&1" % [codefile_path, binfile_path]}`

    if $?.success? == false
      puts 'Compile failed!'
      puts "Compile output is #{compile_output}"
      self.status = "CE"
      save
      return
    end

    exec_output = `ulimit -v 100000; echo "timeout 1 echo 1 2 | #{binfile_path}" | sh 2> /dev/null`

    puts ''
    # puts codefile_path
    # puts binfile_path
    # # puts compile_output
    puts exec_output
    # puts $?.exitstatus
    puts ''

    if $?.exitstatus != 0
      case $?.exitstatus
      when 137
        self.status = "MLE"
      when 139
        self.status = "RTE"
      end
      save
      return
    end



  end
end
