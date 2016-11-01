require 'ostruct'
require 'optparse'

# Small lib for generating an OptionParser from an OpenStruct
module OptionParserGenerator
  # Special postfixes for Hash keys
  SPECIAL_POSTFIXES = ['--help', '--values', '--short', '--class', '--proc'].freeze

  # Raised when not given an OpenStruct
  class WrongArgumentType < ArgumentError
  end
  # Raised when there are two boolean entries in the OpenStruct
  # one named no_xyz and one xyz
  #
  # only raised when the option :ignore_collisions is not given
  class OptionCollision < ArgumentError
  end

  # utility methods
  # @api private
  module OpenStructExtension
    # extracts a special value from the openstruct
    def special_value(key, string)
      self["#{key}__#{string}"]
    end
  end
  private_constant :OpenStructExtension

  # Does some sanity checks and prepares the OpenStruct
  # @todo preprocess data here instead of doing it adhoc
  # @todo raise more exceptions
  # @api private
  def self.handle_arguments(ostruct)
    unless ostruct.is_a?(OpenStruct)
      raise WrongArgumentType, 'needs an OpenStruct'
    end
    ostruct = ostruct.dup
    ostruct.extend(OpenStructExtension)
    ostruct.freeze # freeze is not needed but makes development easier
  end
  private_class_method :handle_arguments

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
        next if trigger.end_with?(*SPECIAL_POSTFIXES)

        arguments = generate_arguments(defaults, key, val)
        case val
        when FalseClass, TrueClass
          if trigger.start_with?('no-')
            trigger.gsub!(/\Ano-/, '') # removes no- prefixes
            check_collisions(trigger, key, defaults) unless options[:ignore_collisions]
          end
          arguments.unshift "--[no-]#{trigger}"
          block = proc do |bool|
            # inverted when it starts with no_
            key.to_s.start_with?('no_') ^ bool
          end
        else
          arguments.push defaults.special_value(key, 'class') || (val.class.equal?(Fixnum) ? Integer : val.class)
          values = defaults.special_value(key, 'values') || []
          arguments << values if values.any?
          arguments.unshift "--#{trigger}=ARG"
          block = proc do |str|
            str
          end
        end
        if (proc = defaults.special_value(key, 'proc'))
          block = proc
        end
        opts.on(*arguments) do |arg|
          out = opts.instance_variable_get(:@out)
          out[key] = block.call(arg)
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
  end

  # returns an array of helptext and
  # if set the short version of trigger
  # @api private
  def self.generate_arguments(defaults, key, val)
    short = defaults.special_value(key, 'short') || ''
    if short.length > 1
      raise ArgumentError, 'short is too long, it has to be only one character'
    end

    help = "#{defaults.special_value(key, 'help')} (Default: #{val})"

    arguments = [help]
    arguments << "-#{short}" unless short.empty?
    arguments
  end
  private_class_method :generate_arguments

  # @api private
  def self.check_collisions(trigger, key, defaults)
    if defaults.each_pair.map { |v| v.first.to_s }.include?(trigger)
      raise OptionCollision, "on #{key}"
    end
  end
  private_class_method :check_collisions

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
  private_constant :OptParsePatch

  # Shorthand when parsing is only needed once.
  #
  # Generates an OptionParser and calls parse on it
  # @see OptionParserGenerator#[]
  # @return [OpenStruct]
  def self.parse(ostruct, argv, **opt)
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
