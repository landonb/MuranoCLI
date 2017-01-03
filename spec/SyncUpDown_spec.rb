require 'MrMurano/version'
require 'MrMurano/verbosing'
require 'MrMurano/Config'
require 'MrMurano/SyncUpDown'
require '_workspace'

class TSUD
  include MrMurano::Verbose
  include MrMurano::SyncUpDown
  def initialize
    @itemkey = :id
    @locationbase = $cfg['location.base']
    @location = 'tsud'
  end
end
RSpec.describe MrMurano::SyncUpDown do
  include_context "WORKSPACE"
  before(:example) do
    $cfg = MrMurano::Config.new
    $cfg.load
    $cfg['net.host'] = 'bizapi.hosted.exosite.io'
    $cfg['solution.id'] = 'XYZ'
  end

  context "status" do
    it "warns with missing directory" do
      t = TSUD.new
      expect(t).to receive(:warning).once.with(/Skipping missing location.*/)
      ret = t.status
      expect(ret).to eq({:toadd=>[], :todel=>[], :tomod=>[], :unchg=>[]})
    end

    it "finds nothing in empty directory" do
      FileUtils.mkpath('tsud')
      t = TSUD.new
      ret = t.status
      expect(ret).to eq({:toadd=>[], :todel=>[], :tomod=>[], :unchg=>[]})
    end

    it "finds things there but not here" do
      FileUtils.mkpath('tsud')
      t = TSUD.new
      expect(t).to receive(:list).once.and_return([
        {:id=>1},{:id=>2},{:id=>3}
      ])
      ret = t.status
      expect(ret).to eq({
        :toadd=>[],
        :todel=>[{:id=>1, :synckey=>1}, {:id=>2, :synckey=>2}, {:id=>3, :synckey=>3}],
        :tomod=>[],
        :unchg=>[]})
    end

    it "finds things there but not here; asdown" do
      FileUtils.mkpath('tsud')
      t = TSUD.new
      expect(t).to receive(:list).once.and_return([
        {:id=>1},{:id=>2},{:id=>3}
      ])
      ret = t.status({:asdown=>true})
      expect(ret).to eq({
        :todel=>[],
        :toadd=>[{:id=>1, :synckey=>1}, {:id=>2, :synckey=>2}, {:id=>3, :synckey=>3}],
        :tomod=>[],
        :unchg=>[]})
    end

    it "finds things here but not there" do
      FileUtils.mkpath('tsud')
      FileUtils.touch('tsud/one.lua')
      FileUtils.touch('tsud/two.lua')
      t = TSUD.new
      ret = t.status
      expect(ret).to eq({
        :toadd=>[
          {:name=>'one.lua', :synckey=>nil,
           :local_path=>Pathname.new(@projectDir + '/tsud/one.lua').realpath},
          {:name=>'two.lua', :synckey=>nil,
           :local_path=>Pathname.new(@projectDir + '/tsud/two.lua').realpath},
        ],
        :todel=>[],
        :tomod=>[],
        :unchg=>[]})
    end

  end

  it "finds local items" do
    FileUtils.mkpath('tsud')
    FileUtils.touch('tsud/one.lua')
    FileUtils.touch('tsud/two.lua')
    t = TSUD.new
    ret = t.localitems(@projectDir + '/tsud')
    expect(ret).to eq([
      {:name=>'one.lua',
       :local_path=>Pathname.new(@projectDir + '/tsud/one.lua')},
      {:name=>'two.lua',
       :local_path=>Pathname.new(@projectDir + '/tsud/two.lua')},
    ])
  end

end
#  vim: set ai et sw=2 ts=2 :
