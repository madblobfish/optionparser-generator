require 'ostruct'
require 'optparse'

# Small lib for generating an OptionParser from an OpenStruct
module OptionParserGenerator
  # Raised when not given an OpenStruct
  class WrongArgumentType < ArgumentError
  end
  # Raised when there are two boolean entries in the OpenStruct
  # one named no_xyz and one xyz
  #
  # only raised when the option :ignore_collisions is not given
  class OptionCollision < ArgumentError
  end

  # Does some sanity checks and prepares the OpenStruct
  # @todo preprocess data here instead of doing it adhoc
  # @todo raise more exceptions
  # @api private
  def self.handle_arguments(ostruct)
    unless ostruct.is_a?(OpenStruct)
      raise WrongArgumentType, 'needs an OpenStruct'
    end
    ostruct.dup.freeze # not needed but makes development easier
  end

  # Does the magic
  #
  # @todo write documentation :(
  # @todo split this up
  # @param ostruct [OpenStruct] Default values with special values
  # @param options [Hash]
  # @option options [Boolean] :ignore_collisions ignore bool key collisions see OptionCollision
  def self.[](ostruct, **options)
    defaults = handle_arguments(ostruct)

    optparser = OptionParser.new do |opts|
      defaults.each_pair do |key, val|
        trigger = key.to_s.tr('_', '-')
        next if trigger.end_with?('--help', '--values', '--short', '--class')

        help = "#{defaults["#{key}__help"]} (Default: #{val})"
        values = defaults["#{key}__values"] || []
        short = defaults["#{key}__short"] || ''
        arguments = []
        arguments << help
        arguments << "-#{short}" unless short.empty?
        case val
        when FalseClass, TrueClass
          if trigger.start_with?('no-')
            trigger[0..2] = ''
            if defaults.each_pair.map { |v| v.first.to_s }.include?(trigger) && !options[:ignore_collisions]
              raise OptionCollision, "on #{key}"
            end
          end
          opts.on("--[no-]#{trigger}", *arguments) do |b|
            out = opts.instance_variable_get(:@out)
            out[key] =
              if key.to_s.start_with?('no_')
                !b
              else
                b
              end
          end
        else
          arguments.push defaults["#{key}__class"] || (val.class.equal?(Fixnum) ? Integer : val.class)
          arguments << values if values.any?
          opts.on("--#{trigger}=ARG", *arguments) do |str|
            out = opts.instance_variable_get(:@out)
            out[key] = str
          end
        end
      end

      opts.on('-h', '--help') do
        puts opts
        exit
      end
    end

    # add default values
    optparser.instance_variable_set(:@defaults, defaults)
    optparser.extend(OptParsePatch)
    optparser
  end

  # patch for OptionParser redefines parse and parse!
  # @api private
  module OptParsePatch
    # @return [OpenStruct]
    def parse!(*params)
      @out = @defaults.dup
      super
      @out
    end

    # @return [OpenStruct]
    def parse(*params)
      @out = @defaults.dup
      super
      @out
    end
  end

  # Shorthand when parsing is only needed once.
  #
  # Generates an OptionParser and calls parse on it
  # @see OptionParserGenerator#[]
  # @return [OpenStruct]
  def self.parse(ostruct, argv = nil, **opt)
    self[ostruct, opt].parse(argv)
  end

  # Same as parse, removes parsed elements from argv
  # @see OptionParserGenerator#parse
  # @return [OpenStruct]
  def self.parse!(ostruct, argv = ARGV, **opt)
    self[ostruct, opt].parse!(argv)
  end
end
# Object alias
# @see OptionParserGenerator
OptParseGen = OptionParserGenerator

# rubocop:disable Style/MethodName

# Global shorthand
#
# alias to OptionParserGenerator[arg, opt]
# @return [OptionParser]
# @see OptionParserGenerator
def OptionParserGenerator(arg, **opt)
  OptionParserGenerator[arg, opt]
end
alias OptParseGen OptionParserGenerator

# rubocop:enable Style/MethodName
