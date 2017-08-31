# create windows template
download windows 2012iso and install it
you need to enable winrm (you can use this power script https://raw.githubusercontent.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/master/bosh-psmodules/modules/BOSH.WinRM/BOSH.WinRM.psm1)

or manually
add a rule in our windows 2012 r2 base template
to allow connections to 5985 WINRM outside its subnet

have also set
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

ISSUES:

(not solved)
- sometime ipv6 is used in winrm
```
2017/08/21 08:51:52 packer-builder-vsphere.linux: 2017/08/21 08:51:52 [INFO] Attempting WinRM connection...
2017/08/21 08:51:52 packer-builder-vsphere.linux: 2017/08/21 08:51:52 [DEBUG] connecting to remote shell using WinRM
2017/08/21 08:51:52 packer-builder-vsphere.linux: 2017/08/21 08:51:52 [ERROR] connection error: unknown error Post http://fe80::dd5b:1430:623d:c52b:5985/wsman: invalid URL port ":dd5b:1430:623d:c52b:5985"
2017/08/21 08:51:52 packer-builder-vsphere.linux: 2017/08/21 08:51:52 [ERROR] WinRM connection err: unknown error Post http://fe80::dd5b:1430:623d:c52b:5985/wsman: invalid URL port ":dd5b:1430:623d:c52b:5985"
```

(solved)
- strange errors with "The data area passed to a system call is too small"
https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/issues/20

- vsphere timeout see https://github.com/jetbrains-infra/packer-builder-vsphere/issues/33

TODO:
create docker images that does bundle install and adds all resources
