RSpec.describe Sanctum::Command::View do
  let(:config_path) {"#{Dir.tmpdir}/view"}
  let(:vault_token) {"514c55f0-c452-99e3-55e0-8301b770b92c"}
  let(:vault_addr) {"http://127.0.0.1:8200"}
  let(:vault_env) { {"VAULT_ADDR" => vault_addr, "VAULT_TOKEN" => vault_token} }
  let(:vault_client) {Sanctum::VaultClient.build(vault_addr, vault_token)}
  let(:args) {["#{config_path}/encrypted_file"]}
  let(:options) {
    {:config_file=>"#{config_path}/sanctum.yaml",
     :sanctum=>{:force=>false, :color=>false},
     :vault=>{:url=>vault_addr,
              :token=>vault_token,
              :transit_key=>"transit/keys/vault-test"},
              :sync=>[{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test"}],
              :cli=>{:targets=>nil, :force=>true}}
  }

  before :each do
    Sanctum::Colorizer.colorize = options[:sanctum][:color]
    #Clean up generated test file
    FileUtils.remove_entry_secure(config_path, force: true) if File.directory?(config_path)
    # Start vault server
    @pid = Process.spawn("vault", "server", "-dev", "-dev-root-token-id=#{vault_token}", [:out, :err]=>"/dev/null")
    # Ensure vault server has started and is accepting connections
    Timeout::timeout(5){response = Net::HTTP.get_response(URI("#{vault_addr}/v1/sys/health")) rescue retry until response.kind_of? Net::HTTPSuccess}

    # Enable transit secrets mount
    vault_command(vault_env,"vault secrets enable transit")
    # Create a transit key
    vault_command(vault_env,"vault write -f transit/keys/vault-test")

    # Create tmp folder
    FileUtils.mkdir_p(config_path)
    # Write transit encrypted data to local file to test view command
    Sanctum::VaultTransit.write_to_file(vault_client, {args[0] => {"keyone" => "valueone"}}, options[:vault][:transit_key])
  end

  after :each do
    Process.kill("INT", @pid)
    Process.wait(@pid)
  end

  # TODO This could probably be better
  it "views an encrypted file" do
    expect {described_class.new(options, args).run(command=nil)}.to output(/keyone: valueone/).to_stdout
  end
end
