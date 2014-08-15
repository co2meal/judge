
namespace :judge do
  JUDGE_DIR = "#{Rails.root}/tmp/judge"
  SOLVER_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver$/
  SOLVER_CODE_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver.cpp$/

  JUDGER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger$/
  JUDGER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger.cpp$/

  CHECKER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker$/
  CHECKER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker.cpp$/

  SYSTEM_TEST_IN_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/system_tests\/(?<system_test_id>\d+).in$/
  SYSTEM_TEST_OUT_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/system_tests\/(?<system_test_id>\d+).out$/

  # SOLVER_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver$/

  def system_test_in_path(system_test_id)
    system_test = SystemTest.find(system_test_id)    
    "#{JUDGE_DIR}/problems/%d/system_tests/%s.in" % [system_test.problem.id, system_test_id]
  end

  def solver_path(submission_id)
    "#{JUDGE_DIR}/submissions/%s/bin/solver" % submission_id
  end

  def judger_path(problem_id)
    "#{JUDGE_DIR}/problems/%s/bin/judger" % problem_id
  end


  desc "TODO"
  task :submission, [:submission_id] => [:environment] do |t,args|
    submission = Submission.find(args.submission_id)
    Rake::Task["#{JUDGE_DIR}/problems/%s/bin/judger" % submission.problem.id].invoke
    Rake::Task["#{JUDGE_DIR}/submissions/%s/bin/solver" % submission.id].invoke
    submission.problem.system_tests.each do |system_test|
      Rake::Task["#{JUDGE_DIR}/problems/%s/system_tests/%d.in" % [submission.problem.id, system_test.id]].invoke
      Rake::Task["#{JUDGE_DIR}/submissions/%s/system_tests/%d.out" % [submission.id, system_test.id]].invoke
    end
  end

  rule SOLVER_REGEXP => '.cpp' do |t|
    m = t.name.match(SOLVER_REGEXP)
    submission = Submission.find(m[:submission_id])

    submission.update_attribute(:status, "Compiling")
    `g++ -o #{t.name} #{t.source} 2>&1`
    if $?.success?
      submission.update_attribute(:status, "Compile Success")
    else
      submission.update_attribute(:status, "Compile Error")
    end
  end

  rule SOLVER_CODE_REGEXP do |t|
    m = t.name.match(SOLVER_CODE_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write Submission.find(m[:submission_id]).code
    end
  end

  rule JUDGER_REGEXP => '.cpp' do |t|
    `g++ -o #{t.name} #{t.source} 2>&1`
  end

  rule JUDGER_CODE_REGEXP do |t|
    m = t.name.match(JUDGER_CODE_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write Problem.find(m[:problem_id]).judge_code
    end
  end

  rule CHECKER_REGEXP => '.cpp' do |t|
    `g++ -o #{t.name} #{t.source} 2>&1`
  end

  rule CHECKER_CODE_REGEXP do |t|
    m = t.name.match(CHECKER_CODE_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write Problem.find(m[:problem_id]).check_code
    end
  end

  rule SYSTEM_TEST_IN_REGEXP do |t|
    m = t.name.match(SYSTEM_TEST_IN_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write SystemTest.find(m[:system_test_id]).input_data
    end
  end

  rule SYSTEM_TEST_OUT_REGEXP => lambda { |fn| system_test_in_path(fn.pathmap("%n")) } do |t|
    m = t.name.match(SYSTEM_TEST_OUT_REGEXP)
    submission = Submission.find(m[:submission_id])
    submission.update_attribute(:status, "testing #{m[:system_test_id]}")

    solver = solver_path(submission.id)
    judger = judger_path(submission.problem.id)

    sh "mkdir -p %s" % t.name.pathmap("%d")

    submission.update_attribute(:status, "Judging")
    `echo "ulimit -v 100000; timeout 1 #{solver} < #{t.source} > #{t.name}" | sh`

    if $?.exitstatus != 0
      case $?.exitstatus
      when 124
        submission.update_attribute(:status, "TLE")
      when 137
        submission.update_attribute(:status, "MLE")
      when 139
        submission.update_attribute(:status, "RTE")
      else
        submission.update_attribute(:status, "Unknown Error")
      end
      return
    end

    `#{judger} #{t.source} #{t.name}`

    if $?.exitstatus == 0
      submission.update_attribute(:status, "OK")    
    else
      submission.update_attribute(:status, "WA")
    end
  end
end
