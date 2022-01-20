
strComputer = "."

Set ListAdapters = CreateObject("System.Collections.ArrayList")
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration where IPEnabled = TRUE")



If WScript.Arguments.Length = 0 Then
  Set ObjShell = CreateObject("Shell.Application")
  ObjShell.ShellExecute "wscript.exe" _
    , """" & WScript.ScriptFullName & """ RunAsAdministrator", , "runas", 1
  WScript.Quit
End if

Dim arrayAdapters : arrayAdapters = Array()
i = 0
endCheck = True
title = title & "Lista dostepnych interfejsow sieciowych:" & vbCrLf

For Each adapter in IPConfigSet
    i = i + 1    
    adapterName = adapterName & adapter.Description
    msg = msg & "["&i&"]: " & adapter.Description & vbCrLf 
    ' Rozszerzam rozmiar tablicy aby dodawac do niej bierzace elementy, w moim przypadku Description
    ' bedzie to moj odnosnik do zapytania dla okreslonego interfejsu sieciowego
    Redim Preserve arrayAdapters(UBound(arrayAdapters) +1)
    arrayAdapters(UBound(arrayAdapters)) = adapter.Description
Next

' Walidacja wyboru adapteru
While endCheck
    inputChoose = InputBox(title & msg)
    if (CInt(inputChoose) > i) Then
        MsgBox "Nie ma takiego interfejsu, wybierz ponownie"
    Else
        ' displayInfo(inputChoose)
        configuration(inputChoose)
        endCheck = False
    end if
Wend

' Funkcja ktora sluzy do wyswietlania informacji wybranego interfejsu
Function displayInfo(Choose)
    ' Tutaj do zapytania dodaje Description do ktorego przekazuje parametr zeby odwolac sie do konkretnego interfejsu
    ' arrayAdapters(Choose - 1) - interfejs na liscie wybru zaczyna sie od 1 a wartosci tablicy startuja od 0
    Set AdapterInfo = objWMIService.ExecQuery _
        ("Select * from Win32_NetworkAdapterConfiguration where IPEnabled = TRUE and Description = '"&arrayAdapters(Choose - 1)&"'")

    adapterDNS = ""

    for Each value in AdapterInfo
        adapterName = value.Description(0)
        Mask = dapterName & value.Description(0)
        adapterIP = value.IPAddress(0)
        adapterMask = value.IPSubnet(0)

        If not isNull(value.DefaultIPGateway) Then
            adapterGate = value.DefaultIPGateway(0)
        Else
            adapterGate = "Brak bramy domyslnej"
        End If
        
        If not IsNull(value.DNSServerSearchOrder) Then
            For i = 0 To UBound(value.DNSServerSearchOrder)
                adapterDNS = adapterDNS & value.DNSServerSearchOrder(i) & "    "
            Next
        Else
            adapterDNS = "Brak servera DNS"
        End If

        displayInfo = "Nazwa: " & adapterName & vbCrLf & "Adress IPv4: " & adapterIP & vbCrLf & "Maska: " & adapterMask & vbCrLf & "Brama domyslna: " &  adapterGate & vbCrLf & "DNS Server: " & adapterDNS & vbCrLf
    Next
End Function

' Funkcja ktora sluzy do wyboru parametru ktory uzytkownik chce zmienic
Function configuration(Choose)
    Set AdapterChange = objWMIService.ExecQuery _
        ("Select * from Win32_NetworkAdapterConfiguration where IPEnabled = TRUE and Description = '"&arrayAdapters(Choose - 1)&"'")
    endLoop = True
    user_input = Choose

    While endLoop
        currentAdapterValues = displayInfo(Choose)
        info = currentAdapterValues & vbCrLf & "Wybierz wartosc ktora chcesz edytowac" & vbCrLf & "[1] Adres IP" & vbCrLf & "[2] Maska podsieci" & vbCrLf & "[3] Brama" & vbCrLf & "[4] Server DNS" & vbCrLf & "[5] Wyjscie"
        inputEditChoose = InputBox(info)

        Select Case inputEditChoose
            case 1
                configIP(AdapterChange)
            case 2
                configMask(AdapterChange)      
            case 3
                configGate(AdapterChange)
            case 4
                configDNS(AdapterChange)
            case 5
                endLoop = False
        End Select
    Wend
End Function


' Funkcje z poczatkiem config% sluza do zmiany parametrow 
Function configIP(Ask)
     for each value in Ask
        adapterIPCurrent = value.IPAddress(0)
        adapterMask = value.IPSubnet(0)
    Next

    inputChangeIP = InputBox("Aktualny adres IP: " & adapterIPCurrent)
    inputChangeMask = inputBox("Aktualna maska: " & adapterMask)

    for Each value in Ask 
        inputChangeIPArray = Array(inputChangeIP)
        subnetArray = Array(inputChangeMask)
        
        errIP = value.EnableStatic(inputChangeIPArray, subnetArray)
        if (errIP = 0) Then
            MsgBox "Parametry zostaly zmienione na: " & vbCrLf & "IP: " & inputChangeIP & vbCrLf & "Maska: " & inputChangeMask 
        Else
            MsgBox "Blad przy zmianie parametrow"
        End If
    Next
End Function    


Function configMask(Ask)
    inputChangeMask = InputBox("Podaj maske: " & adapterMaskCurrent)  

    for Each value In Ask
        IPArray = Array(value.IPAddress(0))
        inputChangeMaskArray = Array(inputChangeMask)

        errMask = value.EnableStatic(IPArray, inputChangeMaskArray)
        if (errMask = 0) Then
            MsgBox "Maska zostala zmieniona na: " & inputChangeMask
        Else
            MsgBox "Blad przy zmianie maski"
        End If
    Next
End Function


Function configGate(Ask)
    inputChangeGateway = InputBox("Podaj brame: " & adapterGatewayCurrent) 

    adapterGatewayArray = Array(inputChangeGateway)
    adapterGatewayMetricArray = Array(1)

    for each value in Ask
        errGateway = value.SetGateways(adapterGatewayArray, adapterGatewayMetricArray)
        if (errGateway = 0) Then
            MsgBox "Brama zostala zmieniona na: " & inputChangeGateway
        Else
            MsgBox "Blad przy zmianie bramy"
        End If
    Next
End Function


Function configDNS(Ask)
    inputDNSPref= InputBox("Podaj adres preferowany: ") 
    inputDNSAlter = InputBox("Podaj adres alternatywny: ")

    dnsServers = Array(inputDNSPref, inputDNSAlter)

    for Each dns in Ask
        errDNS = dns.SetDNSServerSearchOrder(dnsServers)
        if (errDNS = 0) Then
            MsgBox ("Servery DNS zostaly zmienione na: " & vbCrLf & "DNS Preferowany:   " & inputDNSPref & vbCrLf & "DNS Alternatywny:  " & inputDNSAlter)
        Else
            MsgBox "Blad przy zmianie DNS"
        End If
    Next
End Function