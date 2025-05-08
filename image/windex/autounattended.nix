#Copyright (C) 2020 M-Labs Limited.
{
  writeText,

  fullName ? "John Doe",
  organization ? "KVM Authority",
  uiLanguage ? "en-US",
  inputLocale ? "en-US",
  userLocale ? "en-US",
  systemLocale ? "en-US",
  timeZone ? "UTC",
  imageSelection ? "Windows 11 Pro N",
  productKey ? null,
  users ? {},
  administratorPassword ? null,
  defaultUser ? null,
  setupCommands ? [],
  services ? {},
  impureShellCommands ? [],
  driveLetter ? "D:",
  efi ? true,
  enableTpm ? true,
}: let
  commands = [
    "powershell.exe Set-ExecutionPolicy -Force Unrestricted"
    # Allow unsigned powershell scripts
    "powershell.exe ${driveLetter}\win-bundle-installer.exe"
    # Install any declaed packages
    "net accounts /maxpwage:unlimited"
    # Disable forced password expiry
  ]
  ++ setupCommands
  ++ ["powershell.exe ${driveLetter}\setup.ps1"]
  ++ impureShellCommands;

  mkCommands = commands: let
    toXML = command: order: ''
      <RunSynchronousCommand wcm:action="add">
        <Path>${command}</Path>
        <Description>${command}</Description>
        <Order>${builtins.toString order}</Order>
      </RunSynchronousCommand>
    '';

    mkCommands' = n:
      if n < 0 then ""
      else toXML (builtins.elemAt commands n) n + mkCommands' (n - 1);
    in mkCommands' (builtins.length commands - 1);

  mkUsers = users: let
    toXML = name: {
      password,
      description ? "",
      displayName ? "",
      groups ? ["Users"]
    }: ''
      <LocalAccount wcm:action="add">
        <Password>
          <Value>${password}</Value>
          <PlainText>true</PlainText>
        </Password>
        <Description>${description}</Description>
        <DisplayName>${displayName}</DisplayName>
        <Group>${builtins.concatStringsSep ";" (groups)}</Group>
        <Name>${name}</Name>
      </LocalAccount>
    '';
    in builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs toXML users));

in writeText "autounattended.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
      <settings pass="windowsPE">
        <component name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <DriverPaths>
            <PathAndCredentials wcm:action="add" wcm:keyValue="1">
              <Path>D:\</Path>
            </PathAndCredentials>
            <PathAndCredentials wcm:action="add" wcm:keyValue="2">
              <Path>E:\</Path>
            </PathAndCredentials>
            <PathAndCredentials wcm:action="add" wcm:keyValue="3">
              <Path>C:\virtio\amd64\w10</Path>
            </PathAndCredentials>
            <PathAndCredentials wcm:action="add" wcm:keyValue="4">
              <Path>C:\virtio\NetKVM\w10\amd64</Path>
            </PathAndCredentials>
            <PathAndCredentials wcm:action="add" wcm:keyValue="5">
              <Path>C:\virtio\qxldod\w10\amd64</Path>
            </PathAndCredentials>
          </DriverPaths>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

          <DiskConfiguration>
            <Disk wcm:action="add">
              <CreatePartitions>
                <CreatePartition wcm:action="add">
                  <Order>1</Order>
                  <Type>"EFI"</Type>
                  <Size>300</Size>
                </CreatePartition>
                <CreatePartition wcm:action="add">
                  <Order>2</Order>
                  <Type>$"MSR"</Type>
                  <Size>16</Size>
                </CreatePartition>
                <CreatePartition wcm:action="add">
                  <Order>3</Order>
                  <Type>Primary</Type>
                  <Extend>true</Extend>
                </CreatePartition>
              </CreatePartitions>
              <ModifyPartitions>
                <ModifyPartition wcm:action="add">
                  <Order>1</Order>
                  <Format>"FAT32"</Format>
                  <Label>System</Label>
                  <PartitionID>1</PartitionID>
                </ModifyPartition>
                <ModifyPartition wcm:action="add">
                  <Order>2</Order>
                  <PartitionID>2</PartitionID>
                </ModifyPartition>
                <ModifyPartition wcm:action="add">
                  <Order>3</Order>
                  <Format>NTFS</Format>
                  <Label>Windows</Label>
                  <Letter>C</Letter>
                  <PartitionID>3</PartitionID>
                </ModifyPartition>
              </ModifyPartitions>
              <DiskID>2</DiskID>
              <WillWipeDisk>true</WillWipeDisk>
            </Disk>
          </DiskConfiguration>

          <ImageInstall>
            <OSImage>
              <InstallTo>
                <DiskID>2</DiskID>
                <PartitionID>3</PartitionID>
              </InstallTo>
              <InstallFrom>
                <Path>\install.swm</Path>
                <MetaData wcm:action="add">
                  <Key>/IMAGE/NAME</Key>
                  <Value>${imageSelection}</Value>
                </MetaData>
              </InstallFrom>
            </OSImage>
          </ImageInstall>

          <UserData>
            <ProductKey>
              ${if productKey != null then "<Key>${productKey}</Key>" else "<Key/>"}
              <WillShowUI>OnError</WillShowUI>
            </ProductKey>
            <AcceptEula>true</AcceptEula>
            <FullName>${fullName}</FullName>
            <Organization>${organization}</Organization>
          </UserData>

        </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <SetupUILanguage>
            <UILanguage>${uiLanguage}</UILanguage>
          </SetupUILanguage>
          <InputLocale>${inputLocale}</InputLocale>
          <SystemLocale>${systemLocale}</SystemLocale>
          <UILanguage>${uiLanguage}</UILanguage>
          <UILanguageFallback>en-US</UILanguageFallback>
          <UserLocale>${userLocale}</UserLocale>
        </component>
      </settings>

      <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <InputLocale>${inputLocale}</InputLocale>
          <SystemLocale>${systemLocale}</SystemLocale>
          <UILanguage>${uiLanguage}</UILanguage>
          <UILanguageFallback>en-US</UILanguageFallback>
          <UserLocale>${userLocale}</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideLocalAccountScreen>true</HideLocalAccountScreen>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <ProtectYourPC>1</ProtectYourPC>
          </OOBE>
          <TimeZone>${timeZone}</TimeZone>

          <UserAccounts>
            ${if administratorPassword != null then ''
    <AdministratorPassword>
      <Value>${administratorPassword}</Value>
      <PlainText>true</PlainText>
    </AdministratorPassword>
  '' else ""}
            <LocalAccounts>
              ${mkUsers users}
            </LocalAccounts>
          </UserAccounts>

          ${if defaultUser == null then "" else ''
    <AutoLogon>
      <Password>
        <Value>${(builtins.getAttr defaultUser users).password}</Value>
        <PlainText>true</PlainText>
      </Password>
      <Enabled>true</Enabled>
      <Username>${defaultUser}</Username>
    </AutoLogon>
  ''}

        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <Reseal>
            <ForceShutdownNow>true</ForceShutdownNow>
            <Mode>OOBE</Mode>
          </Reseal>
        </component>
      </settings>

      <settings pass="specialize">
          <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <RunSynchronous>
                ${mkCommands commands}
              </RunSynchronous>
          </component>
          <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="NonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <CEIPEnabled>0</CEIPEnabled>
          </component>
      </settings>

      <!-- Disable Windows UAC -->
      <settings pass="offlineServicing">
        <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <EnableLUA>false</EnableLUA>
        </component>
      </settings>

       <cpi:offlineImage cpi:source="wim:c:/wim/windows-11/install.wim#${imageSelection}" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
    </unattend>
  ''

