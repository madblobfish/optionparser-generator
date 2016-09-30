# OptionParser Generator
[![Build Status](https://travis-ci.org/madblobfish/optionparser-generator.svg?branch=master)](https://travis-ci.org/madblobfish/optionparser-generator)
[![Dependency Status](https://gemnasium.com/badges/github.com/madblobfish/optionparser-generator.svg)](https://gemnasium.com/github.com/madblobfish/optionparser-generator)
[![Inline docs](http://inch-ci.org/github/madblobfish/optionparser-generator.svg?branch=master)](http://inch-ci.org/github/madblobfish/optionparser-generator)

Small gem which generates an OptionParser object from an OpenStruct.

# Installation
`gem install optsparser_generator`

# Usage
```ruby
require 'optsparser_generator'
# step one define OpenStruct with default and special values
os = OpenStruct.new
os.default = 'value'
os.val = 123
os.val__values = [1, 1.5, 2, 123]
os.val__class = Numeric
os.bool = true
os.bool__help = 'description of argument'
os.bool__short = 'b'
os.test = "don't know"
os.test_proc = Proc.new do |value|
	puts value
	"some-#{value}-conversion"
end
os.freeze

# step two generate OptionParser
opt_parser = OptParseGen(os)
opt_parser = OptionParserGenerator(os)
opt_parser.parse!(ARGV)
# or parse options directly
OptParseGen.parse(os) # takes ARGV or an array
```

## Special values
* __help  	defines the description for a property
* __values	defines possible values in an Array
* __short 	defines the short trigger
* __class 	defines the Class which OptionParser then tries to coerce to
* __proc 	a Proc which will be executed to compute the value

# Version numbers
I choose two digit version numbers.
The first digit indicates breaking changes.
Second digit increases per release.

Enjoy
