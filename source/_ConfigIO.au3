#include-once
; #INDEX# ========================================================================
; Title .........: _ConfigIO
; AutoIt Version : 3.3.0++
; Language ......: English
; Description ...: Functions that assist with reading and writiing configuration files. A very simple XML reader/writer.
; Author ........: Stephen Podhajecki (eltorro)
; ================================================================================
; #VARIABLES# ====================================================================
Global $__COM_ERR
Global Const $NODE_XML_INVALID = 0;
Global Const $NODE_XML_ELEMENT = 1;
Global Const $NODE_XML_ATTRIBUTE = 2;
Global Const $NODE_XML_TEXT = 3;
Global Const $NODE_XML_CDATA_SECTION = 4;
Global Const $NODE_XML_ENTITY_REFERENCE = 5;
Global Const $NODE_XML_ENTITY = 6;
Global Const $NODE_XML_PROCESSING_INSTRUCTION = 7;
Global Const $NODE_XML_COMMENT = 8;
Global Const $NODE_XML_DOCUMENT = 9;
Global Const $NODE_XML_DOCUMENT_TYPE = 10;
Global Const $NODE_XML_DOCUMENT_FRAGMENT = 11;
Global Const $NODE_XML_NOTATION = 12;
Global $XML_ENCODING[4] = [3, "iso-8859-1", "UTF-8", "UTF-16"] ; the first element sets the default encoding
Global $aCONFIG_FHDS[1][2] ;hold handles and filenames
; ================================================================================

; #NO_DOC_FUNCTION# ==============================================================
; Not working/documented/implimented at this time
; ================================================================================
; __Config_COMErr
; ================================================================================

; #CURRENT# ======================================================================
;_Config_Create
;_Config_Open
;_Config_Read
;_Config_Write
;_Config_Delete
;_Config_EnumParam
;_Config_EnumVal
;_Config_Save
;_Config_SaveAs
;_Config_Close
;_Config_Indent
;_Config_Base64_Encode
;_Config_Base64_Decode
; ================================================================================

; #INTERNAL_USE_ONLY#=============================================================
;__Config_CreateKeyRecursive
;__Config_KeyExists
;__Config_SetFileToHandle
;__Config_GetFileFromHandle
;__Config_RemoveFileHandle
;__Config_COMErr
;__Config_InitCOMErr
; ================================================================================

; #FUNCTION# =====================================================================
; Name...........: _Config_Create
; Description ...: Creates a configuration file
; Syntax.........: _Config_Create($szFileName, $iOverwrite = 0, $szRoot = "",$iEncoding = 0)
; Parameters ....: $szFileName - The filename for the configuration file
;                : $iOverwrite      - Overwrite exisiting file
;                  |0 - Don't overwrite, and return error
;                  |1 - Overwrite the file.
;                  |2 - Prompt to overwrite.
;                  $szRoot     - The value for the root node
;                  $iEncoding  - The encoding to use
;                  |0 - Default (UTF-16)
;                  |1 - iso-8859-1
;                  |2 - UTF-8
;                  |3 - UTF-16
; Return values .: Success - An XML object handle
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: Creates the configuration file using the default encoding and root name. After creation,
;                  _Config_Open is called and the handle returned.  This file handle and the filename are cached
;                  and later used by _Config_Close and _Config_Save
; Related .......: _Config_Open, _Config_Close, _Config_Save, _Config_SaveAs
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Create($szFileName, $iOverwrite = 0, $szRoot = "", $iEncoding = 0)
	If $szRoot = "" Then $szRoot = "CONFIG"
	If FileExists($szFileName) Then
		If $iOverwrite = 0 Then Return SetError(1, 0, 0)
		If $iOverwrite = 2 Then
			If MsgBox(266292, @ScriptName, "The file: " & $szFileName & " , already exists. Do you wish to overwrite the file?") <> 6 Then Return SetError(1, 0, 0)
		EndIf
	EndIf
	Local $hConfig, $objPI, $objRoot
	$hConfig = ObjCreate("MSXML2.DOMDocument")
	If $iEncoding <= 0 Or $iEncoding > UBound($XML_ENCODING) Then $iEncoding = $XML_ENCODING[0]
	$objPI = $hConfig.createProcessingInstruction("xml", StringFormat('version="1.0" encoding="%s"', $XML_ENCODING[$iEncoding]))
	$hConfig.appendChild($objPI)
	$objRoot = $hConfig.createElement($szRoot)
	$hConfig.documentElement = $objRoot
	$hConfig.save($szFileName)
	If $hConfig.parseError.errorCode <> 0 Then
		ConsoleWriteError("Error Creating specified file: " & $szFileName)
		SetError($hConfig.parseError.errorCode, 0, 0)
		Return 0
	EndIf
	$objPI = 0
	$objRoot = 0
	$hConfig = 0
	Return _Config_Open($szFileName)
EndFunc   ;==>_Config_Create

; #FUNCTION# ===================================================================
; Name...........: _Config_Open
; Description ...: Opens a configuration file
; Syntax.........: _Config_Open($szFileName)
; Parameters ....: $szFileName - The configuration file to open
; Return values .: Success - An XML object handle.
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: Opens an XML configuration file and if succesful returns the object handle to the file.
; Related .......: _Config_Create, _Config_Close, _Config_Save, _Config_SaveAs
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Open($szFileName)
	Local $hConfig
	$hConfig = ObjCreate("Msxml2.DOMDocument")
	If @error Then Return SetError(1, 0, 0)
	If IsObj($hConfig) Then
		__Config_InitCOMErr()
		$hConfig.async = False
		$hConfig.preserveWhiteSpace = True
		$hConfig.Load($szFileName)
		$hConfig.setProperty("SelectionLanguage", "XPath")
		If $hConfig.parseError.errorCode <> 0 Then
			;ConsoleWriteError("Error opening specified file: " & $szFileName & @CRLF & $hConfig.parseError.reason)
			SetError($hConfig.parseError.errorCode, 0, 0)
			Return 0
		EndIf
		__Config_SetFileToHandle($hConfig, $szFileName)
		Return $hConfig
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_Open

; #FUNCTION# ===================================================================
; Name...........: _Config_Read
; Description ...: Read a value from the configuration file.
; Syntax.........: _Config_Read($hConfig, $szParam, $szValue)
; Parameters ....: $hConfig -  The object handle returned by _Config_Open or _Config_Create.
;                  $szParam - The name of the parameter to Read the value of.
;                  $szValue - The value name to read.
; Return values .: Success - The value.
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......:
; Related .......: _Config_Write, _Config_Delete
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Read(ByRef $hConfig, $szParam, $szValue)
	If Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	If $szParam = "" Then Return SetError(1, 0, 0)
	If $szValue Then $szParam &= "/" & $szValue
	Local $objKey, $szRet
	$szParam = StringReplace($szParam, "\", "/")
	$objKey = $hConfig.documentElement.selectSingleNode($szParam & "/child::text()")
	If IsObj($objKey) Then
		$szRet = $objKey.nodeValue
		$objKey = 0
		Return $szRet
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_Read

; #FUNCTION# ===================================================================
; Name...........: _Config_Write
; Description ...: Write a value in the configuration file.
; Syntax.........: _Config_Set($hConfig, $szParam, $vValue)
; Parameters ....: $hConfig -  The object handle returned by _Config_Open or _Config_Create.
;                  $szParam - The name of the parameter to write to
;                  $szValue - The value name to write to
;                  $vValue  - The value to write.
; Return values .: Success - 1
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: Call _Config_Save or _Config_SaveAs to save any changes made.
; Related .......: _Config_Read, _Config_Delete
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Write(ByRef $hConfig, $szParam, $szValue, $vValue)
	Local $err
	If Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	If $szParam = "" Then Return SetError(1, 0, 0)
	If $szValue Then $szParam &= "/" & $szValue
	$szParam = StringReplace($szParam, "\", "/")
	If __Config_KeyExists($hConfig, $szParam) Then
		Local $objKey = $hConfig.documentElement.selectSingleNode($szParam & "/child::text()")
		If IsObj($objKey) Then
			$objKey.text = $vValue
		Else
			Local $objChild = $hConfig.createTextNode($vValue)
			$objKey = $hConfig.documentElement.selectSingleNode($szParam)
			$objKey.appendChild($objChild)
			$err = @error
			$objChild = 0
			$objKey = 0
			If $err Then Return SetError(1, 0, 0)
		EndIf
		$objKey = 0
	Else
		__Config_CreateKeyRecursive($hConfig, $szParam, $vValue)
		If @error Then Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_Config_Write

; #FUNCTION# ===================================================================
; Name ..........: _Config_Delete
; Description ...: Delete a param from the config file.
; Syntax ........: _Config_Delete($hConfig, $szParam ,$szValue = "")
; Parameters ....: $hConfig - The config file handle
;                  $szParam - The name of the parameter to delete
;                  $szValue - The name of the value to delete
; Return values .: Success - 1
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: Call _Config_Save or _Config_SaveAs to save any changes made.
;                  If $szValue is skipped then the parameter and sub-parameters are deleted.
; Related .......: _Config_Read, _Config_Write
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Delete(ByRef $hConfig, $szParam, $szValue = "")
	If Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	If $szParam = "" Then Return SetError(1, 0, 0)
	If $szValue Then $szParam &= "/" & $szValue
	$szParam = StringReplace($szParam, "\", "/")
	Local $objKey, $objChild
	$objKey = $hConfig.documentElement.selectSingleNode($szParam)
	If IsObj($objKey) Then
		;only remove param if no sub-params like regedit
		If $objKey.hasChildNodes Then
			$objChild = $hConfig.documentElement.selectSingleNode($szParam & "/child::text()")
			If IsObj($objChild) Then
				$objChild.parentNode.removeChild($objChild)
			EndIf
			$objKey = $hConfig.documentElement.selectSingleNode($szParam)
			If Not $objKey.hasChildNodes Then $objKey.parentNode.removeChild($objKey)
		EndIf
		$objChild = 0
		$objKey = 0
		Return 1
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_Delete

; #FUNCTION# ===================================================================
; Name ..........: _Config_EnumParam
; Description ...: Reads the name of a parameter according to it's index.
; Syntax ........: _Config_EnumParam($hConfig,$szParam,$iIndex = 1)
; Parameters ....: $hConfig - The config file handle
;                  $szParam - The name of the parameter to enumerate
;                  $iIndex  - The 1-based index to retrieve
; Return values .: Success - The param
;                  Failure - 0 or empty String ("") and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: An empty string can be used for $szParam to enumerate the parameters under the root node.
; Related .......: _Config_EnumVal
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_EnumParam($hConfig, $szParam, $iIndex = 1)
	If $iIndex < 1 Or Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	$szParam = StringReplace($szParam, "\", "/")
	Local $objKey, $vRet
	If $szParam = "" Then
		$szParam = "*[" & $iIndex & "]"
	Else
		$szParam &= "/*[" & $iIndex & "]"
	EndIf
	$objKey = $hConfig.documentElement.selectSingleNode($szParam)
	If IsObj($objKey) Then $vRet = $objKey.nodeName
	$objKey = 0
	Return SetError(($vRet = ""), 0, $vRet)
EndFunc   ;==>_Config_EnumParam

; #FUNCTION# ===================================================================
; Name ..........: _Config_EnumVal
; Description ...: Reads the value to a parameter according to it's index.
; Syntax ........: _Config_EnumVal($hConfig,$szParam,$iIndex)
; Parameters ....: $hConfig - The config file handle
;                  $szParam - The name of the parameter to enumerate
;                  $iIndex - The 1-based index to retrieve
; Return values .: Success - The value of the parameter
;                  Failure - 0 or empty string ("") and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: An empty string can be used for $szParam to enumerate the parameters under the root node.
; Related .......:
; Link ..........: _Config_EnumParam
; Example .......: Yes
; ================================================================================
Func _Config_EnumVal($hConfig, $szParam, $iIndex)
	If $iIndex < 1 Or Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	$szParam = StringReplace($szParam, "\", "/")
	Local $objKey, $objChild, $vRet
	If $szParam = "" Then
		$szParam = "*[" & $iIndex & "]"
	Else
		$szParam &= "/*[" & $iIndex & "]"
	EndIf
	$objKey = $hConfig.documentElement.selectSingleNode($szParam)
	If IsObj($objKey) Then
		If $objKey.hasChildNodes Then
			$objChild = $hConfig.documentElement.selectSingleNode($szParam & "/child::text()")
			If IsObj($objChild) Then $vRet = $objChild.nodeValue
		EndIf
	EndIf
	$objChild = 0
	$objKey = 0
	Return SetError(($vRet = ""), 0, $vRet)
EndFunc   ;==>_Config_EnumVal

; #FUNCTION# ===================================================================
; Name...........: _Config_Save
; Description ...: Save the config file
; Syntax.........: _Config_Save($hConfig)
; Parameters ....: $hConfig - The config file handle
; Return values .: Success - 1
;                  Failure - 0
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: This function explicitly saves the configuration file.  The filename is
;                  retrieved from the handle cache.  Use _Config_SaveAs the specify a filename.
; Related .......: _Config_SaveAs
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Save(ByRef $hConfig)
	If IsObj($hConfig) Then
		Local $szFileName = __Config_GetFileFromHandle($hConfig)
		If $szFileName <> "" Then
			$hConfig.save($szFileName)
			If @error = 0 Then Return 1
		EndIf
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_Save

; #FUNCTION# ===================================================================
; Name...........: _Config_SaveAs
; Description ...: Save the config file as another filename
; Syntax.........: _Config_SaveAs($hConfig, $szFileName, $iOverwrite = 0)
; Parameters ....: $hConfig - The config file handle
;                  $szFileName -  The file name to save as.
;                  $iOverwrite -  The overwrite flag.
;                  |0 - Don't overwrite, and return error
;                  |1 - Overwrite the file.
;                  |2 - Prompt to overwrite.
; Return values .: Success - 1
;                  Failure - 0
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: This function will save the configuration using the supplied file name. The new file name will
;                  now be associated with the file handle.
; Related .......: _Config_Save
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_SaveAs(ByRef $hConfig, $szFileName, $iOverwrite = 0)
	If IsObj($hConfig) And $szFileName <> "" Then
		If FileExists($szFileName) Then
			If $iOverwrite = 0 Then Return SetError(1, 0, 0)
			If $iOverwrite = 2 Then
				If MsgBox(266292, @ScriptName, "The file: " & $szFileName & " , already exists. Do you wish to overwrite the file?") <> 6 Then Return SetError(1, 0, 0)
			EndIf
		EndIf
		$hConfig.save($szFileName)
		If @error = 0 Then
			__Config_SetFileToHandle($hConfig, $szFileName)
			Return 1
		EndIf
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_SaveAs

; #FUNCTION# ===================================================================
; Name...........: _Config_Close
; Description ...: Close the config file
; Syntax.........: _Config_Close($hConfig,$iSaveOnClose = 1)
; Parameters ....: $hConfig - The config file handle
;                  $iSaveOnClose   - Save when closing the file. Defaults to 1 (yes)
; Return values .: Success - 1
;                  Failure - 0
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: If $iSaveOnClose = 1 then the an attempt to save the config file will be made.
; Related .......: _Config_Create, _Config_Open, _Config_Save
; Link ..........:
; Example .......: Yes
; ================================================================================
Func _Config_Close(ByRef $hConfig, $iSaveOnClose = 1)
	Local $vRet
	If IsObj($hConfig) Then
		If $iSaveOnClose Then
			_Config_Save($hConfig)
			$vRet = @error
		EndIf
	EndIf
	__Config_RemoveFileHandle($hConfig)
	$hConfig = 0
	Return SetError($vRet, 0, ($vRet = 0))
EndFunc   ;==>_Config_Close

; #FUNCTION# ===================================================================
; Name ..........: _Config_Indent
; Description ...: Indents an XML file
; Syntax ........: _Config_Indent($szFileName, $iEncoding = 0)
; Parameters ....: $szFileName - The file to indent
;                  $iEncoding  - The encoding to use
;                  |0 - Default (UTF-16)
;                  |1 - iso-8859-1
;                  |2 - UTF-8
;                  |3 - UTF-16
; Return values .: None
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: Uses msxml SAX methods to indent an xml file.  It is NOT PERFECT. HTML-Tidy does a much better job.
;                  Requires MSXML4.0 or greater.
; Related .......:
; Link ..........: http://tidy.sourceforge.net
; Example .......: Yes
; ================================================================================
Func _Config_Indent($szFileName, $iEncoding = 0)
	Local $oOutput = ObjCreate("MSXML2.DOMDocument.4.0")
	Local $oReader = ObjCreate("MSXML2.SAXXMLReader.4.0")
	Local $oWriter = ObjCreate("MSXML2.MXXMLWriter.4.0")
	If @error Then
		$oWriter = ObjCreate("MSXML2.MXXMLWriter.6.0")
		If @error Then Return SetError(1, 0, 0)
	EndIf
	If $iEncoding <= 0 Or $iEncoding > UBound($XML_ENCODING) Then $iEncoding = $XML_ENCODING[0]
	$oWriter.indent = True
	$oWriter.byteOrderMark = True
	$oWriter.encoding = $XML_ENCODING[$iEncoding]
	$oWriter.omitXMLDeclaration = False
	$oWriter.standalone = True
	$oReader.contentHandler = $oWriter
	$oReader.parseURL($szFileName)
	$oOutput.loadXML($oWriter.output)
	$oOutput.save($szFileName)
	$oReader = 0
	$oWriter = 0
	$oOutput = 0
EndFunc   ;==>_Config_Indent

; #FUNCTION# ===================================================================
; Name ..........: _Config_Base64_Encode
; Description ...: Encodes the data input to base64.
; Syntax ........: _Config_Base64_Encode($vData)
; Parameters ....: $vData - The base64 string to Encode
; Return values .: Success - The encoded base64 string.
;                  Failure -0 or empty string ("") and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: This fails to produce desired results unless using AutoIt ver 3.3.0.0
;                  or greater as byte array support for COM was not included previously.
; Related .......:
; Link ..........:
; Example .......: yes
; ================================================================================
Func _Config_Base64_Encode($vData)
	Local $err, $oXML
	If StringLeft(@AutoItVersion, 3) = "3.3" Then
		$oXML = ObjCreate("MSXML2.DOMDocument")
		$oXML.loadXML("<root/>")
		$oXML.documentElement.dataType = "bin.base64"
		If IsString($vData) Then $vData = StringToBinary($vData)
		$oXML.documentElement.NodeTypedValue = $vData
		Local $vRet = $oXML.documentElement.Text
		$err = @error
		$oXML = 0
		Return SetError(($err <> 0 Or $vRet = ""), $err, $vRet)
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_Config_Base64_Encode

; #FUNCTION# ===================================================================
; Name ..........: _Config_Base64_Decode
; Description ...: Decodes a Base64 string to binary.
; Syntax ........: _Config_Base64_Decode($vData, $iFlag = 0)
; Parameters ....: $vData - The base64 string to decode
;                  $iFlag - Set return type 0 = binary, anything else = text(String).
; Return values .: Success - The decoded base64 string in binary or text.
;                  Failure - @error set to 1.  Return value may contain an error message.
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......: This fails to produce desired results unless using AutoIt ver 3.3.0.0
;                  or greater as byte array support for COM was not included previously.
; Related .......:
; Link ..........:
; Example .......: yes
; ================================================================================
Func _Config_Base64_Decode($vData, $iFlag = 0)
	Local $oXML, $vRet, $err = 0
	If StringLeft(@AutoItVersion, 3) = "3.3" Then
		$oXML = ObjCreate("MSXML2.DOMDocument")
		$oXML.loadXML("<root/>")
		$oXML.documentElement.dataType = "bin.base64"
		$oXML.documentElement.text = $vData
		$vRet = $oXML.documentElement.NodeTypedValue
		$err = @error
		$oXML = 0
		If $iFlag Then Return SetError(($err <> 0), $err, BinaryToString($vRet))
		Return SetError(($err <> 0), $err, $vRet)
	EndIf
	Return SetError(1, 0, "")
EndFunc   ;==>_Config_Base64_Decode


; #INTERNAL_USE_ONLY# ============================================================
; Name ..........: __Config_CreateKeyRecursive
; Description ...: Recursive method to create parameter key.
; Syntax ........: __Config_CreateKeyRecursive(ByRef $hConfig, $szParam, $vValue)
; Parameters ....: $hConfig - The config file handle
;                  $szParam - The name of the parameter to create.
;                  $vValue - The value of the parameter.
; Return values .: Succes - 1
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......; No
; ================================================================================
Func __Config_CreateKeyRecursive(ByRef $hConfig, $szParam, $vValue)
	If Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	Local $aTemp = StringSplit($szParam, "\/")
	Local $objKey
	Local $sPath = "/" & $hConfig.documentElement.NodeName
	For $x = 1 To $aTemp[0]
		If Not __Config_KeyExists($hConfig, $sPath & "/" & $aTemp[$x]) Then
			Local $objChild = $hConfig.createNode($NODE_XML_ELEMENT, $aTemp[$x], "")
			If $x = $aTemp[0] Then $objChild.text = $vValue
			If $x = 1 Then
				$hConfig.documentElement.appendChild($objChild)
			Else
				$objKey = $hConfig.selectSingleNode($sPath)
				$objKey.appendChild($objChild)
			EndIf
		EndIf
		$sPath &= "/" & $aTemp[$x]
	Next
	Local $szFileName = __Config_GetFileFromHandle($hConfig)
	If $szFileName <> "" Then
		$hConfig.save($szFileName)
	EndIf
	Return 1
EndFunc   ;==>__Config_CreateKeyRecursive

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_KeyExists
; Description ...: Check if a node name exists
; Syntax ........: __Config_KeyExists(ByRef $hConfig, $szParam)
; Parameters ....: $hConfig - The config file handle
;                  $szParam - The name of the parameter to check for.
; Return values .: Success - 1
;                  Failure - 0
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......; no
; ================================================================================
Func __Config_KeyExists(ByRef $hConfig, $szParam)
	If StringStripWS($szParam, 3) = "" Then Return SetError(1, 0, "")
	If Not IsObj($hConfig) Then Return SetError(1, 0, 0)
	Local $node = $hConfig.documentelement.selectSingleNode($szParam)
	If IsObj($node) Then
		$node = 1
	Else
		$node = 0
	EndIf
	Return $node
EndFunc   ;==>__Config_KeyExists

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_GetFileFromHandle
; Description ...:
; Syntax ........: __Config_GetFileFromHandle(ByRef $hConfig)
; Parameters ....: $hConfig - The config file handle
; Return values .: Success - The filename and @extended contains the index in the cache
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: no
; ================================================================================
Func __Config_GetFileFromHandle(ByRef $hConfig)
	For $x = 1 To $aCONFIG_FHDS[0][0]
		If $hConfig = $aCONFIG_FHDS[$x][0] Then Return SetError(0, $x, $aCONFIG_FHDS[$x][1])
	Next
	Return SetError(1, 0, 0)
EndFunc   ;==>__Config_GetFileFromHandle

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_SetFileToHandle
; Description ...: Add or changes the file handle to filename association in the handle cache.
; Syntax ........: __Config_SetFileToHandle(ByRef $hConfig , $szFileName)
; Parameters ....: $hConfig    - The config file handle
;                  $szFileName - The filename to associate with the handle
; Return values .: Success -  1
;                  Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: no
; ================================================================================
Func __Config_SetFileToHandle(ByRef $hConfig, $szFileName)
	If IsObj($hConfig) And $szFileName <> "" Then
		If __Config_GetFileFromHandle($hConfig) <> "" Then
			$aCONFIG_FHDS[@extended][1] = $szFileName
		Else
			$aCONFIG_FHDS[0][0] += 1
			ReDim $aCONFIG_FHDS[$aCONFIG_FHDS[0][0] + 1][2]
			$aCONFIG_FHDS[$aCONFIG_FHDS[0][0]][0] = $hConfig
			$aCONFIG_FHDS[$aCONFIG_FHDS[0][0]][1] = $szFileName
		EndIf
		Return 1
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>__Config_SetFileToHandle

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_RemoveFileHandle
; Description ...: Removes a file handle and it's associated filename from the cache.
; Syntax ........: __Config_RemoveFileHandle(ByRef $hConfig)
; Parameters ....: $hConfig - The config file handle
; Return values .: Success -  The index of the removed item
;                  Failure -  0 and @error set to 1
; Author ........: Stephen Podhajecki (eltorro)
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: no
; ================================================================================
Func __Config_RemoveFileHandle(ByRef $hConfig)
	For $x = 1 To $aCONFIG_FHDS[0][0]
		If $hConfig = $aCONFIG_FHDS[$x][0] Then
			For $y = $x To $aCONFIG_FHDS[0][0] - 1
				$aCONFIG_FHDS[$y][0] = $aCONFIG_FHDS[$y + 1][0]
				$aCONFIG_FHDS[$y][1] = $aCONFIG_FHDS[$y + 1][1]
			Next
			$aCONFIG_FHDS[0][0] -= 1
			ReDim $aCONFIG_FHDS[$aCONFIG_FHDS[0][0] + 1][2]
			Return $x
		EndIf
	Next
	Return SetError(1, 0, 0)
EndFunc   ;==>__Config_RemoveFileHandle

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_COMErr
; Description ...: Sven com error handler
; Syntax ........: __Config_COMErr()
; Parameters ....: None.
; Return values .: @Error set to 1 and @Extended set to the COM error number.
; Author ........:
; Modified.......:
; Remarks .......: Default error handler.
; Related .......: __Config_InitCOMErr
; Link ..........:
; Example .......: no
; ================================================================================
Func __Config_COMErr()
	Local $HexNumber = Hex($__COM_ERR.number, 8)
	If @error Then Return SetError(1, 0, 0)
	Local $msg = "COM Error with DOM!" & @CRLF & @CRLF & _
			"err.description is: " & @TAB & $__COM_ERR.description & @CRLF & _
			"err.windescription:" & @TAB & $__COM_ERR.windescription & @CRLF & _
			"err.number is: " & @TAB & $HexNumber & @CRLF & _
			"err.lastdllerror is: " & @TAB & $__COM_ERR.lastdllerror & @CRLF & _
			"err.scriptline is: " & @TAB & $__COM_ERR.scriptline & @CRLF & _
			"err.source is: " & @TAB & $__COM_ERR.source & @CRLF & _
			"err.helpfile is: " & @TAB & $__COM_ERR.helpfile & @CRLF & _
			"err.helpcontext is: " & @TAB & $__COM_ERR.helpcontext
	;MsgBox(0, @AutoItExe, $msg)
	SetError(1, $__COM_ERR.number, $msg)
EndFunc   ;==>__Config_COMErr

; #INTERNAL_USE_ONLY#=============================================================
; Name ..........: __Config_InitCOMErr
; Description ...: Initialize the COM error event handler.
; Syntax ........: __Config_InitCOMErr([$sFunction])
; Parameters ....: $sFunction - Function for COM error handler
; Return values .: None.
; Author ........:
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: [yes/no]
; ================================================================================
Func __Config_InitCOMErr($sFunction = "__Config_COMErr")
	If $__COM_ERR <> "" Then $__COM_ERR = ""
	$__COM_ERR = ObjEvent("AutoIt.Error", $sFunction) ; ; Initialize SvenP 's  error handler
EndFunc   ;==>__Config_InitCOMErr