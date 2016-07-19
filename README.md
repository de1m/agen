# Agen
![Screenshot](/screenshot/screen.PNG)
## Description
Tool to create configuration of icinga2 for passive windows checks(for using with nsclient++)

## Steps

### config.xml

    <?xml version="1.0" encoding="UTF-16"?>
    <CONFIG>
	    <monserver>
		    <interval>2</interval>
		    <adresse>monitoring.server.local</adresse>
		    <password>NSCAPASS</password>
	    </monserver>
	    <konfiguration>
    		<htemplate>passive-host</htemplate>
	    	<stemplate>passive-service</stemplate>
		    <hgruppe>HOSTGROUP</hgruppe>
		    <sgruppe>SERVICEGROUP</sgruppe>
	    </konfiguration>
    </CONFIG>

 interval - specifying how many times the data should be sent (min)
 address - url/ip of monitoring server
 password - password of nsca service on monitoring server
 htemplate - name of passive host template on icinga2
 stemplate - name of passvie service template on icinga2
 hgruppe - host group name on icinga2 server
 sgruppe - service group name on icinga2 server
 
#### Example passive host template

    template Host "passive-host" {
        max_check_attempts = 2
        check_interval          = 300s
        retry_interval          = 200s
        enable_active_checks = true
        enable_passive_checks = true
        check_command = "passive"
        vars.notification["mail"] = {
        groups = [ "icingaadmins" ]
        }
    }
    
#### Example passvie service template

    template Service "passive-service" {
        max_check_attempts = 2
        check_interval = 3m
        retry_interval = 0
        enable_active_checks = true
        check_command = "passive"
        vars.notification["mail"] = {
        groups = [ "icingaadmins" ]
        }
    }
    
#### Generated example of an configuration file for icinga2

    object Host "4demo" {
	    import	"passive-host"
	    display_name =		"4demo Server Host"
	    vars.group =		"test"
    }
 
    object Service "CPU" {
	    import	"passive-service"
	    host_name	="4demo"
	    vars.group	="test"
    }
 
    object Service "Festplatten" {
	    import	"passive-service"
	    host_name	="4demo"
	    vars.group	="test"
    }
 
    object Service "Arbeitsspeicher" {
	    import	"passive-service"
	    host_name	="4demo"
	    vars.group	="test"
    }
    
### source.txt
This file contains all ressources, which you can select to monitor
#### Segment
Here will be descript, which services contain this file

    win - Windows service
    eve - Eventlog
    
#### Module
Module to activated in nsclient++

#### Interval
Time to resend state of a service

#### Example - DHCP Server
1. Add winDHCP in Segment
2. Add Service
    
        ##winDHCP
        ;DHCP Service
        DHCPServer:Windows_Dienst_DHCP_Server
    
    ##winDHCP - define (win) that it is a windows service
    ;DHCP Service - description of service, this will be write in nsclient.ini as comment
    DHCPServer - Name of service in Windows
    Windows_Dienst_DHCP_Server - Name of service in icinga (Display Name)
3. Add Eventlog

        ##EveIDDHCP
        ;EveIDDHCP
        10020:system:1:10:20:DHCP_Dyn._IP
        
    ##EveIDDHCP - Name of Segment - eve define that it is a eventlog
    ;EveIDDHCP - comment in nslcient.ini
    10020 - Eventlog id
    system - type of eventlog (application, system, security)
    1 - warn
    10 - critical
    20 - show last 20min.
    DHCP_Dyn._IP - Name of service in icinga (Display Name). You can use a name with space
    
 
 ## Steps
 
 1. Edit config.xml (show below)
 2. Start tool
 3. Select folder with config.xml and source.txt
 4. Write host name and display host name
 5. Select service to monitoring
 6. Check checkbox if you will generate icinga2 configuration file
 7. Copy nsclient.ini in nsclient++ folder and restart nsclient++
 8. Copy servername.conf file in icinga2 server and reload/restart icinga2 configuration.


# It would be good if you send me the updates of source.txt file
