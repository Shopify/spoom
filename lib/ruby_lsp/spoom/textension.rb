# typed: false

class Listener
end

class Request
end

class CodeLens < Listener
  @listeners = []

  def initialize
    self.class.listeners.each do |l|
      @external_listeners << T.unsafe(l).new(@uri, @emitter, @message_queue)
    end

    self.class.extensions.each do |ext|
      ext.code_lens_listener(@uri, @emitter, @message_queue)
    end
  end

  def merge_external_listeners_responses!
    @listeners.each do |listener|
      listener.response
    end
  end
end

class Extension
  def code_lens_listener(uri, emitter, message_queue)
    nil
  end
end

class MyExtension < Extension
  def code_lens_listener(uri, emitter, message_queue)
    MyListener.new(uri, emitter, message_queue, **@options)
  end

  class MyListener < Listener
    def initialize()
    end
  end
end

###

class ListenersContext
  attr_reader :code_lens_listeners
  attr_reader :hover_listeners

  def initialize
    @code_lens_listeners = []
    @hover_listeners = []
  end
end

class Server
  def activate_extensions


    extensions = load_extensions
    extensions.each do |ext|
      ext.activate
    end
  end
end

class Extension
  def activate(listeners_context)
    listeners_context.code_lens_listeners << MyCodeLensListener
  end

  def desactivate

  end
end
