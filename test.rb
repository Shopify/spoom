# frozen_string_literal: true
# typed: true

class C
  def test(x)
    begin
      true
    rescue
      begin
        false
      rescue
        raise if x
        true
      end
    end
  end
end
