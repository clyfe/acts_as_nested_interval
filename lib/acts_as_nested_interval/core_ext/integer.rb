# Copyright (c) 2007, 2008 Pythonic Pty Ltd
# http://www.pythonic.com.au/

class Integer
  # Returns modular multiplicative inverse.
  # Examples:
  #   2.inverse(7) # => 4
  #   4.inverse(7) # => 2
  def inverse(m)
    u, v = m, self
    x, y = 0, 1
    while v != 0
      q, r = u.divmod(v)
      x, y = y, x - q * y
      u, v = v, r
    end
    if u.abs == 1
      x < 0 ? x + m : x
    end
  end
end
