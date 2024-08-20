# typed: true
# frozen_string_literal: true

extend T::Sig

c = (break :abc if 1.to_s == "" while 1.to_s == "")
T.reveal_type(c) # error: Revealed type: `T.nilable(Symbol)`
