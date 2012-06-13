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
  register_renderer(:doc) do |doc|
    collapse_text_nodes doc[1].map { |x| render_node(x) }
  end

  register_renderer(:part) do |part|
    wrap_paragraph(part[1].map {|x| render_node(x)}.join(''))
  end

  register_renderer(:text_span) do |span|
    span[1].map {|x| render_node(x)}.join('')
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
  def self.register_command(names, num_arg, default_kwargs, &blk)
    Array(names).each do |name|
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


  ############################################################
  # Helper functions
  ############################################################
  def collapse_text_nodes(nodes)
    results = Array.new
    prev_texts = Array.new
    nodes.each { |x|
      if x.is_a? String
        prev_texts << x
      else
        if !prev_texts.empty?
          results << prev_texts.join('')
          prev_texts = Array.new
        end
        results << x
      end
    }
    if !prev_texts.empty?
      results << prev_texts.join('')
    end

    if (results.size == 1) && (results[0].is_a? String)
      results[0]
    else
      results
    end
  end

  # wrap a paragraph, subclass should override this
  def wrap_paragraph(par)
    "\n\n#{par}\n\n"
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

