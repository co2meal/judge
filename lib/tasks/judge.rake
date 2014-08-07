
namespace :judge do
  JUDGE_DIR = "#{Rails.root}/tmp/judge"
  SOLVER_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver$/
  SOLVER_CODE_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver.cpp$/

  JUDGER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger$/
  JUDGER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/judger.cpp$/

  CHECKER_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker$/
  CHECKER_CODE_REGEXP = /^#{JUDGE_DIR}\/problems\/(?<problem_id>\d+)\/bin\/checker.cpp$/

  # SOLVER_REGEXP = /^#{JUDGE_DIR}\/submissions\/(?<submission_id>\d+)\/bin\/solver$/



  desc "TODO"
  task :compile, [:submission_id] => [:environment] do |t,args|
    submission = Submission.find(args.submission_id)
    Rake::Task["#{JUDGE_DIR}/problems/%s/bin/judger" % submission.problem.id].invoke
    Rake::Task["#{JUDGE_DIR}/submissions/%s/bin/solver" % submission.id].invoke
  end

  rule ".out" => lambda { |fn| fn.ext('.in') } do |t|
    sh "echo #{t.name}"
    sh "echo #{User.first.email}"
  end

  rule SOLVER_REGEXP => '.cpp' do |t|
    m = t.name.match(SOLVER_REGEXP)
    submission = Submission.find(m[:submission_id])

    submission.update_attribute(:status, "Compiling")
    `g++ -o #{t.name} #{t.source} 2>&1`
    if not $?.success?
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
    sh "g++ -o %s %s" % [t.name, t.source]
  end

  rule JUDGER_CODE_REGEXP do |t|
    m = t.name.match(JUDGER_CODE_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write Problem.find(m[:problem_id]).judge_code
    end
  end

  rule CHECKER_REGEXP => '.cpp' do |t|
    sh "g++ -o %s %s" % [t.name, t.source]
  end

  rule CHECKER_CODE_REGEXP do |t|
    m = t.name.match(SOLVER_CODE_REGEXP)
    sh "mkdir -p %s" % t.name.pathmap("%d")
    File.open(t.name, "w") do |f|
      f.write Problem.find(m[:problem_id]).check_code
    end
  end

end
