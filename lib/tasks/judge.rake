# coding: utf-8

namespace :judge do
  JUDGE_DIR = "#{Rails.root}/tmp/judge"
  EASY_SANDBOX_SO = "#{Rails.root}/lib/EasySandbox/EasySandbox.so"

  SUBMISSION_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/submission\..*$/

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


  def result(submission, status=nil)
    result_file = "#{JUDGE_DIR}/submissions/%s/result" % [submission.id]

    if status.nil?
      File.readable?(result_file) and File.read(result_file).strip
    else
      sh "mkdir -p %s" % result_file.pathmap("%d")
      File.open(result_file, "w") do |f|
        f.puts status
      end
    end
  end

  desc "TODO"
  task :submission, [:submission_id] => [:environment] do |t,args|
    submission = Submission.find(args.submission_id)
    Rake::Task["#{JUDGE_DIR}/submissions/%s/submission.finished" % submission.id].invoke
  end

  rule 'submission.prepared' do |t|
    m = t.name.match(SUBMISSION_REGEXP)
    submission = Submission.find(m[:submission_id])
    next if result submission

    submission.update_attribute(:status, "준비중")
    Rake::Task["#{JUDGE_DIR}/problems/%s/bin/judger" % submission.problem.id].invoke
    Rake::Task["#{JUDGE_DIR}/submissions/%s/bin/solver" % submission.id].invoke
    
    submission.problem.system_tests.each do |system_test|
      Rake::Task["#{JUDGE_DIR}/problems/%s/system_tests/%d.in" % [submission.problem.id, system_test.id]].invoke
    end
  end

  rule 'submission.executed' => '.prepared' do |t|
    m = t.name.match(SUBMISSION_REGEXP)
    submission = Submission.find(m[:submission_id])
    next if result submission

    submission.update_attribute(:status, "실행중")
    submission.problem.system_tests.each do |system_test|
      Rake::Task["#{JUDGE_DIR}/submissions/%s/system_tests/%d.out" % [submission.id, system_test.id]].invoke
    end
  end

  rule 'submission.judged' => '.executed' do |t|
    m = t.name.match(SUBMISSION_REGEXP)
    submission = Submission.find(m[:submission_id])
    judger = judger_path(submission.problem.id)

    next if result submission

    status = "정답"

    submission.update_attribute(:status, "채점중")

    submission.problem.system_tests.each do |system_test|
      infile = "#{JUDGE_DIR}/problems/%d/system_tests/%s.in" % [system_test.problem.id, system_test.id]
      outfile = "#{JUDGE_DIR}/submissions/%s/system_tests/%d.out" % [submission.id, system_test.id]

      `#{judger} #{infile} #{outfile}`

      if not $?.success?
        status = "오답"
      end
    end

    if not result submission
      result submission, status
    end
  end

  rule 'submission.finished' => '.judged' do |t|
    m = t.name.match(SUBMISSION_REGEXP)
    submission = Submission.find(m[:submission_id])

    if not result submission
      submission.update_attribute(:status, "결과 없음")
    else
      submission.update_attribute(:status, result(submission))
    end
  end

  rule SOLVER_REGEXP => '.cpp' do |t|
    m = t.name.match(SOLVER_REGEXP)
    submission = Submission.find(m[:submission_id])

    `g++ -o #{t.name} #{t.source} 2>&1`
    if not $?.success?
      result submission, "컴파일 에러"
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

  rule SYSTEM_TEST_OUT_REGEXP => lambda { |fn| [system_test_in_path(fn.pathmap("%n")), EASY_SANDBOX_SO] } do |t|
    m = t.name.match(SYSTEM_TEST_OUT_REGEXP)
    submission = Submission.find(m[:submission_id])

    solver = solver_path(submission.id)
    judger = judger_path(submission.problem.id)

    sh "mkdir -p %s" % t.name.pathmap("%d")

    `echo "ulimit -v 100000; timeout 1 sh -c 'LD_PRELOAD=#{EASY_SANDBOX_SO} #{solver} < #{t.source} > #{t.name}'" | sh`

    if $?.exitstatus != 0
      case $?.exitstatus
      when 124
        result submission, "시간 초과"
      when 137
        result submission, "메모리 초과"
      when 139
        result submission, "실행중 오류"
      else
        result submission, "#{$?.exitstatus} ERROR"
      end
      next
    end

    `sed 1d < #{t.name} > #{t.name}.tmp`
    `mv #{t.name}.tmp #{t.name}`
  end

  rule EASY_SANDBOX_SO do |t|
    Dir.chdir(Rails.root) do
      sh "git submodule init"
      sh "git submodule update"
      sh "make -C %s" % t.name.pathmap("%d")
    end
  end
end
