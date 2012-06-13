class TeXMLLaTeXDoc < TeXMLDoc
  register_renderer(:inline_math) do |math|
    ["$#{math[1]}$"]
  end

  register_renderer(:display_math) do |math|
    ["$$#{math[1]}$$"]
  end

  register_command([:emph, :e], 1, true, style: 'i') do |args, kwargs|
    case kwargs[:style] 
    when 'i'
      ['\emph{', args[0], '}']
    when 'b'
      ['\textbf{', args[0], '}']
    end
  end

  register_command([:code, :c], 1) do |args, kwargs|
    ['\texttt{', args[0], '}']
  end

  register_command([:link, :l], 1, true, :text => '') do |args, kwargs|
    ["\\href{#{args[0].flatten.join}}{",
      kwargs[:text].empty? ? args[0] : kwargs[:text],
      "}"]
  end

  register_command([:smiley, :s], 1) do |args, kwargs|
    "\\texttt{#{args[0].flatten.join}}"
  end

  register_block_command(:code, 0) do |body, args, kwargs|
    ['\begin{verbatim}', body, '\end{verbatim}']
  end

  register_block_command(:blockquote, 0, true, :source => '') do |body, args, kwargs|
    result = ['\begin{quote}', body]
    if kwargs[:source].empty?
      result << '\end{quote}'
    else
      result + ['\begin{flushright}', kwargs[:source], '\end{flushright}\end{quote}']
    end
  end

  def item_start
    '\item '
  end
  def item_end
    "\n"
  end
  def wrap_itemize(elements, opt)
    if opt[:type] == 'unordered'
      ['\begin{itemize}', elements, '\end{itemize}']
    else
      ['\begin{enumerate}', elements, '\end{enumerate}']
    end
  end
  def wrap_paragraph(par)
    ["\n\n", par, "\n"]
  end

  def doc_header
    '''\documentclass{article}
    \usepackage{hyperref}
    \usepackage{url}
    \usepackage{xeCJK}
    \usepackage{amsmath}
    \usepackage{amssymb}
    \usepackage{amsthm}

    \setCJKmainfont{STXihei}
    \setmainfont{Linux Biolinum}

    \begin{document}
    '''
  end

  def doc_footer
    '\end{document}'
  end
end
