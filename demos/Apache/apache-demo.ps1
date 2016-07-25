
#list Apache Modules
Get-ApacheModules |Where {$_.Module -like "*proxy*"}|Sort-Object Module

#Graceful restart of Apache
Restart-ApacheHTTPServer -graceful

#Enumerate current virtual hosts (web sites)
Get-ApacheVHost

#Add a new virtual host
New-ApacheVHost -ServerName "mytestserver" -DocumentRoot /var/www/html/mystestserver -VirtualHostIPAddress * -VirtualHostPort 8090

#Or interactively with: New-ApacheVHost

Get-ApacheVHost |Where {$_.VirtualHostPort -eq 8090}