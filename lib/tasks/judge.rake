# coding: utf-8

namespace :judge do
  JUDGE_DIR = "#{Rails.root}/tmp/judge"
  EASY_SANDBOX_SO = "#{Rails.root}/lib/EasySandbox/EasySandbox.so"

  SUBMISSION_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/submission\..*$/
  HACK_REGEXP = /^#{JUDGE_DIR}\/hacks\/(?<hack_id>\d+)\/hack\..*$/

  SOLVER_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver$/
  SOLVER_CODE_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver.cpp$/

  JUDGER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger$/
  JUDGER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger.cpp$/

  CHECKER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker$/
  CHECKER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker.cpp$/

  SYSTEM_TEST_IN_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/system_tests\/(?<system_test_id>\d+).in$/
  SYSTEM_TEST_OUT_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/system_tests\/(?<system_test_id>\d+).out$/

  HACK_IN_REGEXP = /^#{JUDGE_DIR}\/hacks\/(?<hack_id>\d+)\/(?<hack_id>\d+).in$/
  HACK_OUT_REGEXP = /^#{JUDGE_DIR}\/hacks\/(?<hack_id>\d+)\/(?<hack_id>\d+).out$/

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

  def checker_path(problem_id)
    "#{JUDGE_DIR}/problems/%s/bin/checker" % problem_id
  end

  def result(object, status=nil)
    table_name = object.class.table_name
    result_file = "#{JUDGE_DIR}/%s/%s/result" % [table_name, object.id]

    if status.nil?
      File.readable?(result_file) and File.read(result_file).strip
    else
      sh "mkdir -p %s" % result_file.pathmap("%d")
      File.open(result_file, "w") do |f|
        f.puts status
      end
    end
  end

  def run_test(object, solver, infile, outfile)
    sh "mkdir -p %s" % outfile.pathmap("%d")

    `echo "ulimit -v 100000; timeout 1 sh -c 'LD_PRELOAD=#{EASY_SANDBOX_SO} #{solver} < #{infile} > #{outfile}'" | sh`

    if $?.exitstatus != 0
      case $?.exitstatus
      when 124
        result object, "시간 초과"
      when 137
        result object, "메모리 초과"
      when 139
        result object, "실행중 오류"
      else
        result object, "#{$?.exitstatus} ERROR"
      end
      return
    end

    `sed 1d < #{outfile} > #{outfile}.tmp`
    `mv #{outfile}.tmp #{outfile}`
  end

  task :submission, [:submission_id] => [:environment] do |t,args|
    submission = Submission.find(args.submission_id)
    Rake::Task["#{JUDGE_DIR}/submissions/%s/submission.finished" % submission.id].invoke
  end

  task :hack, [:hack_id] => [:environment] do |t,args|
    hack = Hack.find(args.hack_id)
    Rake::Task["#{JUDGE_DIR}/hacks/%s/hack.finished" % hack.id].invoke
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



  rule 'hack.prepared' do |t|
    m = t.name.match(HACK_REGEXP)
    hack = Hack.find(m[:hack_id])
    next if result hack

    hack.update_attribute(:status, "준비중")
    Rake::Task["#{JUDGE_DIR}/problems/%s/bin/judger" % hack.submission.problem.id].invoke
    Rake::Task["#{JUDGE_DIR}/problems/%s/bin/checker" % hack.submission.problem.id].invoke
    Rake::Task["#{JUDGE_DIR}/submissions/%s/bin/solver" % hack.submission.id].invoke
    
    Rake::Task["#{JUDGE_DIR}/hacks/%s/%s.in" % [hack.id, hack.id]].invoke
  end

  rule 'hack.executed' => '.prepared' do |t|
    m = t.name.match(HACK_REGEXP)
    hack = Hack.find(m[:hack_id])
    next if result hack

    hack.update_attribute(:status, "실행중")

    Rake::Task["#{JUDGE_DIR}/hacks/%s/%s.out" % [hack.id, hack.id]].invoke
  end

  rule 'hack.judged' => '.executed' do |t|
    m = t.name.match(HACK_REGEXP)
    hack = Hack.find(m[:hack_id])
    judger = judger_path(hack.submission.problem.id)

    next if result hack

    status = "핵 실패"

    hack.update_attribute(:status, "채점중")

    infile = "#{JUDGE_DIR}/hacks/%s/%s.in" % [hack.id, hack.id]
    outfile = "#{JUDGE_DIR}/hacks/%s/%s.out" % [hack.id, hack.id]

    `#{judger} #{infile} #{outfile}`

    if not $?.success?
      status = "핵 성공"
    end

    if not result hack
      result hack, status
    end
  end

  rule 'hack.finished' => '.judged' do |t|
    m = t.name.match(HACK_REGEXP)
    hack = Hack.find(m[:hack_id])

    if not result hack
      hack.update_attribute(:status, "결과 없음")
    else
      hack.update_attribute(:status, result(hack))
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

    run_test(submission, solver, t.source, t.name)
  end

  rule HACK_IN_REGEXP do |t|
    m = t.name.match(HACK_IN_REGEXP)

    hack = Hack.find(m[:hack_id])

    sh "mkdir -p %s" % t.name.pathmap("%d")

    File.open(t.name, "w") do |f|
      f.write Hack.find(m[:hack_id]).input_data
    end
  end

  rule HACK_OUT_REGEXP => '.in' do |t|
    m = t.name.match(HACK_OUT_REGEXP)

    hack = Hack.find(m[:hack_id])

    solver = solver_path(hack.submission.id)
    judger = judger_path(hack.submission.problem.id)
    checker = checker_path(hack.submission.problem.id)

    # Check

    `#{checker} < #{t.source}`

    if $?.exitstatus != 0
      result hack, "제약조건 오류"
      next
    end

    # Solve
    run_test(hack, solver, t.source, t.name)
  end

  rule EASY_SANDBOX_SO do |t|
    Dir.chdir(Rails.root) do
      sh "git submodule init"
      sh "git submodule update"
      sh "make -C %s" % t.name.pathmap("%d")
    end
  end
end
