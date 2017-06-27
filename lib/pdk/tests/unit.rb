require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util/bundler'
require 'json'

module PDK
  module Test
    class Unit
      def self.cmd(_tests)
        # TODO: actually run the tests
        # cmd = 'rake spec'
        # cmd += " #{tests}" if tests
        cmd = 'pwd'
        cmd
      end

      def self.invoke(tests, report = nil)
        PDK::Util::Bundler.ensure_bundle!

        puts _('Running unit tests: %{tests}') % { tests: tests }

        output = PDK::CLI::Exec.execute(cmd(tests))
        report.write(output) if report
      end

      class RspecExecutionError < StandardError
      end

      # List current rspec examples
      # @return array of { :id, :full_description }
      def self.list
        PDK::Util::Bundler.ensure_bundle!
        PDK::Util::Bundler.ensure_binstubs!('rspec-core')

        command_argv = [File.join(PDK::Util.module_root, 'bin', 'rspec'), '--dry-run', '--format', 'json']
        command_argv.unshift('ruby') if Gem.win_platform?
        list_command = PDK::CLI::Exec::Command.new(*command_argv)
        list_command.context = :module
        output = list_command.execute!

        rspec_json_output = JSON.parse(output[:stdout])
        if rspec_json_output['examples'].empty?
          rspec_message = rspec_json_output['messages'][0]
          if rspec_message == 'No examples found.' # rubocop:disable Style/GuardClause
            return []
          else
            raise PDK::CLI::FatalError, _('Unable to enumerate examples. rspec reported: %{message}' % { message: rspec_message })
          end
        else
          examples = []
          rspec_json_output['examples'].each do |example|
            examples << { id: example['id'], full_description: example['full_description'] }
          end
          examples
        end
      rescue JSON::ParserError => e
        raise PDK::CLI::FatalError, _('Failed to parse output from rspec: %{message}' % { message: e.message })
      end
    end
  end
end
