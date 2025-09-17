
build:
	gem build -V optsparser_generator.gemspec
install:
	gem install -V optsparser_generator
uninstall:
	gem remove -x optsparser_generator
remove: uninstall
reinstall: uninstall build install

doc:
	yard
test:
	rspec -r spec_helper.rb
style:
	rubocop --config .rubocop_todo.yml
mutant:
	bundle exec mutant run -I lib --require optsparser_generator --use rspec --usage opensource -- 'OptionParserGenerator'
test-githubactions:
	act
