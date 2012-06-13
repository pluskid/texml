class TeXMLHTMLDoc < TeXMLDoc

  register_renderer(:inline_math) do |math|
    ["<script type='math/tex'>#{math[1]}</script>"]
  end

  register_renderer(:display_math) do |math|
    ["<script type='math/tex; mode=display'>#{math[1]}</script>"]
  end


  register_command([:emph, :e], 1, true, style: 'i') do |args, kwargs|
    case kwargs[:style] 
    when 'i'
      ['<i>', args[0], '</i>']
    when 'b'
      ['<b>', args[0], '</b>']
    end
  end

  register_command([:code, :c], 1) do |args, kwargs|
    ["<code>", args[0], "</code>"]
  end

  register_command([:link, :l], 1, true, :text => '') do |args, kwargs|
    ["<a href='", args[0],  "'>", (kwargs[:text].empty? ? args[0] : kwargs[:text]),
      "</a>"]
  end

  register_command([:smiley, :s], 1) do |args, kwargs|
    ["<code>", args[0], "</code>"]
  end

  register_block_command(:code, 0, true, :lang => 'text') do |body, args, kwargs|
    ["<pre lang='lang-#{kwargs[:lang].flatten.join}'>"] + body + ["</pre>"]
  end

  register_block_command(:blockquote, 0, true, :source => '') do |body, args, kwargs|
    html = ["<blockquote>"] + body
    if kwargs[:source].empty?
      html << "</blockquote>"
    else
      html += ["\n<small>", kwargs[:source], "</small></blockquote>"]
    end

    html
  end

  def item_start
    "<li>"
  end
  def item_end
    "</li>"
  end
  def wrap_itemize(elements, opt)
    if opt[:type] == 'unordered'
      ['<ul>', elements, '</ul>']
    else
      ['<ol>', elements, '</ol>']
    end
  end

  def escape_text(text)
    text.gsub('<', '&lt;').
      gsub('>', '&gt;')
  end

  def wrap_paragraph(par)
    ["\n\n<p>\n", par, "\n</p>\n"]
  end
end

