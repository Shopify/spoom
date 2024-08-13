class Foo
  def foo; end # error: Missing sig

  foo
# ^^^ error: Method `foo` does not exist

  def bar(x, y); end
        # ^ error: Missing sig

  class Foo
    def foo; end
      # ^^^ error: Method `foo` does not exist

    def bar(x, y); end
             # ^ error: Method `bar` does not exist
  end
end
