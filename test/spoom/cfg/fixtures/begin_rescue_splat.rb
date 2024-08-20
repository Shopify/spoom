begin
  meth
rescue *untyped_exceptions => e
  T.reveal_type(e) # error: Revealed type: `Exception`
end
