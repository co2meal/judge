# coding: utf-8

module SubmissionsHelper
	def status_color(status)
		# '<span class="label-success">AC</span>'.html_safe
		if status == "Pending"
			'<span class="label label-default">대기중</span>'.html_safe # Pending
		elsif status == "준비중\n"
			'<span class="label label-default">준비중</span>'.html_safe # Pending
		elsif status == "실행중\n"
			'<span class="label label-warning">실행중</span>'.html_safe # Compiling
		elsif status == "채점중\n"
			'<span class="label label-warning">채점중</span>'.html_safe # judging
		elsif status == "정답\n"				
			'<span class="label label-success">정답</span>'.html_safe # Accepted
		elsif status == "컴파일 에러\n"
			'<span class="label label-primary">컴파일 에러</span>'.html_safe # Compile Error
		elsif status == "오답\n"
			'<span class="label label-danger">오답</span>'.html_safe # Wrong Answer
		elsif status == "시간 초과\n"
			'<span class="label label-danger">시간 초과</span>'.html_safe # Time Limit Exceeded
		elsif status == "메모리 초과\n"
			'<span class="label label-danger">메모리 초과</span>'.html_safe # Memory Limit Exceeded
		elsif status == "실행중 오류\n"
			'<span class="label label-danger">실행중 오류</span>'.html_safe # Runtime Error
		else
			status
		end
	end
end
