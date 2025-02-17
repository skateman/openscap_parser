# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'openscap_parser'
require 'pathname'

require 'minitest/autorun'
require 'shoulda-context'
require 'mocha/minitest'

require 'simplecov'
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

def test(name, &)
  test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
  defined = method_defined? test_name
  raise "#{test_name} is already defined in #{self}" if defined

  if block_given?
    define_method(test_name, &)
  else
    define_method(test_name) do
      flunk "No implementation provided for #{name}"
    end
  end
end

def file_fixture(fixture_name)
  file_fixture_path = './test/fixtures/files'
  path = Pathname.new(File.join(file_fixture_path, fixture_name))

  if path.exist?
    path
  else
    msg = "the directory '%s' does not contain a file named '%s'"
    raise ArgumentError, format(msg, file_fixture_path, fixture_name)
  end
end
