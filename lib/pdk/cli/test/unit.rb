module PDK::CLI
  @test_unit_cmd = @test_cmd.define_command do
    name 'unit'
    usage _('unit [options]')
    summary _('Run unit tests.')

    flag nil, :list, _('list all available unit tests and their descriptions')

    option nil, :tests, _('a comma-separated list of tests to run'), argument: :required do |values|
      OptionValidator.list(values)
    end

    option nil, :runner_options, _('options to pass through to the actual test-runner'), argument: :required

    run do |opts, _args, _cmd|
      require 'pdk/tests/unit'

      PDK::CLI::Util.ensure_in_module!

      report = nil

      if opts[:list]
        examples = PDK::Test::Unit.list
        if examples.empty?
          puts _('No examples found.')
        else
          puts _('Examples:')
          examples.each do |example|
            puts _("%{id}\t%{description}" % { id: example[:id], description: example[:full_description] })
          end
        end
      else
        if opts[:tests]
          tests = opts.fetch(:tests)
        end

        # Note: Reporting may be delegated to the validation tool itself.
        if opts[:'report-file']
          format = opts.fetch(:'report-format', PDK::Report.default_format)
          report = Report.new(opts.fetch(:'report-file'), format)
        end

        PDK::Test::Unit.invoke(tests, report)
      end
    end
  end
end
