require_relative '../lib/optsparser_generator.rb'

describe OptionParserGenerator do
  os = OpenStruct.new
  os.default = 'value'
  os.val = 123
  os.val__values = [1, 2, 123]
  os.bool = true
  os.bool__help = 'description of argument'
  os.bool__short = 'b'
  os.freeze

  os_no = OpenStruct.new
  os_no.no_bool = true
  os_no.freeze

  os_collide = OpenStruct.new
  os_collide.bool = true
  os_collide.no_bool = false
  os_collide.zz = 3
  os_collide.freeze

  # general
  it 'should provide OptionParserGenerator and OptParseGen interfaces' do
    expect(method(:OptionParserGenerator)).to eql(method(:OptParseGen))
  end

  it 'should modify the OptionParser to return an OpenStruct' do
    expect(OptParseGen(OpenStruct.new).parse).to eq(OpenStruct.new)
    expect(OptParseGen(OpenStruct.new).parse!([])).to eq(OpenStruct.new)
  end

  it 'should take an OpenStruct and return an OptionParser' do
    expect(OptParseGen(OpenStruct.new)).to be_a(OptionParser)
  end

  it 'parse and parse! should return the defaults if not overridden' do
    expect(OptParseGen(os).parse).to eq(os)
    expect(OptParseGen(os).parse!([])).to eq(os)
  end

  it 'parse and parse! should not modify the defaults!' do
    ostruct = OpenStruct.new
    ostruct.val = 123
    expect(OptParseGen(ostruct).parse(['--val=1']).val).to eq(1)
    expect(OptParseGen(ostruct).parse([]).val).to eq(123)
    expect(OptParseGen(ostruct).parse(['--val=3']).val).to eq(3)
    expect(OptParseGen(ostruct).parse([]).val).to eq(123)
    expect(ostruct.val).to eq(123)
  end

  # agrument handling
  it 'should raise WrongArgumentType when not given an OpenStruct' do
    [
      { a: 1 },
      1,
      'a',
      true,
      false,
      nil,
      Object.new
    ].each do |obj|
      expect { OptParseGen(obj) }.to raise_error(OptionParserGenerator::WrongArgumentType, 'needs an OpenStruct')
    end
  end

  # general workings
  it 'should not generate triggers for the special values' do
    ostruct = OpenStruct.new
    ostruct.val = 1
    ostruct.val__help = 'help'
    ostruct.val__values = [1, 2, 3]
    ostruct.val__short  = 's'
    optparser = OptParseGen(ostruct)
    expect { optparser.parse(['--val--class']) }.to raise_error(OptionParser::InvalidOption)
    expect { optparser.parse(['--val--help']) }.to raise_error(OptionParser::InvalidOption)
    expect { optparser.parse(['--val--values']) }.to raise_error(OptionParser::InvalidOption)
    expect { optparser.parse(['--val--short']) }.to raise_error(OptionParser::InvalidOption)
  end

  it 'should should disallow setting other values than in __values' do
    ostruct = OpenStruct.new
    ostruct.int = 12
    ostruct.int__values = [1, 2]
    ostruct.string = 'a'
    ostruct.string__values = %w(a b c)
    ostruct.freeze
    optparser = OptParseGen(ostruct)
    expect { optparser.parse(['--int=3']) }.to raise_error(OptionParser::InvalidArgument)
    expect { optparser.parse(['--string=d']) }.to raise_error(OptionParser::InvalidArgument)
  end

  it 'should work with Classes' do
    ostruct = OpenStruct.new
    ostruct.int = 12
    ostruct.int__class = Integer
    ostruct.num = 12
    ostruct.num__class = Numeric
    ostruct.regexp = /\s/
    ostruct.regexp__class = Regexp
    ostruct.string = 'yo'
    ostruct.freeze
    optparser = OptParseGen(ostruct)
    expect(optparser.parse(['--int=11']).int).to eq(11).and be_a(Integer)
    expect(optparser.parse(['--int', '11']).int).to eq(11).and be_a(Integer)
    expect(optparser.parse(['--num=11.1']).num).to eq(11.1).and be_a(Numeric)
    expect(optparser.parse(['--regexp=\w']).regexp).to eq(/\w/).and be_a(Regexp)
    expect(optparser.parse(['--regexp=/11.1/']).regexp).to eq(/11.1/).and be_a(Regexp)
    expect(optparser.parse(['--string=bla']).string).to eq('bla').and be_a(String)
  end

  # special booleans
  it 'should define booleans starting with "no_"' do
    optparser = OptParseGen(os_no)
    expect(optparser.parse(['--bool']).no_bool).to be_falsy
    expect(optparser.parse(['--no-bool']).no_bool).to be_truthy
  end

  it 'should define booleans' do
    optparser = OptParseGen(os)
    result = os.dup
    expect(optparser.parse(['-b'])).to eq(result)
    expect(optparser.parse(['--bool'])).to eq(result)
    result.bool = false
    expect(optparser.parse(['--no-bool'])).to eq(result)
    expect(optparser.parse(['--no-bool']).bool).not_to eq(optparser.parse(['--bool']).bool) # just making sure
    result.bool = true
    expect(optparser.parse(['--bool'])).to eq(result)
  end

  it 'should ignore colliding no_ on boolean values when given :ignore_collisions option' do
    OptParseGen(os_collide, ignore_collisions: true)
  end

  it 'should continue after collision when given :ignore_collisions option' do
    optparser = OptParseGen(os_collide, ignore_collisions: true)
    optparser.parse(['--zz=3'])
    expect { optparser.parse(['--no-no-bool']) }.to raise_error(OptionParser::InvalidOption)
  end

  it 'should handle colliding no_ on boolean values' do
    expect do
      OptParseGen(os_collide)
    end.to raise_error(OptionParserGenerator::OptionCollision, 'on no_bool')
    expect do
      OptParseGen(os_collide, ignore_collisions: false)
    end.to raise_error(OptionParserGenerator::OptionCollision)
  end

  # output interfaces
  it 'should print usage and exit on --help' do
    optparser = OptParseGen(OpenStruct.new)
    expect do
      begin
        optparser.parse('--help')
        fail
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end.to output("Usage: #{File.basename($0)} [options]\n    -h, --help\n").to_stdout
  end

  it 'should write the default values into help' do
    ostruct = OpenStruct.new #defining it here keeps the string constant
    ostruct.bool = false
    ostruct.bool__short = 'b'
    ostruct.bool__help = 'yes'
    ostruct.int = 12
    ostruct.string = 'yep'
    optparser = OptParseGen(ostruct)
    expect do
      begin
        optparser.parse('--help')
        fail
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end.to output(
      "Usage: #{File.basename($0)} [options]\n    -b, --[no-]bool                  yes (Default: false)\n        --int=ARG                     (Default: 12)\n        --string=ARG                  (Default: yep)\n    -h, --help\n"
    ).to_stdout
  end
end
