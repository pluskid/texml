class TeXMLDoc
  # register renderer to render a syntax node
  # - name: the symbol for the syntax node name to be rendered
  # - blk: the body of the renderer, which accept two arguments:
  #        - this: the Doc object
  #        - node: the node
  def self.register_renderer(*names, &blk)
    names.each {|name|
      define_method("renderer_#{name}".to_sym, &blk)
    }
  end

  def render_node(node)
    name = node[0]
    renderer = "renderer_#{name}".to_sym
    if !self.respond_to? renderer
      raise SyntaxError, "Unknown renderer for syntax node #{name}"
    end

    self.send(renderer, node)
  end

  ############################################################
  # Built-in renderers
  ############################################################

  # renderer for doc node
  register_renderer(:doc, :par) do |doc|
    doc[1].map { |x| render_node(x) }.join('')
  end

  # renderer for paragraph
  register_renderer(:block) do |blk|
    inside = blk[1]
    if inside[0] == :par
      wrap_paragraph(render_node(inside))
    else
      render_node(inside)
    end
  end
  
  register_renderer(:text) do |text|
    escape_text(text[1])
  end

  register_renderer(:literal) do |text|
    escape_literal(text[1])
  end

  register_renderer(:space) do |space|
    ' '
  end

  # renderer for inline command
  register_renderer(:command, :block_command) do |cmd|
    info = cmd[1]
    name = info[:name]
    if cmd[0] == :command
      cmd_meth = "command_#{name}".to_sym
    else
      cmd_meth = "block_command_#{name}"
    end

    if !self.respond_to? cmd_meth
      raise SyntaxError, "Command not found: #{name}"
    end

    args = info[:args][:args].map { |x| render_node(x) }
    kwargs = Hash.new
    info[:args][:named_args].each { |k,v| kwargs[k] = render_node(v) }

    if cmd[0] == :command
      self.send(cmd_meth, args, kwargs)
    else
      body = render_node(info[:body])
      self.send(cmd_meth, body, args, kwargs)
    end
  end

  # register inline command
  # - name: the symbol for the command name
  # - num_arg: number of arguments should the command get, automatic argument count check is performed
  #         when num_arg >= 0
  # - default_kwargs: default keyword arguments, this is merged with user-specified kwargs before passing
  #         to the block
  # - blk: the block to render the command output. It accept two arguments:
  #         - args: array of arguments
  #         - kwargs: hash of keyword arguments
  #        all the values of the arguments are already rendered
  def self.register_command(name, num_arg, default_kwargs, &blk)
    define_method("command_#{name}".to_sym) do |args, kwargs|
      if num_arg >= 0
        if num_arg != args.size
          raise SyntaxError, "expected #{num_arg} arguments for command #{name}, but got #{args.size}"
        end
        kw = default_kwargs.merge(kwargs)

        self.instance_exec(args, kw, &blk)
      end
    end
  end

  # register block command
  # see register_command for doc of the parameters
  # the blk proc now accept three arguments:
  #   - body: the body of the text block, for verbatim command, the body is not rendered, but
  #           for ordinary block command, the body is already rendered
  #   - args: array of arguments
  #   - kwargs: hash of keyword arguments
  def self.register_block_command(name, num_arg, default_kwargs, &blk)
    define_method("block_command_#{name}".to_sym) do |body, args, kwargs|
      if num_arg >= 0
        if num_arg != args.size
          raise SyntaxError, "expected #{num_arg} arguments for block command #{name}, but got #{args.size}"
        end
        kw = default_kwargs.merge(kwargs)

        self.instance_exec(body, args, kw, &blk)
      end
    end
  end


  register_block_command(:code, 0, {lang: 'text'}) do |body, args, kwargs|
    wrap_code_highlight(body, kwargs)
  end

  ############################################################
  # Helper functions
  ############################################################

  # wrap a paragraph, subclass should override this
  def wrap_paragraph(par)
    "\n\n#{par}\n\n"
  end

  # wrap embedded code highlight
  def wrap_code_highlight(code, info)
    "\n\n#{code}\n\n"
  end

  # escape ordinary text, subclass should override this, e.g. HTML Doc should escape '<' to '&lt;', etc.
  def escape_text(text)
    text
  end

  # escape for literal/verbatim text, usually it should be kept untouched
  def escape_literal(text)
    text
  end
end

class TeXMLHTMLDoc < TeXMLDoc

  register_command(:emph, 1, style: 'i') do |args, kwargs|
    case kwargs[:style] 
    when 'i'
      '<i>' + args[0] + '</i>'
    when 'b'
      '<b>' + args[0] + '</b>'
    end
  end

  def escape_text(text)
    text.gsub('<', '&lt;').
      gsub('>', '&gt;')
  end

  def wrap_paragraph(par)
    "<p>\n" + par.strip + "\n</p>\n"
  end

  def wrap_code_highlight(code, info)
    "<pre class='lang-#{info[:lang]}'>" + code + "</pre>"
  end
end
