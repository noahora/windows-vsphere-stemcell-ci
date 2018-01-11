$LOAD_PATH.push ARGV[0]
require 'stemcell/builder'

class VSphere < Stemcell::Builder::VSphere
  def build
    run_packer
    export_vmdk
    run_stembuild
  end

  private

# a template needs to be availeble of the windows2012 first with winrm enabled
  def packer_config
    JSON.dump(JSON.parse(super).tap do |config|
      config['builders'] = [
          {
            "type" => "vsphere",
            "vcenter_server" => Stemcell::Builder::validate_env('VCENTER_SERVER'),
            "username" => Stemcell::Builder::validate_env('VCENTER_USERNAME'),
            "password" => Stemcell::Builder::validate_env('VCENTER_PASSWORD'),
            "insecure_connection" => true,

            "template" => Stemcell::Builder::validate_env('BASE_TEMPLATE'),
            "folder" => Stemcell::Builder::validate_env('VCENTER_VM_FOLDER'),
            "vm_name" =>  "packer-vmx",
            "host" =>     Stemcell::Builder::validate_env('VCENTER_HOST'),
            "resource_pool" => "",
            # "ssh_username" => 'Administrator',
            # "ssh_password" => Stemcell::Builder::validate_env('ADMINISTRATOR_PASSWORD'),
            'communicator' => 'winrm',
            'winrm_username' => 'Administrator',
            'winrm_password' => Stemcell::Builder::validate_env('ADMINISTRATOR_PASSWORD'),
            'winrm_timeout' => '3h',
            'winrm_insecure' => true,
            "CPUs" => ENV.fetch('NUM_VCPUS', '4'),
            "RAM"  => ENV.fetch('MEM_SIZE', '4096'),
          }
        ]
    end)
  end
  $dir = '/root' # Dir.pwd
  # we can change this when govmami has the export feature https://github.com/vmware/govmomi/pull/813 or maby intergrate
  # in vpshere plugin see https://github.com/jetbrains-infra/packer-builder-vsphere/issues/34
  def export_vmdk
    folder = Stemcell::Builder::validate_env('VCENTER_VM_FOLDER')
    host_folder = Stemcell::Builder::validate_env('VCENTER_HOST_FOLDER')
    server = Stemcell::Builder::validate_env('VCENTER_SERVER')
    username = Stemcell::Builder::validate_env('VCENTER_USERNAME')
    password = Stemcell::Builder::validate_env('VCENTER_PASSWORD')
    ovfusername = "#{username.split('\\')[0].strip}\%5c#{username.split('\')[1].strip}"
    ovfpassword = "#{password.split('\$')[0].strip}\\\$"
    cmd = "ovftool --noSSLVerify --machineOutput \"vi://#{ovfusername}:#{ovfpassword}@#{server}/#{host_folder}/vm/#{folder}/packer-vmx/\" #{$dir}/"
    puts cmd
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line=stdout.gets || line=stderr.gets do
        puts(line)
      end
  end

# produces tgz and needs to be uploaded to s3
  def run_stembuild
    vmdk_file = find_file_by_extn(@output_directory, "vmdk")
    cmd = "stembuild -vmdk \"#{vmdk_file}\" -v \"#{Stemcell::Manifest::Base.strip_version_build_number(@version)}.#{Time.now.getutc.to_i}\" -output \"#{@output_directory}\""
    puts "running stembuild command: [[ #{cmd} ]]"
    `#{cmd}`
  end

end

administrator_password = Stemcell::Builder::validate_env('ADMINISTRATOR_PASSWORD')

# version should be agent/p_modules number from github
# windows update versioning? how do we check/compare?
versionfile = File.join(Dir.pwd,'build','version')
version = IO.read(versionfile).chomp

sourcedir = '/root/packer-vmx/'#File.join(Dir.pwd,'packer-vmx')


vsphere = VSphere.new(
  mem_size: ENV.fetch('MEM_SIZE', '4096'),
  num_vcpus: ENV.fetch('NUM_VCPUS', '4'),
  source_path: sourcedir,
  agent_commit: 'bar',
  administrator_password: administrator_password,
  new_password: ENV.fetch('NEW_PASSWORD', administrator_password),
  product_key: ENV['PRODUCT_KEY'],
  owner: Stemcell::Builder::validate_env('OWNER'),
  organization: Stemcell::Builder::validate_env('ORGANIZATION'),
  os: Stemcell::Builder::validate_env('OS_VERSION'),
  output_directory: sourcedir,
  packer_vars: {},
  version: version,
  enable_rdp: ENV['ENABLE_RDP'] ? (ENV['ENABLE_RDP'].downcase == 'true') : false,
  enable_kms: ENV['ENABLE_KMS'] ? (ENV['ENABLE_KMS'].downcase == 'true') : false,
  kms_host: ENV.fetch('KMS_HOST', ''),
  skip_windows_update: ENV['SKIP_WINDOWS_UPDATE'],
  http_proxy: {},
  https_proxy: {},
  bypass_list: {}
)

vsphere.build

end
