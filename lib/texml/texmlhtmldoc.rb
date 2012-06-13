class TeXMLHTMLDoc < TeXMLDoc

  register_renderer(:inline_math) do |math|
    "<script type='math/tex'>#{math[1]}</script>"
  end

  register_renderer(:display_math) do |math|
    "\n\n<script type='math/tex; mode=display'>#{math[1]}</script>\n\n"
  end


  register_command([:emph, :e], 1, style: 'i') do |args, kwargs|
    case kwargs[:style] 
    when 'i'
      '<i>' + args[0] + '</i>'
    when 'b'
      '<b>' + args[0] + '</b>'
    end
  end

  register_command([:code, :c], 1, {}) do |args, kwargs|
    "<code>#{args[0]}</code>"
  end

  register_command([:link, :l], 1, :text => '') do |args, kwargs|
    "<a href='#{args[0]}'>" + kwargs[:text].empty? ? args[0] : kwargs[:text] +
      "</a>"
  end

  register_command([:smiley, :s], 1, {}) do |args, kwargs|
    "<code>#{args[0]}</code>"
  end

  register_block_command(:code, 0, :lang => 'text') do |body, args, kwargs|
    "\n\n<pre lang='lang-#{kwargs[:lang]}'>#{body}</pre>\n\n"
  end

  register_block_command(:blockquote, 0, :source => '') do |body, args, kwargs|
    html = "<blockquote>#{body}"
    if kwargs[:source].empty?
      html += "</blockquote>"
    else
      html += "\n<small>#{kwargs[:source]}</small>"
    end

    html
  end

  def escape_text(text)
    text.gsub('<', '&lt;').
      gsub('>', '&gt;')
  end

  def wrap_paragraph(par)
    "<p>\n" + par.strip + "\n</p>\n"
  end
end

