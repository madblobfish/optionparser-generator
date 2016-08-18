require 'ostruct'
require 'optparse'

# Small lib for generating an OptionParser from an OpenStruct
module OptionParserGenerator
  # raised when not given an OpenStruct
  class WrongArgumentType < ArgumentError
  end
  # raised when there are two boolean entries in the OpenStruct
  # one named no_xyz and one xyz
  # only raised when the option :ignore_collisions is not given
  class OptionCollision < ArgumentError
  end

  # @todo preprocess data here instead of doing it adhoc
  # @todo raise more exceptions
  # @api private
  def self.handle_arguments(ostruct)
    unless ostruct.is_a?(OpenStruct)
      raise WrongArgumentType, 'needs an OpenStruct'
    end
    ostruct.dup.freeze # not needed but makes development easier
  end

  # does the magic
  #
  # @todo write documentation :(
  # @todo split this up
  # @param ostruct [OpenStruct] Default values with special values
  # @param options [Hash]
  # @option options [Boolean] :ignore_collisions ignore bool key collisions @see OptionCollision
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
        arguments << help unless help.empty?
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

  ## patch for OptionParser redefines parse and parse!
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
end
# global shorthand
# alias to OptionParserGenerator[arg, opt]
# @return [OptionParser]
# @see OptionParserGenerator
def OptionParserGenerator(arg, **opt)
  OptionParserGenerator[arg, opt]
end
alias OptParseGen OptionParserGenerator
