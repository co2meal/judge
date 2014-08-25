class RenderProblem < Redcarpet::Render::HTML
  def table(header, body)
    '<table class="table">' + header + body + '</table>'
  end
  def codespan(code)
    '<kbd>' + code + '</kbd>'
  end
end