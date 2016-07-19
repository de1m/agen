#cs
 This tool can create a configuration file for nsclient++ and icinga2 (example: server.conf).
 You need only to select a service/s, that you will to monitoring (for example dhcp or dns)
 LICENCE: MIT
#ce

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=icinga_logo2.ico
#AutoIt3Wrapper_Outfile=..\bin\Agen_x86.exe
#AutoIt3Wrapper_Outfile_x64=..\bin\Agen_x64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Generiert INI Datei fuer NSClient(Passive)
#AutoIt3Wrapper_Res_Fileversion=0.9.1.6
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; *** Start added by AutoIt3Wrapper ***
#include <ComboConstants.au3>
#include <ListBoxConstants.au3>
; *** End added by AutoIt3Wrapper ***
#include <array.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <GuiComboBox.au3>
#include <Array.au3>
#include <_ConfigIO.au3>

;Create GUI
#Region ### START Koda GUI section ### Form=d:\autoit\agen(icinga)\gui\agen.kxf
$AGen = GUICreate("AGen - Icinga", 619, 464, 226, 135)
GUISetFont(12, 400, 0, "Calibri")
$liSegmente = GUICtrlCreateList("", 8, 8, 241, 455,BitOR($LBS_STANDARD, $LBS_EXTENDEDSEL, $WS_VSCROLL))
$bOpen = GUICtrlCreateButton("Open", 456, 7, 155, 25)
$iKonfiguration = GUICtrlCreateInput("", 260, 38, 349, 27, BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
$lKonfiguration = GUICtrlCreateLabel("Configuration:", 262, 15, 95, 23)
$lTemplate = GUICtrlCreateLabel("Host Template:", 263, 152, 103, 23)
$cHosttemplate = GUICtrlCreateCombo("", 368, 150, 241, 27, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$cHostGrup = GUICtrlCreateCombo("", 368, 180, 241, 27, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$cSTemplate = GUICtrlCreateCombo("", 368, 213, 241, 27, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$cSGruppe = GUICtrlCreateCombo("", 368, 244, 241, 27, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$iHostAlias = GUICtrlCreateInput("", 368, 274, 241, 27)
$iDispName = GUICtrlCreateInput("", 368, 304, 241, 27)
$lIcingaConfig = GUICtrlCreateLabel("Create Icinga2 configuration:", 254, 367, 199, 23)
$chConfig = GUICtrlCreateCheckbox("", 455, 370, 17, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
$lTemplate = GUICtrlCreateLabel("Host Template:", 263, 152, 103, 23)
$lServiceTemplate = GUICtrlCreateLabel("Service Template:", 249, 216, 119, 23)
$lHostGroup = GUICtrlCreateLabel("Host Group:", 277, 182, 89, 23)
$lHostAlias = GUICtrlCreateLabel("Host Alias:", 292, 276, 74, 23)
$lIPAdresse = GUICtrlCreateLabel("Host Disp. Name:", 249, 304, 119, 23)
$lServiceGruppe = GUICtrlCreateLabel("Service Group:", 261, 244, 105, 23)
$lXMLConfig = GUICtrlCreateLabel("XML configuration file:", 260, 67, 167, 23)
$iXMLConfig = GUICtrlCreateInput("", 260, 90, 349, 27, BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
$bOK = GUICtrlCreateButton("OK", 254, 428, 355, 25)
GUICtrlSetState(-1, $GUI_DISABLE) ;Disable ok button
GUISetState(@SW_SHOW,$AGen)

#EndRegion ### END Koda GUI section ###

IF FileExists(@ScriptDir&"\nsclient.ini") Then
	FileMove(@ScriptDir&"\nsclient.ini", @ScriptDir&"\nsclient_old_"&Random(1,100,1)&".ini")
EndIf

Global $aDienste ; Array with all Services and State of they
_ComputerGetServices($aDienste, "All")

;MsgBox(0,"Start-Ende",$SchaliasS&"-"&$SchaliasE)
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $bOpen

			Local $tXTverzeichnis = FileSelectFolder("Folder with configuration (source.txt, config.xml)", @ScriptDir,0,@ScriptDir)
			$tXTsource = $tXTverzeichnis&"\source.txt"

			if FileExists($tXTverzeichnis&"\config.xml") Then
				$existXML = 2
			Else
				$existXML = 1
			EndIf
			if FileExists($tXTverzeichnis&"\source.txt") Then
					$existS = 5
			Else
					$existS = 2
			EndIf

			;Check if config.xml exist in folder
			Select
				case $existXML + $existS = 7
					GUICtrlSetData($iXMLConfig,$tXTverzeichnis&"\config.xml")

			$configf = _Config_Open($tXTverzeichnis & "\config.xml"); Open configuration
			;Read configuration
			$interval = _Config_Read($configf, "monserver", "interval")
			$adresse = _Config_Read($configf, "monserver", "adresse")
			$password = _Config_Read($configf, "monserver", "password")
			$hosttemplate = StringSplit(_Config_Read($configf, "konfiguration", "htemplate"),",")
			$hostgroup = StringSplit(_Config_Read($configf, "konfiguration", "hgruppe"),",")
			$servicetemplate = StringSplit(_Config_Read($configf, "konfiguration", "stemplate"),",")
			$servicegroup = StringSplit(_Config_Read($configf, "konfiguration", "sgruppe"),",")

			;Update Combobox
			GUICtrlSetData($iKonfiguration,$tXTsource)

			_UpdateCombobox($cHosttemplate,$hosttemplate)
			_UpdateCombobox($cHostGrup,$hostgroup)
			_UpdateCombobox($cSTemplate,$servicetemplate)
			_UpdateCombobox($cSGruppe,$servicegroup)



			$nsINI = @ScriptDir&"\nsclient.ini"

			Local $aSource = FileReadToArray($tXTsource)

			$segmentS = _ArraySearch($aSource,"#Segmente",0,0,0,1)
			$segmentE = _ArraySearch($aSource,"@",$segmentS,0,0,1)

			_GUICtrlListBox_BeginUpdate($liSegmente)
			For $i = $segmentS + 1 TO $segmentE - 1
				_GUICtrlListBox_AddString($liSegmente,$aSource[$i])
			Next
			_GUICtrlListBox_EndUpdate($liSegmente)

			;MsgBox(0,"Start-Ende",$segmentS&"-"&$segmentE)
			;Read source.txt
			$moduleS = _ArraySearch($aSource,"#Module",0,0,0,1)
			$moduleE = _ArraySearch($aSource,"@",$moduleS, 0,0,1)

			;MsgBox(0,"Start-Ende",$moduleS&"-"&$moduleE)
			
			$aliallgemeinS = _ArraySearch($aSource,"#AliAllgemein",0,0,0,1)
			$aliallgemeinE = _ArraySearch($aSource,"@",$aliallgemeinS,0,0,1)

			;MsgBox(0,"Start-Ende",$aliallgemeinS&"-"&$aliallgemeinE)
			
			$intervalS = _ArraySearch($aSource,"#Interval",0,0,0,1)
			$intervalE = _ArraySearch($aSource,"@",$intervalS,0,0,1)

			;MsgBox(0,"Start-Ende",$intervalS&"-"&$intervalE)

			$SchaliasS = _ArraySearch($aSource,"#SchAlias",0,0,0,1)
			$SchaliasE = _ArraySearch($aSource,"@",$SchaliasS,0,0,1)

			$SchaliasINIS = _ArraySearch($aSource,"#SchAliasINI",0,0,0,1)
			$SchaliasINIE = _ArraySearch($aSource,"@",$SchaliasINIS,0,0,1)



			GUICTRLSetState($bOK, $GUI_ENABLE) ;OK Button wird wieder aktiviert.

				case $existxml + $existS = 6
					MsgBox(0,"Status", "File not found: "&@CRLF &$tXTverzeichnis&"\config.xml")
					;Exit
				case $existXML + $existS = 4
					MsgBox(0,"Status", "File not found: "&@CRLF &$tXTverzeichnis&"\source.txt")
					;Exit
				case $existxml+$existS = 3
					MsgBox(0,"Status", "File not found: "&@CRLF &$tXTverzeichnis&"\config.xml" & @CRLF&$tXTverzeichnis&"\source.txt")
					;Exit
			EndSelect

		Case $bOK
			For $i = $moduleS + 1 To $moduleE - 1
				FileWriteLine($nsINI,$aSource[$i])
			Next
			FileWriteLine($nsINI, " ")

			For $i = $aliallgemeinS + 1 To $aliallgemeinE -1
				FileWriteLine($nsINI,$aSource[$i])
			Next
			FileWriteLine($nsINI, " ")

			$aItems = _GUICtrlListBox_GetSelItemsText($liSegmente)

			;Create Icinga host Config
			If _IsChecked($chConfig) Then
				$servername = Guictrlread($iHostAlias)
				$cfgFile = @ScriptDir&"\"&$servername&".conf"
				FileWriteLine($cfgFile,"object Host "&Chr(34)&GUICtrlRead($iHostAlias)&Chr(34)&" {")
				FileWriteLine($cfgFile,"	import	"&Chr(34)&GUICtrlRead($cHosttemplate)&Chr(34))
				If _IsVarIsNull(GUICtrlRead($iDispName)) Then
				Else
					FileWriteLine($cfgFile,"	display_name =		"&Chr(34)&GUICtrlRead($iDispName)&Chr(34))
				EndIf
				FileWriteLine($cfgFile,"	vars.group =		"&Chr(34)&GUICtrlRead($cHostGrup)&Chr(34))
				FileWriteLine($cfgFile,"}")
				FileWriteLine($cfgFile," ")
			EndIf

			For $iI = 1 To $aItems[0]
				_WriteSegmentAlias($aItems[$iI])
			Next

			FileWriteLine($nsINI,"[/settings/scheduler/schedules/default]")
			FileWriteLine($nsINI,"interval="&$interval&"m")
			FileWriteLine($nsINI, " ")

			For $i = $SchaliasS + 1 to $SchaliasE - 1
				FileWriteLine($nsINI,$aSource[$i])
			Next
			FileWriteLine($nsINI, " ")

			;Standart Service (CPU,HDD,Ram)
			If _IsChecked($chConfig) Then
				For $i = $SchaliasINIS +1 to $SchaliasINIE - 1
					$servername = Guictrlread($iHostAlias)
					$cfgFile = @ScriptDir&"\"&$servername&".conf"
					
					;Create Service and write to file
					FileWriteLine($cfgFile,"object Service "&Chr(34)&$aSource[$i]&Chr(34)&" {")
					FileWriteLine($cfgFile,"	import	"&Chr(34)&GUICtrlRead($cSTemplate)&Chr(34))
					FileWriteLine($cfgFile,"	host_name	="&Chr(34)&GUICtrlRead($iHostAlias)&Chr(34))
					FileWriteLine($cfgFile,"	vars.group	="&Chr(34)&GUICtrlRead($cHostGrup)&Chr(34))
					FileWriteLine($cfgFile,"}")
					FileWriteLine($cfgFile," ")
				Next
				FileWriteLine($nsINI, " ")
			EndIf

			For $iI = 1 To $aItems[0]
				_WriteSegmentSch($aItems[$iI])
			Next

			FileWriteLine($nsINI, "[/settings/NSCA/client]")
			FileWriteLine($nsINI, "hostname="&GUICtrlRead($iHostAlias))
			FileWriteLine($nsINI, @CRLF)

			FileWriteLine($nsINI, "[/settings/NSCA/client/targets/default]")
			FileWriteLine($nsini, "address="&$adresse)
			FileWriteLine($nsini, "encryption=1")
			FileWriteLine($nsINI, "password="&$password);Dfnasdf234Adaf234edfasdfAD
			FileWriteLine($nsINI, @CRLF)
			Exit
	EndSwitch
WEnd

;Write scheduler segments
Func _WriteSegmentSch($searchstr)
	$strStart = _ArraySearch($aSource, "##"&$searchstr, 0, 0, 0, 1)
	$strEnd = _ArraySearch($aSource, "@", $strStart, 0, 0, 1)
	Select
		Case StringLeft($searchstr, 3) = "Eve"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				FileWriteLine($nsINI,"EvID"&$strSplit[1]&"_"&$strSplit[6]&" = eventid_"&$strSplit[1])

				If _IsChecked($chConfig) Then
					$servername = Guictrlread($iHostAlias)
					$cfgFile = @ScriptDir&"\"&$servername&".conf"
					;Service definiion erstellen und in Datei schreiben
					FileWriteLine($cfgFile,"object Service "&Chr(34)&"EvID"&$strSplit[1]&"_"&$strSplit[6]&Chr(34)&" {")
					FileWriteLine($cfgFile,"	import	"&Chr(34)&GUICtrlRead($cSTemplate)&Chr(34))
					FileWriteLine($cfgFile,"	host_name	="&Chr(34)&GUICtrlRead($iHostAlias)&Chr(34))
					FileWriteLine($cfgFile,"	vars.group	="&Chr(34)&GUICtrlRead($cHostGrup)&Chr(34))
					FileWriteLine($cfgFile,"}")
					FileWriteLine($cfgFile," ")
				EndIf
			Next
		Case StringLeft($searchstr, 3) = "win"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				$dienst = _ArraySearch($aDienste,$strSplit[1],0,0,0,0);Sucht Dienst in einem Array, in diesem Array sind alle Dienste mit dem Status aufgeschrieben.
				if @error Then
					FileWriteLine($nsINI,";NOT FOUND: "&$strSplit[2]&" = alias_"&$strSplit[1])
				Else
					FileWriteLine($nsINI,$strSplit[2]&" = alias_"&$strSplit[1])
				EndIf

#cs				If _IsChecked($chDienste) Then
					$servername1 = Guictrlread($iHostAlias)
					$dienstecfg = $tXTverzeichnis&"\"&$servername1&"_Dienste.txt"
					FileWriteLine($dienstecfg, $strSplit[1])
				EndIf
#ce
				If _IsChecked($chConfig) Then
					$dienst = _ArraySearch($aDienste,$strSplit[1],0,0,0,0);Sucht Dienst in einem Array, in diesem Array sind alle Dienste mit dem Status aufgeschrieben.
					if @error Then
						;nicht machen, wenn Dienst nicht gefunden wurde.
					Else
						$servername = Guictrlread($iHostAlias)
						$cfgFile = @ScriptDir&"\"&$servername&".conf"
						;Service definiion erstellen und in Datei schreiben
						FileWriteLine($cfgFile,"object Service "&Chr(34)&$strSplit[2]&Chr(34)&" {")
						FileWriteLine($cfgFile,"	import	"&Chr(34)&GUICtrlRead($cSTemplate)&Chr(34))
						FileWriteLine($cfgFile,"	host_name	="&Chr(34)&GUICtrlRead($iHostAlias)&Chr(34))
						FileWriteLine($cfgFile,"	vars.group	="&Chr(34)&GUICtrlRead($cHostGrup)&Chr(34))
						FileWriteLine($cfgFile,"}")
						FileWriteLine($cfgFile," ")
					EndIf
				EndIf
			Next
		Case StringLeft($searchstr, 3) = "Ext"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				$strSplit2 = StringSplit($strSplit[1],"=")
				FileWriteLine($nsINI, $strSplit[2]&"="&$strSplit2[1])

				If _IsChecked($chConfig) Then
					$servername = Guictrlread($iHostAlias)
					$cfgFile = @ScriptDir&"\"&$servername&".conf"
					;Service definiion erstellen und in Datei schreiben
					FileWriteLine($cfgFile,"object Service "&Chr(34)&$strSplit[2]&" {")
					FileWriteLine($cfgFile,"	import	"&Chr(34)&GUICtrlRead($cSTemplate)&Chr(34))
					FileWriteLine($cfgFile,"	host_name	="&Chr(34)&GUICtrlRead($iHostAlias)&Chr(34))
					FileWriteLine($cfgFile,"	vars.group	="&Chr(34)&GUICtrlRead($cHostGrup)&Chr(34))
					FileWriteLine($cfgFile,"}")
					FileWriteLine($cfgFile," ")
				EndIf
			Next
		Case Else
			MsgBox(0,"Case Else", "nichts ausgwählt")
	EndSelect
	FileWriteLine($nsINI," ")
EndFunc

;write alias segments
Func _WriteSegmentAlias($searchstr)
	$strStart = _ArraySearch($aSource, "##"&$searchstr, 0, 0, 0, 1)
	$strEnd = _ArraySearch($aSource, "@", $strStart, 0, 0, 1)

	Select
		Case StringLeft($searchstr, 3) = "Eve"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				FileWriteLine($nsINI,"eventid_"&$strSplit[1]&" = checkEventLog file="&$strSplit[2]&" debug=true MaxWarn="&$strSplit[3]&" MaxCrit="&$strSplit[4]&" truncate=800 unique descriptions "&Chr(34)&"syntax=%strings% (%count%)"&Chr(34)&" "&Chr(34)&"filter=generated > -"&$strSplit[5]&"m AND id IN("&$strSplit[1]&")")
			Next
		Case StringLeft($searchstr, 3) = "win"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				$dienst = _ArraySearch($aDienste,$strSplit[1],0,0,0,0);Sucht Dienst in einem Array, in diesem Array sind alle Dienste mit dem Status aufgeschrieben.
				if @error Then
					FileWriteLine($nsINI,";NOT FOUND: alias_"&$strSplit[1]&" = checkServiceState "&Chr(34)&$strSplit[1]&Chr(34)&"=started ShowAll")
				Else
					FileWriteLine($nsINI,"alias_"&$strSplit[1]&" = checkServiceState "&Chr(34)&$strSplit[1]&Chr(34)&"=started ShowAll")
				EndIf
			Next
		Case StringLeft($searchstr, 3) = "Ext"
			FileWriteLine($nsINI,  $aSource[$strStart + 1])
			For $o = $strStart + 2 To $strEnd - 1
				$strSplit = StringSplit($aSource[$o],":")
				FileWriteLine($nsINI,$strSplit[1])
			Next
		Case Else
	EndSelect
	FileWriteLine($nsINI," ")
EndFunc

Func _IsVarIsNull($_Var);func to check if var is empty
	If Not $_Var Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>_IsVarIsNull

Func _IsChecked($iControlID); func to check checkbox
    Return BitAND(GUICtrlRead($iControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked

Func _UpdateCombobox($combo, $combotext) ;func - update combobox
	_GUICtrlComboBox_BeginUpdate($combo)
	For $i = 1 to $combotext[0]
		_GUICtrlComboBox_AddString($combo, $combotext[$i])
	Next
	_GUICtrlComboBox_EndUpdate($combo)
	GUICtrlSetData($combo, $combotext[1])
EndFunc

Func _ComputerGetServices(ByRef $aServicesInfo, $sState = "All") ;read state of a service
    Local $cI_Compname = @ComputerName, $wbemFlagReturnImmediately = 0x10, $wbemFlagForwardOnly = 0x20
    Local $colItems, $objWMIService, $objItem
    Dim $aServicesInfo[1][2], $i = 1
	;Dim $aServicesInfo[1][23], $i = 1

    $objWMIService = ObjGet("winmgmts:\\" & $cI_Compname & "\root\CIMV2")
    $colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Service", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)

    If IsObj($colItems) Then
        For $objItem In $colItems
            If $sState <> "All" Then
                If $sState = "Stopped" And $objItem.State <> "Stopped" Then ContinueLoop
                If $sState = "Running" And $objItem.State <> "Running" Then ContinueLoop
			EndIf
			ReDim $aServicesInfo[UBound($aServicesInfo) + 1][2]
            ;ReDim $aServicesInfo[UBound($aServicesInfo) + 1][23]
            $aServicesInfo[$i][0] = $objItem.Name
			$aServicesInfo[$i][1] = $objItem.State
            $i += 1
        Next
        $aServicesInfo[0][0] = UBound($aServicesInfo) - 1
        If $aServicesInfo[0][0] < 1 Then
            SetError(1, 1, 0)
        EndIf
    Else
        SetError(1, 2, 0)
    EndIf
EndFunc   ;==>_ComputerGetServices