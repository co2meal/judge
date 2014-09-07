# coding: utf-8

module ProblemsHelper
  def info_for(problem)
    res = ""
    if user_signed_in? and current_user.accepted_problems.exists? problem
      res += '<span class="label label-success">%s</span>' % '정답'
    end

    res.html_safe
  end

  def ratio_for(problem)
    if problem.submissions.count == 0
      '0%'
    else
      '%d %' % (problem.submissions.accepted.count * 100 / problem.submissions.count)
    end
  end
end
