require 'spec_helper'
require 'account_manager/password_strength'

describe ::String do

  it 'has a weak_password? method' do
    ::String.method_defined?(:weak_password?).should be true
  end

  it 'has a strong_password? method' do
    ::String.method_defined?(:strong_password?).should be true
  end

  describe '#weak_password?' do
    {
      'aaaaaaaa'            => [ 4+(2*7),              true  ],
      'friendlygh'          => [ 4+(2*7)+(2*1.5),      true  ],
      'aaaaaaaA'            => [ 4+(2*7)+3,            true  ],
      'aaaaaaA5'            => [ 4+(2*7)+3+3,          true  ],
      'jT123456'            => [ 4+(2*7)+3+3,          true  ],
      'bottlerocket'        => [ 4+(2*7)+(4*1.5),      true  ],
      'Very$trong?'         => [ 4+(2*7)+(3*1.5)+3+3,  false ],
      'Boxxy2Boxxy'         => [ 4+(2*7)+(3*1.5)+3+3,  false ],
      'write way more code' => [ 4+(2*7)+(11*1.5)+3,   false ],

      'a really, really, really long one that is just so very long' => [ 4+(2*7)+(12*1.5)+(39*1)+3, false ]
    }.each_pair do |password, entropy_and_weakness|

      entropy = entropy_and_weakness[0]
      weak    = entropy_and_weakness[1]
      it %[%-20s     is %6s] % [password, weak] do
        password.weak_password?.should be weak
      end

      it %[%-20s weighs %6d] % [password, entropy] do
        password.weighted_entropy.should == entropy
      end
    end
  end

  describe '#strong_password?' do
    it 'is the inverse of #weak_password?' do
      'whatever'         .strong_password?.should == !'whatever'         .weak_password?
      'And a strong one!'.strong_password?.should == !'And a strong one!'.weak_password?
    end
  end
end
