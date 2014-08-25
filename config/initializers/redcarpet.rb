class RenderHTMLWithTable < Redcarpet::Render::HTML
  def table(header, body)
    '<table class="table">' + header + body + '</table>'
  end
end