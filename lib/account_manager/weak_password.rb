class ::String

  def weighted_entropy
    #
    # This is based in part on NIST Special Publication 800-63, but we're going
    # to skip the dictionary part. This doesn't hurt us since it's just a bonus
    # that we won't apply.
    #
    #   * The first character gives you 4 bits.
    #   * Characters 2 through 8 give you 2 bits each.
    #   * Characters 9 through 20 give you 1.5 bits each.
    #   * Characters 21 and above give you 1 bit each.
    #   * You get a 3-bit bonus for using capitals and lowercase
    #   * You get a 3-bit bonus for non-alphabetic characters.
    #

    entropy  = 0
    entropy += 4 if length > 0
    entropy += 3 if match(/[^a-z]/i)
    entropy += 3 if match(/[A-Z]/) && match(/[a-z]/)

    2.upto([ 8, length].min) { entropy += 2   }
    9.upto([20, length].min) { entropy += 1.5 }
    21.upto(length)          { entropy += 1   }

    entropy
  end

  def weak_password?
    weighted_entropy < 25
  end
end
