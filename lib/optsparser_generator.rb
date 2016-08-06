require 'ostruct'
require 'optparse'

class OptParseGenerator
  def initialize(ostruct)
    @defaults = ostruct.dup.freeze

    @optparser = OptionParser.new do |opts|
      @defaults.each_pair do |key, val|
        trigger = key.to_s.tr('_', '-')
        next if trigger.end_with?('--help', '--values', '--short')
        trigger[0..2] = '' if trigger.start_with?('no-')

        help = @defaults[key.to_s << '__help'] || ''
        help << " (Default: #{val})"
        values = @defaults[key.to_s << '__values'] || []
        short = @defaults[key.to_s << '__short'] || ''
        arguments = []
        arguments << help
        arguments << short unless short.empty?
        case val
        when FalseClass, TrueClass
          opts.on("--[no-]#{trigger}", *arguments) do |b|
            @out[key] =
              if key.to_s.start_with?('no_')
                !b
              else
                b
              end
          end
        else
          arguments << val.class
          arguments << values if values.any?
          opts.on("--#{trigger}=ARGUMENT", *arguments) do |str|
            @out[key] = str
          end
        end
      end
      opts.on('-h', '--help') do
        puts opts
        exit
      end
    end
  end

  def parse!(params)
    @out = @defaults.dup
    @optparser.parse!(params)
    @out
  end

  def method_missing(method_sym, *arguments, &block)
    # TODO: try to copy the methods into this class
    # instead of method_missing hack them
    if @optparser.respond_to?(method_sym)
      @optparser.method(method_sym).call(*arguments, &block)
    end
  end

  def self.respond_to?(method_sym, include_private = false)
    if respond_to?(method_sym, include_private)
      respond_to?(method_sym, include_private)
    else
      @optparser.respond_to?(method_sym, include_private)
    end
  end
end

# tests
# options = OpenStruct.new
# options.no_filter = false
# options.no_filter__help = 'bla bla helP!'
# options.no_filter__short = 'f'
# options.subsitute_new = true
# options.log = 'pa/th'
# options.some_option = 'pa/th'
# options.some_option__help = 'help text'
# options.some_option__values = %w(possible values for some option)
# options.fix_method_names_with_known_ones = true

# optparser = OptParseGenerator.new(options)
# puts optparser.parse!(['--no-filter']).inspect
# puts optparser.parse!(['--log=other/path']).inspect
# optparser.parse!(['--help'])
# puts 'Error: --help did not quit'
