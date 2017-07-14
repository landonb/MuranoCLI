# Last Modified: 2017.07.14 /coding: utf-8
# frozen_string_literal: probably not yet

# Copyright © 2016-2017 Exosite LLC.
# License: MIT. See LICENSE.txt.
#  vim:tw=0:ts=2:sw=2:et:ai

require 'fileutils'
require 'open3'
require 'pathname'
require 'cmd_common'

RSpec.describe 'murano syncup', :cmd, :needs_password do
  include_context "CI_CMD"

  before(:example) do
    @product_name = rname('syncupTestPrd')
    out, err, status = Open3.capture3(capcmd('murano', 'product', 'create', @product_name, '--save'))
    expect(err).to eq('')
    expect(out.chomp).to match(/^[a-zA-Z0-9]+$/)
    expect(status.exitstatus).to eq(0)

    @applctn_name = rname('syncupTestApp')
    out, err, status = Open3.capture3(capcmd('murano', 'app', 'create', @applctn_name, '--save'))
    expect(err).to eq('')
    soln_id = out
    expect(soln_id.chomp).to match(/^[a-zA-Z0-9]+$/)
    expect(status.exitstatus).to eq(0)

    out, err, status = Open3.capture3(capcmd('murano', 'assign', 'set'))
    #expect(out).to a_string_starting_with("Linked product #{@product_name}")
    olines = out.lines
    expect(olines[0].encode!('UTF-8', 'UTF-8')).to eq("Linked ‘#{@product_name}’ to ‘#{@applctn_name}’\n")
    expect(olines[1]).to eq("Created default event handler\n")
    expect(err).to eq('')
    expect(status.exitstatus).to eq(0)
  end
  after(:example) do
    out, err, status = Open3.capture3(capcmd('murano', 'solution', 'delete', @applctn_name))
    expect(out).to eq('')
    expect(err).to eq('')
    expect(status.exitstatus).to eq(0)

    out, err, status = Open3.capture3(capcmd('murano', 'solution', 'delete', @product_name))
    expect(out).to eq('')
    expect(err).to eq('')
    expect(status.exitstatus).to eq(0)
  end

  context "without ProjectFile" do
    before(:example) do
      FileUtils.cp_r(File.join(@testdir, 'spec/fixtures/syncable_content/.'), '.')
      FileUtils.move('assets', 'files')
      FileUtils.mkpath('specs')
      FileUtils.copy(
        File.join(@testdir, 'spec/fixtures/product_spec_files/lightbulb.yaml'),
        'specs/resources.yaml',
      )
    end

    def verify_err_missing_location(err)
      elines = err.lines
      # FIXME/2017-07-13: Why is MurCLI spitting out two skipping-missing
      # messages that indicate the same path being skipped? Shouldn't it
      # just complain about it once?
      expect(elines).to satisfy { |v| elines.length == 2 }
      elines.each do |line|
        expect(line).to start_with("\e[33mSkipping missing location ‘")
      end
    end

    it "syncup" do
      out, err, status = Open3.capture3(capcmd('murano', 'syncup'))
      expect(out).to eq('')
      # 2017-07-13: [lb] confused how this was passing but now is not,
      # even though I added the "Skipping missing" text weeks ago....
      #expect(err).to eq('')
      verify_err_missing_location(err)
      expect(status.exitstatus).to eq(0)

      out, err, status = Open3.capture3(capcmd('murano', 'status'))
      #expect(out).to start_with(%{Adding:\nDeleting:\nChanging:\n})
      #expect(out).to start_with(%{Nothing to add\nNothing to delete\nNothing to change\n})
      expect(out).to start_with(%{Nothing new locally\nNothing new remotely\nNothing that differs\n})
      # Due to timestamp races, there might be modules or services in Changing.
      #expect(err).to eq('')
      verify_err_missing_location(err)
      expect(status.exitstatus).to eq(0)
    end
  end

  # TODO: With ProjectFile
  # TODO: With Solutionfile 0.2.0
  # TODO: With Solutionfile 0.3.0
end

