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
  os_collide.freeze

  # general
  it 'should provide OptionParserGenerator and OptParseGen interfaces' do
    expect(method(:OptionParserGenerator)).to eq(method(:OptParseGen))
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

  # agrument handling
  it 'should raise WrongArgumentType when not given an OpenStruct' do
    [
      { a: 1 },
      1,
      'a',
      true,
      false,
      Object.new
    ].each do |obj|
      expect { OptParseGen(obj) }.to raise_error(OptionParserGenerator::WrongArgumentType)
    end
  end

  it 'should work with Classes' do
    ostruct = OpenStruct.new
    ostruct.int = 12
    ostruct.int__class = Integer
    ostruct.num = 12
    ostruct.num__class = Numeric
    ostruct.regexp = /\s/
    ostruct.regexp__class = Regexp
    optparser = OptParseGen(ostruct)
    expect(optparser.parse(['--int=11']).int).to eq(11).and be_a(Integer)
    expect(optparser.parse(['--num=11.1']).num).to eq(11.1).and be_a(Numeric)
    expect(optparser.parse(['--regexp=\w']).regexp).to eq(/\w/).and be_a(Regexp)
    expect(optparser.parse(['--regexp=/11.1/']).regexp).to eq(/11.1/).and be_a(Regexp)
  end

  it 'should work with default values' do
  end

  # special booleans
  it 'should define booleans starting with "no_"' do
    optparser = OptParseGen(os_no)
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
  end

  it 'should ignore colliding no_ on boolean values when given :ignore_collisions option' do
    OptParseGen(os_collide, ignore_collisions: true)
  end

  it 'should handle colliding no_ on boolean values' do
    expect { OptParseGen(os_collide) }.to raise_error(OptionParserGenerator::OptionCollision)
  end

  # output interfaces
  it 'should print usage and exit on --help' do
    optparser = OptParseGen(OpenStruct.new)
    expect do
      begin
        optparser.parse('--help')
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end.to output("Usage: #{File.basename($0)} [options]\n    -h, --help\n").to_stdout
  end

  it 'should write the default values into help' do
    ostruct = OpenStruct.new #defining it here keeps the string constant
    ostruct.bool = false
    ostruct.int = 12
    ostruct.string = 'yep'
    optparser = OptParseGen(ostruct)
    expect do
      begin
        optparser.parse('--help')
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end.to output(
      "Usage: rspec [options]\n        --[no-]bool                   (Default: false)\n        --int=ARG                     (Default: 12)\n        --string=ARG                  (Default: yep)\n    -h, --help\n"
    ).to_stdout
  end
end