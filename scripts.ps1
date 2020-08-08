# We use upstream msys2 to build packages because the runtime from rtools may
# be out of sync with the upstream core build utilities.
Function InstallMSYS64 {
	Write-Host "Installing MSYS2 64-bit..." -ForegroundColor Cyan
	$zipPath = "$($env:USERPROFILE)\msys2-x86_64-latest.tar.xz"
	$tarPath = "$($env:USERPROFILE)\msys2-x86_64-latest.tar"

	Write-Host "Downloading MSYS installation package..."
	(New-Object Net.WebClient).DownloadFile('https://github.com/msys2/msys2-installer/releases/download/2020-05-17/msys2-base-x86_64-20200517.tar.xz', $zipPath)

	Write-Host "Untaring installation package..."
	7z x $zipPath -y -o"$env:USERPROFILE" | Out-Null

	Write-Host "Unzipping installation package..."
	7z x $tarPath -y -oC:\ | Out-Null
	del $zipPath
	del $tarPath

	Write-Host "Initiating pacman..."
	C:\msys64\usr\bin\bash.exe --login -c exit

	# Workaround: revert to working version of pacman right now (avoid zstd/runtime breakage) remove when this is fixed upstream
	C:\msys64\usr\bin\pacman --noconfirm -Sy
	C:\msys64\usr\bin\pacman --noconfirm --needed -S bash pacman
	C:\msys64\usr\bin\pacman --noconfirm -Suu
	taskkill /IM gpg-agent.exe /F
	taskkill /IM dirmngr.exe /F
}

##### Old stuff ###

$RTOOLS_ARCH = ${env:RTOOLS_ARCH}
$RTOOLS_ZIP = "rtools40-${RTOOLS_ARCH}.7z"
$RTOOLS_EXE = "rtools40-${RTOOLS_ARCH}.exe"
#$ErrorActionPreference = "Stop";

### Use for bootstrapping installation
$RTOOLS_MIRROR = "https://dl.bintray.com/rtools/installer/"
# $RTOOLS_MIRROR = "https://cloud.r-project.org/bin/windows/Rtools/"
# $RTOOLS_MIRROR = "https://ftp.opencpu.org/archive/rtools/4.0/"

function CheckExitCode($msg) {
  if ($LastExitCode -ne 0) {
    Throw $msg
  }
}

# Unzip and Initiate Rtools dump
Function InstallRtoolsZip {
	Write-Host "Installing ${RTOOLS_ZIP}..." -ForegroundColor Cyan
	$tmp = "$($env:USERPROFILE)\${RTOOLS_ZIP}"
	(New-Object Net.WebClient).DownloadFile($RTOOLS_MIRROR + $RTOOLS_ZIP, $tmp)
	7z x $tmp -y -oC:\ | Out-Null
	CheckExitCode "Failed to extract ${RTOOLS_ZIP}"
	C:\rtools40\usr\bin\bash.exe --login -c exit 2>$null
	Write-Host "Installation of ${RTOOLS_ZIP} done!" -ForegroundColor Green
}

# Don't use installer when: (1) architecture doesn't match host (2) Dir C:/rtools40 already exists
Function InstallRtoolsExe {
	if ( Test-Path C:\rtools40 ) {
		Write-Host "Existing rtools40 found. Skipping installation."
	} else {
		Write-Host "Installing ${RTOOLS_EXE}..." -ForegroundColor Cyan
		$tmp = "$($env:USERPROFILE)\${RTOOLS_EXE}"
		(New-Object Net.WebClient).DownloadFile($RTOOLS_MIRROR + $RTOOLS_EXE, $tmp)
		Start-Process -FilePath $tmp -ArgumentList /VERYSILENT -NoNewWindow -Wait
		Write-Host "Installation of ${RTOOLS_EXE} done!" -ForegroundColor Green
	}
}

function bash($command) {
    Write-Host $command -NoNewline
    cmd /c start /wait C:\rtools40\usr\bin\sh.exe --login -c $command
    Write-Host " - OK" -ForegroundColor Green
}

function InstallRtools {
	InstallRtoolsExe
	bash 'pacman -Sy --noconfirm pacman pacman-mirrors'
	bash 'pacman -Syyu --noconfirm --ask 20'		
}
