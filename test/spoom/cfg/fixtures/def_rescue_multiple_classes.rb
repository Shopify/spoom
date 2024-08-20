def multiple_rescue_classes
  putts "body"
rescue Foo, Bar => baz
  putts "rescue"
end
