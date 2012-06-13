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
    doc[1].each_with_index.map { |x, i| 
      if i == 0
        render_node(x) 
      else
        wrap_paragraph(render_node(x))
      end
    }
  end

  register_renderer(:text_span) do |doc|
    doc[1].map { |x| render_node(x) }
  end

  register_renderer(:part) do |part|
    part[1].map {|x| render_node(x)}
  end

  register_renderer(:text) do |text|
    Array(escape_text(text[1]))
  end

  register_renderer(:literal) do |text|
    Array(escape_literal(text[1]))
  end

  register_renderer(:space) do |space|
    [' ']
  end

  register_renderer(:newline) do |newline|
    ["\n"]
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

    args = info[:args][:args]
    kwargs = info[:args][:named_args]

    if cmd[0] == :command
      self.send(cmd_meth, args, kwargs)
    else
      body = info[:body]
      self.send(cmd_meth, body, args, kwargs)
    end
  end

  # register inline command
  # - name: the symbol for the command name
  # - num_arg: number of arguments should the command get, automatic argument count check is performed
  #         when num_arg >= 0
  # - render_args: when true, the value of arguments and kwargs are all rendered 
  #         before passing in
  # - default_kwargs: default keyword arguments, this is merged with user-specified kwargs before passing
  #         to the block
  # - blk: the block to render the command output. It accept two arguments:
  #         - args: array of arguments
  #         - kwargs: hash of keyword arguments
  def self.register_command(names, num_arg=-1, render_args=true, default_kwargs={}, &blk)
    Array(names).each do |name|
      define_method("command_#{name}".to_sym) do |args, kwargs|
        if num_arg >= 0
          if num_arg != args.size
            raise SyntaxError, "expected #{num_arg} arguments for command #{name}, but got #{args.size}"
          end

          if render_args
            args, kwargs = render_args(args, kwargs)
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
  #   - body: the body of the text block, for verbatim command
  #   - args: array of arguments
  #   - kwargs: hash of keyword arguments
  def self.register_block_command(name, num_arg=-1, render_args=true, default_kwargs={}, &blk)
    define_method("block_command_#{name}".to_sym) do |body, args, kwargs|
      if num_arg >= 0
        if num_arg != args.size
          raise SyntaxError, "expected #{num_arg} arguments for block command #{name}, but got #{args.size}"
        end

        if render_args
          args, kwargs = render_args(args, kwargs)
          body = render_node(body)
        end

        kw = default_kwargs.merge(kwargs)

        self.instance_exec(body, args, kw, &blk)
      end
    end
  end

  # itemize support
  register_command(:item, 0) do |args, kwargs|
    [:item]
  end
  register_block_command(:itemize, 0, true, :type => 'unordered') do |body, args, kwargs|
    results = []
    first_item = true
    body.flatten.each { |x|
      if x == :item
        if !first_item
          results << item_end
        end
        first_item = false
        results << item_start
      else
        results << x
      end
    }
    results << item_end
    wrap_itemize(results, kwargs)
  end


  ############################################################
  # Helper functions
  ############################################################
  def item_start
    "\n * "
  end
  def item_end
    "\n"
  end
  def wrap_itemize(elements, opt)
    ["\n\n", elements, "\n\n"]
  end

  def render_args(args, kwargs)
    args.map! {|x| render_node(x)}
    kwargs.each {|k,v| kwargs[k] = render_node(v)}
    [args, kwargs]
  end

  # wrap a paragraph, subclass should override this
  def wrap_paragraph(par)
    ["\n\n"] + par + ["\n\n"]
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

