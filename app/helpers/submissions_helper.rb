# coding: utf-8

module SubmissionsHelper
  def status_color(status)
    label_type = "label-default"
    case status
    when "대기중", "준비중"
      label_type = "label-default"
    when "실행중"
    when "채점중"
      label_type = "label-warning"
    when "정답"
      label_type = "label-success"
    when "컴파일 에러"
      label_type = "label-primary"
    when "오답", "시간 초과", "메모리 초과", "실행중 오류"
      label_type = "label-danger"
    end

    res = '<span class="label %s">%s</span>' % [label_type, status]

    return res.html_safe

  end
end
