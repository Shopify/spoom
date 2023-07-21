class C1
end

module M1
end

module M2
  include M1
end

module M3
  include M2
end

class C2 < C1
end

class C3 < C2
  include M3
end

class C4 < C3
end

class C5 < C4
end

class S1 < T::Struct; end
