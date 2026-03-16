[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-Privilege {
    param(
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    if (-not ("TokenAdjuster" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class TokenAdjuster
{
    private const uint TOKEN_QUERY = 0x0008;
    private const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    private const uint SE_PRIVILEGE_ENABLED = 0x00000002;

    [StructLayout(LayoutKind.Sequential)]
    private struct LUID
    {
        public uint LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct TOKEN_PRIVILEGES
    {
        public uint PrivilegeCount;
        public LUID Luid;
        public uint Attributes;
    }

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool AdjustTokenPrivileges(
        IntPtr TokenHandle,
        bool DisableAllPrivileges,
        ref TOKEN_PRIVILEGES NewState,
        int BufferLength,
        IntPtr PreviousState,
        IntPtr ReturnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    public static void Enable(string privilege)
    {
        IntPtr tokenHandle;
        if (!OpenProcessToken(Process.GetCurrentProcess().Handle, TOKEN_QUERY | TOKEN_ADJUST_PRIVILEGES, out tokenHandle))
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            LUID luid;
            if (!LookupPrivilegeValue(null, privilege, out luid))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            TOKEN_PRIVILEGES tokenPrivileges = new TOKEN_PRIVILEGES
            {
                PrivilegeCount = 1,
                Luid = luid,
                Attributes = SE_PRIVILEGE_ENABLED
            };

            if (!AdjustTokenPrivileges(tokenHandle, false, ref tokenPrivileges, 0, IntPtr.Zero, IntPtr.Zero))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            int lastError = Marshal.GetLastWin32Error();
            if (lastError != 0)
            {
                throw new Win32Exception(lastError);
            }
        }
        finally
        {
            CloseHandle(tokenHandle);
        }
    }
}
"@
    }

    foreach ($privilege in $Name) {
        [TokenAdjuster]::Enable($privilege)
    }
}

function Set-RegistryKeyOwnerAndPermissions {
    param(
        [Parameter(Mandatory)]
        [string]$SubKeyPath,

        [Parameter(Mandatory)]
        [System.Security.Principal.IdentityReference]$Owner,

        [Parameter(Mandatory)]
        [System.Security.Principal.NTAccount]$Principal
    )

    $registryView = if ([Environment]::Is64BitOperatingSystem) {
        [Microsoft.Win32.RegistryView]::Registry64
    } else {
        [Microsoft.Win32.RegistryView]::Default
    }

    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        $registryView
    )

    try {
        $takeOwnershipRights =
            [System.Security.AccessControl.RegistryRights]::ReadKey -bor
            [System.Security.AccessControl.RegistryRights]::ReadPermissions -bor
            [System.Security.AccessControl.RegistryRights]::TakeOwnership

        $key = $baseKey.OpenSubKey(
            $SubKeyPath,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            $takeOwnershipRights
        )

        if ($null -eq $key) {
            throw "Registry key not found: HKLM\$SubKeyPath"
        }

        try {
            $acl = $key.GetAccessControl()
            $acl.SetOwner($Owner)
            $key.SetAccessControl($acl)
        }
        finally {
            $key.Dispose()
        }

        $changePermissionsRights =
            [System.Security.AccessControl.RegistryRights]::ReadKey -bor
            [System.Security.AccessControl.RegistryRights]::ReadPermissions -bor
            [System.Security.AccessControl.RegistryRights]::ChangePermissions

        $key = $baseKey.OpenSubKey(
            $SubKeyPath,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            $changePermissionsRights
        )

        if ($null -eq $key) {
            throw "Registry key not found after ownership change: HKLM\$SubKeyPath"
        }

        try {
            $acl = $key.GetAccessControl()
            $rule = [System.Security.AccessControl.RegistryAccessRule]::new(
                $Principal,
                [System.Security.AccessControl.RegistryRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $acl.SetAccessRule($rule)
            $key.SetAccessControl($acl)
        }
        finally {
            $key.Dispose()
        }
    }
    finally {
        $baseKey.Dispose()
    }
}

if (-not (Test-IsAdministrator)) {
    throw "Run this script from an elevated PowerShell session."
}

Enable-Privilege -Name "SeTakeOwnershipPrivilege", "SeRestorePrivilege"

$administratorsSid = [System.Security.Principal.SecurityIdentifier]::new("S-1-5-32-544")
$administrators = $administratorsSid.Translate([System.Security.Principal.NTAccount])

$downloadsFolderTypeKeys = @(
    "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{885a186e-a440-4ada-812b-db871b942259}\TopViews\{00000000-0000-0000-0000-000000000000}",
    "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{885a186e-a440-4ada-812b-db871b942259}\TopViews\{00000000-0000-0000-0000-000000000000}"
)

foreach ($subKeyPath in $downloadsFolderTypeKeys) {
    if ($PSCmdlet.ShouldProcess("HKLM\$subKeyPath", "set owner to $administrators and grant FullControl")) {
        Set-RegistryKeyOwnerAndPermissions -SubKeyPath $subKeyPath -Owner $administratorsSid -Principal $administrators
        Write-Host "Updated HKLM\$subKeyPath"
    }
}
