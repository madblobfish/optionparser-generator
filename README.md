# OptionParser Generator
Small gem which generates an OptionParser object from an OpenStruct.

# Installation
`gem install optsparser_generator`

# Usage
```ruby
require 'optsparser_generator'
# step one define OpenStruct with default values
os = OpenStruct.new
os.default = 'value'
os.val = 123
os.val__values = [1, 1.5, 2, 123]
os.val__class = Numeric
os.bool = true
os.bool__help = 'description of argument'
os.bool__short = 'b'
os.freeze

# step two generate OptionParser
opt_parser = OptParseGen(os)
opt_parser = OptionParserGenerator(os)
```

## Special values
* __help  	defines the description for a property
* __values	defines possible values in an Array
* __short 	defines the short trigger
* __class 	defines the Class which OptionParser then tries to coerce to

# Version numbers
I choose two digit version numbers.
The first digit indicates breaking changes.
Second digit increases per release.


Enjoy
