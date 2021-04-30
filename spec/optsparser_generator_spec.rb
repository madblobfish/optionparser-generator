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
    expect(OptionParserGenerator).to eql(OptParseGen)
  end

  it 'should modify the OptionParser to return an OpenStruct' do
    expect(OptParseGen(OpenStruct.new).parse).to eq(OpenStruct.new)
    expect(OptParseGen(OpenStruct.new).parse!([])).to eq(OpenStruct.new)
  end

  it 'should take an OpenStruct and return an OptionParser' do
    expect(OptParseGen(OpenStruct.new)).to be_a(OptionParser)
  end

  it 'should take an descendant of OpenStruct and return an OptionParser' do
    class OpenStructDescendant < OpenStruct
    end
    expect(OptParseGen(OpenStructDescendant.new)).to be_a(OptionParser)
  end

  it 'parse and parse! should return the defaults if not overridden' do
    expect(OptParseGen.parse(os, [])).to eq(os)
    expect(OptParseGen.parse!(os, [])).to eq(os)
  end

  context 'parse & parse!' do
    # modification safety
    it 'should not modify the defaults' do
      ostruct = OpenStruct.new
      ostruct.val = 123
      optparser = OptParseGen(ostruct)
      expect(optparser.parse(['--val=1']).val).to eq(1)
      expect(optparser.parse([]).val).to eq(123)
      expect(optparser.parse(['--val=3']).val).to eq(3)
      expect(optparser.parse([]).val).to eq(123)
      expect(ostruct.val).to eq(123)
    end

    it 'should not take in later modifications of the input OpenStruct' do
      ostruct = OpenStruct.new
      ostruct.val = 123
      optparser = OptParseGen(ostruct)
      ostruct.val = 12
      expect(optparser.parse([]).val).to eq(123)
    end
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
      expect{ OptParseGen(obj) }.to raise_error(
        OptionParserGenerator::WrongArgumentType,
        'needs an OpenStruct'
      )
    end
  end

  # general workings
  it 'should not generate triggers for the special values' do
    ostruct = OpenStruct.new
    ostruct.val = 1
    ostruct.val__help = 'help'
    ostruct.val__values = [1, 2, 3]
    ostruct.val__short = 's'
    ostruct.val__proc = 'too lazy'
    optparser = OptParseGen(ostruct)
    OptParseGen::SPECIAL_POSTFIXES.each do |post|
      expect{ optparser.parse(["--val#{post}"]) }.to raise_error(OptionParser::InvalidOption)
    end
  end

  it 'should not prevent correct Invalid Option errors from happening' do
    expect{ OptParseGen(OpenStruct.new).parse(["--unknown"]) }.to raise_error(OptionParser::InvalidOption)
  end

  it 'should raise an error when more than one letter is given to __short' do
    ostruct = OpenStruct.new
    ostruct.bool = true
    ostruct.bool__short = 'lo' # too long
    expect{ OptParseGen(ostruct) }.to raise_error(
      ArgumentError,
      'short is too long, it has to be only one character'
    )
  end

  it 'should should disallow setting other values than in __values' do
    ostruct = OpenStruct.new
    ostruct.int = 12
    ostruct.int__values = [1, 2]
    ostruct.string = 'a'
    ostruct.string__values = %w(a b c)
    ostruct.freeze
    optparser = OptParseGen(ostruct)
    expect{ optparser.parse(['--int=3']) }.to raise_error(OptionParser::InvalidArgument)
    expect{ optparser.parse(['--string=d']) }.to raise_error(OptionParser::InvalidArgument)
  end

  it 'should work with Classes' do
    ostruct = OpenStruct.new
    ostruct.int = 12
    ostruct.int__class = Integer
    ostruct.num = 11
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

  # shorthands for direct parsing
  describe 'OptParseGen' do
    it 'should basically do what OptParseGen[].parse/parse! do' do
      expect(OptParseGen.parse(os, [])).to eq(os)
      expect(OptParseGen.parse!(os, [])).to eq(os)
    end

    it 'should take options' do
      args = [os_collide, []]
      expect(OptParseGen.parse(*args, ignore_collisions: true)).to eq(os_collide)
      expect(OptParseGen.parse!(*args, ignore_collisions: true)).to eq(os_collide)
    end

    it 'should parse arguments' do
      ostruct = os.dup
      ostruct.bool = false
      ostruct.freeze
      expect(OptParseGen.parse(os, ['--no-bool'])).to eq(ostruct)
      expect(OptParseGen.parse!(os, ['--no-bool'])).to eq(ostruct)
    end

    context 'parse' do
      it 'parse should not change the arguments' do
        arr = ['--bool']
        expect{ OptParseGen.parse(os, arr) }.not_to change{ arr }
      end
    end
    context 'parse!' do
      it 'should take and modify ARGV when given no arguments' do
        ostruct = OpenStruct.new
        ostruct.a = true
        stub_const('ARGV', ['-a'])
        expect{ OptParseGen.parse!(ostruct) }.to change{ ARGV }.to([])
      end
    end
  end

  context 'given a boolean default value' do
    it 'should generate triggers --no-X and --X' do
      expect(OptParseGen.parse(os_no, ['--bool']).no_bool).to be_falsy
      expect(OptParseGen.parse(os_no, ['--no-bool']).no_bool).to be_truthy
    end

    it 'should work in general' do
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

    # collisions are when defaults like no_X and X exist
    it 'colliding should be ignored when given :ignore_collisions option' do
      optparser = OptParseGen(os_collide, ignore_collisions: true)
      expect{ optparser.parse(['--no-no-bool']) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'should continue after collision when given :ignore_collisions option' do
      optparser = OptParseGen(os_collide, ignore_collisions: true)
      optparser.parse(['--zz=3'])
      expect{ optparser.parse(['--no-no-bool']) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'should handle colliding no_ on boolean values' do
      expect do
        OptParseGen(os_collide)
      end.to raise_error(OptionParserGenerator::OptionCollision, 'on no_bool')
      expect do
        OptParseGen(os_collide, ignore_collisions: false)
      end.to raise_error(OptionParserGenerator::OptionCollision)
    end
  end

  context 'proc special values' do
    it 'should handle proc special values' do
      ostruct = os.dup
      ostruct.bool__proc = lambda do |bool|
        puts bool
      end
      expect{ OptParseGen.parse(ostruct, ['--bool']) }.to output("true\n").to_stdout
      expect{ OptParseGen.parse(ostruct, ['--no-bool']) }.to output("false\n").to_stdout
    end

    it 'should return values should set the value of the option' do
      ostruct = os.dup
      ostruct.bool__proc = lambda do |_|
        123
      end
      expect(OptParseGen.parse(ostruct, ['--bool']).bool).to eq(123)
    end
  end

  context 'required special values' do
    it 'should raise when a required value is missing' do
      ostruct = OpenStruct.new
      ostruct.bool = true
      ostruct.val = 123
      ostruct.val__required = true
      expect{ OptParseGen.parse(ostruct, ['--bool']) }.to raise_error(
        OptionParser::MissingArgument,
        'missing argument: val'
      )
      expect{ OptParseGen.parse(ostruct, []) }.to raise_error(
        OptionParser::MissingArgument,
        'missing argument: val'
      )
    end

    it 'should not raise when a required value is used' do
      ostruct = OpenStruct.new
      ostruct.bool = true
      ostruct.val = 123
      ostruct.val__required = true
      expect(OptParseGen.parse(ostruct, ['--val=1']).val).to eq(1)
      expect(OptParseGen.parse(ostruct, ['--val=1', '--bool']).val).to eq(1)
    end
  end

  # output interfaces
  context 'predefined output functions' do
    it 'should print usage and exit on --help' do
      expect do
        begin
          OptParseGen.parse(OpenStruct.new, '--help')
          fail
        rescue SystemExit => e
          expect(e.status).to eq(0)
        end
      end.to output("Usage: #{File.basename($PROGRAM_NAME)} [options]\n    -h, --help\n").to_stdout
    end

    it 'should write the default values into help' do
      ostruct = OpenStruct.new # defining it here keeps the string constant
      ostruct.bool = false
      ostruct.bool__short = 'b'
      ostruct.bool__help = 'yes'
      ostruct.int = 12
      ostruct.string = 'yep'
      expect do
        begin
          # also tests the default value for generate_no_help
          OptParseGen.parse(ostruct, '--help', generate_no_help: false)
          fail
        rescue SystemExit => e
          expect(e.status).to eq(0)
        end
      end.to output(
        "Usage: #{File.basename($PROGRAM_NAME)} [options]\n    -b, --[no-]bool                  yes (Default: false)\n        --int=ARG                     (Default: 12)\n        --string=ARG                  (Default: yep)\n    -h, --help\n"
      ).to_stdout
    end
  end

  context 'options' do
    it 'should generate a help trigger unless given the generate_no_help option' do
      optparser = OptParseGen(os, generate_no_help: true)
      expect do
        begin
          optparser.parse(['--help'])
        rescue SystemExit => e
          expect(e.status).to eq(0)
        end
      end.to output("Usage: #{File.basename($PROGRAM_NAME)} [options]\n        --default=ARG                 (Default: value)\n        --val=ARG                     (Default: 123)\n    -b, --[no-]bool                  description of argument (Default: true)\n").to_stdout
    end
  end
end
