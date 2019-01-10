using namespace System
using namespace System.Collections

class Menu {
    ## Properties 
    [ArrayList]$MenuItems = @()
    [string]$Menu
    [object]$ReturnObject
    [ArrayList]$ReturnBuildList = @()

    ## Constructor
    Menu([Array[]]$items) {
        foreach ($item in $items) {
            [void]$this.MenuItems.Add($item)
        }

        $this.MakeMenu()
        
    }

    Menu() {
        
    }

    [void] MakeMenu () {
        ## Instantiate new stringbuilder instance
        $sb = [System.Text.StringBuilder]::new()
        $count = 1
        foreach ($item in $this.MenuItems) {
            
            $sb.Append("[$count] $item")
            $sb.AppendLine()
            $count ++
        }

        $this.Menu = $sb.ToString()
        
    }

    [object] RenderMenu(){
        ##clear-host
        while ($true) {
            [Menu]::WriteLine($this.Menu)
            $UserSelected =  [menu]::Prompt()
            $this.ReturnObject = $this.MenuItems[$UserSelected -1]
            break
        }

        return $this.ReturnObject
    }

    [object] RenderMenu($Message) {      
        ##clear-host
        [Menu]::WriteLine($Message)
        while ($true) {
            [Menu]::WriteLine($this.Menu)
            $UserSelected =  [menu]::Prompt()
            $this.ReturnObject = $this.MenuItems[$UserSelected -1]
            break
        }

        return $this.ReturnObject
    }

    [ArrayList] RenderListBuilderMenu($Message, $ObjectName) {      
        while ($this.MenuItems.Count -ne 0) {
            ##clear-host
            [console]::WriteLine("{0} `tType 'quit' to exit",$Message)
            if ($this.MenuItems -eq 0) {
                break
            }
            [Menu]::WriteLine($this.Menu)
            $UserSelected =  [menu]::Prompt()
            if ($UserSelected -eq "quit") {
                
                break
            }
            try {
                $UserSelectedConverted = [convert]::ToInt32($UserSelected)
            }
            catch {
                continue
            }
            $currentItem = $this.MenuItems[$UserSelectedConverted -1]
            $this.ReturnBuildList.Add($currentItem)
            $this.MenuItems.Remove($currentItem)
            ##clear-host
            [Menu]::WriteLine("Press ENTER to continue to add $ObjectName")
            $UserInput = [console]::ReadKey()
            if ($UserInput.Key -eq "Enter") {
                if ($this.MenuItems.Count -eq 0) {
                    break
                }
                $this.MakeMenu()
                continue
            }
            else {

                break
            }
            
        }
        ##clear-host
        return $this.ReturnBuildList
    }

    static [string] Prompt()
    {
        
        [console]::ForegroundColor = "white"
        $userInput = Read-Host "`nVDT>>"
        return $userInput
    }

    static [bool] Confirm($Answer)
    {

        $TruthTest = $true
        while ($true) {

            [console]::ForegroundColor = "Yellow"
            Write-Host "Is $Answer correct?`tType 'YES' or 'NO'"
            $UserSelected = [menu]::Prompt()
            if ($userSelected -eq "Yes") {
                $TruthTest = $true
                break
            }
            else {
                $TruthTest = $false
                break
            }
        }

        return $TruthTest
    }

    static [void] WriteLine($SomeThingToSay)
    {
        [console]::ForegroundColor = "Yellow"
        [console]::WriteLine($SomeThingToSay)
        [console]::ForegroundColor = "White"

    }
}

#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
$certAction = Get-PowerCLIConfiguration
foreach ($cert in $certAction)
{
    if ($cert.invalidcertificateaction -ne "Ignore")
    {
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    }
}

function Get-VAppVMsToRename {
    $VMsToRenameMenu = [menu]::new(($Global:MTC_Students_vAPP | Get-VM | Sort-Object -Unique))
    $VMsToRename = $VMsToRenameMenu.RenderListBuilderMenu("Select VM's to rename", "VM")
    $VMnames = @{}
    foreach ($vm in $VMsToRename) {
        
        while ($true) {
            
            Write-Host "`nWhat would you like to rename $($VM.Name) to?"
            $newVMName = [menu]::Prompt()
            $confirmStatus = [menu]::Confirm($newVMName)
            if ($confirmStatus -eq $true) {
                
                $VMnames.Add($newVMName, $vm.Name)
                break
            }
            else{
                
                continue
            }
        }
    }
    return $VMnames
}

function Invoke-RenameWindowsGuestHostName {
    param (
        [hashtable]$VMNames
    )


    [menu]::WriteLine("Enter local administrator credentials to rename guest operating systems")
    [pscredential]$LocalAdministratorCreds = (Get-Credential)
    # VMNames hashtable values are Vmware inventory names.  The keys are the new names to rename the OS's to.
    $VmsToBeRenamed = $Global:MTC_Students_vAPP | Get-VM | Where-Object {$VMNames.ContainsValue($_.Name)}
    foreach ($vm in $VmsToBeRenamed) {
        
        $vmvApp = $vm.VApp
        $regex = [regex]::match($vmvApp, 'Student \d{3}')
        $studentNumber = ($reg.Value.Split(" "))[1]
        $NewVMName = $VMNames.Keys |? { $VMNames[$_] -eq $vm.Name }
        $NewVMNameFormatted = "$NewVMName$studentNumber"
        Invoke-RenameComputer -vmwareVM $VM.Name -vmwareGestOSName $NewVMNameFormatted -Credential $LocalAdministratorCreds
        
    }

    
}

function GuestOSManagement () {

    $OperatingSystems = @("Windows", "Linux")
    $OperatingSystemsMENU = [menu]::new($OperatingSystems)
    [string]$userSelected = $OperatingSystemsMENU.RenderMenu("Choose OS")
    if ($userSelected -eq "Windows") {
        
        # Windows Task
        $WindowsTask = @("Rename Computer", "...")
        $WindowsMenu = [menu]::new($WindowsTask)
        [string]$userSelected = $WindowsMenu.RenderMenu("Select a task to run?")
        $userSelectedConverted = ($WindowsTask.IndexOf($userSelected)) + 1
        switch ($userSelectedConverted) 
        {
            
            1{ 
                $VMNames = Get-VAppVMsToRename
                Invoke-RenameWindowsGuestHostName -VMNames $VmsToBeRenamed
            }
            Default {GuestOSManagement}
        }
    }
    else{
        # Do some linux stuff
    }

    RenderMainMenu

}

function RenderMainMenu {
    Clear-Host
    $MainMenuItems = @("VM Options", "Clean Slate", "Deploy VApp", "Network Settings", "DSC Options", "Reset Student Passwords", "Guest OS Management", "Help", "Disconnect")
    $MainMenu = [menu]::new($MainMenuItems)
    $MainMenuMessage = "


    *******************
    *    MAIN MENU    *
    *******************


    "

    # We cast the return object to type string so we can do a indexof lookup to get a int for our switch
    [string]$userSelected = $MainMenu.RenderMenu($MainMenuMessage)
    $userSelectedConverted = $null
    $userSelectedConverted = ($MainMenuItems.IndexOf($userSelected)) + 1
    ###clear-host
    while ($userSelectedConverted -ne 9)
    {

        switch ($userSelectedConverted)
        {
            1 {vmOptions}    
            2 {
                Stopwatch $sw
                CleanSlate
                Stopwatch $sw
            }
            3 {
                Stopwatch $sw
                DeployVapp
                Stopwatch $sw
            }
            4 {NetworkOptions}
            5 {DSCOptions}
            6 {
                Stopwatch $sw
                Reset-Passwords
                Stopwatch $sw-
            }
            7 {GuestOSManagement}
            8 {Help_File}
            #Disconnect From VCSA
            9 {Disconnect}
        }
        clear-host
    }
}
###clear-host
# Main Loop
function Main ()
{
    Connect
    ###clear-host
    [Menu]::WriteLine("Is this the first time you are running the VDT?`tType YES or NO")
    $UserInput = [menu]::Prompt()
    while ($userInput -ne "yes" -and $userInput -ne "no") {
        
        [menu]::WriteLine("Is this the first time you are running the VDT?`tType YES or NO")
        $UserInput = [menu]::Prompt()
    }

    if ($userInput -like "*yes*") {
        
        Set-EnvironmentForFirstUse
    }

    Write-Host "
    *********************************
    *   Virtual Deployment Toolkit  *
    *********************************

    "
    Write-Host "Read the help file before using the tool.

    "

    read-host "Press Enter To Continue"

    $Global:MTC_Students_vAPP = Get-Folder 'Students' | Get-VApp
    $Global:MTC_Students_Folders = Get-Folder -name 'Students' | Get-Folder -NoRecursion | Sort-Object
    Start-Sleep 1
    Clear-Host
    RenderMainMenu

       
}

# Network Options Menu
function NetworkOptions
{
    ###clear-host
    $userInput3 = 0
    while ($userInput3 -ne 9)
    {
    Write-Host "
********************
* NETWORK SETTINGS *
********************


[1] Blowout Network Configs
[2] Network Provision
[3] Generate vApp CSV
[9] Back "

    $userInput3 = [menu]::Prompt()
                
    switch ($userInput3)
    {
        1 {Blowout-Networking}
        2 {ProvisonNetwork}
        3 {
            ###clear-host
            Write-Host "Select the vApp that you want to make a blank CSV for."
            $CSVvApp = SelectVapp
            generateCSV ($CSVvApp)
          }
        9 {RenderMainMenu}
        }
    ###clear-host
    }
}

# vm options menu
function vmOptions()
{
    Clear-Host
    $VMOPtionsMenuItems = @("Power On VM(s)", "Power Off VM(s)", "Deploy VM(s)", "Delete VM(s)", "Take Snapshot of VM(s)", "Snapshot Options", "Clear VApp Range")
    $VMOPtionsMenu = [menu]::new($VMOPtionsMenuItems)
    $VMOPtionsMenuMessage = "

    ********************
    *    VM Options    *
    ********************

    "

    # We cast the return object to type string so we can do a indexof lookup to get a int for our switch
    [string]$userSelected = $VMOPtionsMenu.RenderMenu($VMOPtionsMenuMessage)
    $userSelectedConverted = $null
    $userSelectedConverted = ($VMOPtionsMenuItems.IndexOf($userSelected)) + 1
    ###clear-host
    while ($true)
    {

        switch ($userSelectedConverted)
        {
            1 
            { 
                [Menu]::WriteLine("What VM(s) do you want to start?")
                $VM_Name = [menu]::Prompt()
                Stopwatch $sw
                PowerOn($VM_Name)
                Stopwatch $sw
            }
                  
            2 
            { 
                [Menu]::WriteLine("What VM(s) do you want to Shutdown?")
                $VM_Name = [Menu]::Prompt()
                Stopwatch $sw
                PowerOff($VM_Name)
                Stopwatch $sw
            }

            3 {
                Stopwatch $sw
                deployTemp
                Stopwatch $sw
              }

            4
            {
                [Menu]::WriteLine("What VM(s) do you want to delete?")
                $VM_Name = [Menu]::Prompt()
                Stopwatch $sw
                DeleteVM($VM_Name)    
                Stopwatch $sw
            }

            5 {
                Stopwatch $sw
                Snapshot
                Stopwatch $sw
              }

            6 {revertToSnapshotMenu}

            7 
              {
                Stopwatch $sw
                Clear-Vapp-Range
                Stopwatch $sw
              }

            default 
            {
                RenderMainMenu
            }        
        }
        ###clear-host 
    }
}

#removes VPGs from all student VMS add them to blackhole and deletes VPGs from VDS
function Blowout-Networking () 
{   
    ###clear-host
    $VDSMenu = [menu]::new((Get-VDSwitch))
    $userSelectedVDS = $VDSMenu.RenderMenu("`nSelect the VDS With your Student VPGs`n")

    #lists macaddress, wol, networkname, type, name, parent, etc
    $allAdapters = Get-VApp -Name Student* | Get-VM | Get-NetworkAdapter

    $portgroup = Get-VDPortgroup -name 'Dump VPG'
    #if 'Dump VPG' portgroup does not exist, make it
    if ($portgroup -eq $null)
    {
        New-VDPortgroup -Name 'Dump VPG' -VDSwitch $userSelectedVDS
    }

    foreach ($nic in $allAdapters) 
    {
        $task = $portgroup.AttachNetworkAdapter($nic)
    }

    $allAdapters = Get-Folder -name 'Students' | Get-vm -name * | Get-NetworkAdapter
    $portgroup = Get-VDPortgroup -name 'Dump VPG'

    foreach ($nic in $allAdapters) 
    {
        $task = $portgroup.AttachNetworkAdapter($nic)
    }

    Get-VDSwitch -name $userSelectedVDS | Get-VDPortgroup -Name Student** | Remove-VDPortGroup -Confirm:$false
}
#resets student passwords to PASSWORDPASSWORD
function Reset-Passwords
{
    $pass = ConvertTo-SecureString -AsPlainText "PASSWORDPASSWORD" -Force
    $users = Invoke-Command -ComputerName MTCDC01 -Credential $userCreds -ScriptBlock {get-aduser -filter 'Name -like "Student*"'}

    foreach ($u in $users)
    {
        Set-ADAccountPassword -Identity $u -NewPassword $pass
    }
}
function Clear-Vapp-Range
{
    #clear-host
    Write-Host "Enter range to delete vms in vapp (inclusive) or a single vapp"
    $UserInput = [menu]::Prompt()

    #regex to detect ##*## or ###*###
    #'\d' denotes a number '.' denotes a wildcard regex
    $pattern1 = [regex]::new('\d\d.\d\d')
    $pattern2 = [regex]::new('\d\d\d.\d\d\d')

    $solopattern1 = [regex]::new('\d\d')
    $solopattern2 = [regex]::new('\d\d\d')

    #if the user input matches one of the two regex patterns
    if($($pattern1.Matches($UserInput)).success -or $($pattern2.Matches($UserInput)).success)
    {
        #pull student vapps
        $vapps = Get-VApp |?{$_.name -like "Student*"}

        #determine which of the two patterns is used, for indexing purposes
        if ($($pattern1.Matches($UserInput)).success)
        {
            $spacing = $UserInput[2]
            $low, $high = $UserInput.Split($spacing)
        }
        else
        {
            $spacing = $UserInput[3]
            $low, $high = $UserInput.Split($spacing)
        }

        #ensure low is the low-side of the range and switch if needed
        if ($low -gt $high)
        {
            $_j = $low
            $low = $high
            $high = $_j
        }

        if ($low.Length -eq 2)
            {
                $low = "1$low"
                $high = "1$high"
            }
        foreach ($v in $vapps)
        {
            #get student number
            $string = $v.name
            $number = $string.Split(' ')[1]

            if ($number -ge $low -or $number -le $high)
            {
                $vms = Get-VM -Location $v
                foreach ($vm in $vms)
                {
                    Remove-VM $vm -DeletePermanently -RunAsync
                }
            }
        }
    
    }
    elseif ($($solopattern1.Matches($UserInput)).success -or $($solopattern2.Matches($UserInput)).success)
    {
        if ($UserInput.Length -lt 100)
        {
            $UserInput += 100
        }
        $vapp = Get-VApp |?{$_.name -like "Student $userinput *"}
        $vms = get-vm -Location $vapp
        foreach ($vm in $vms)
        {
            Remove-VM $vm -DeletePermanently -RunAsync
        }
    }
}
# Powers on VMs
function PowerON ($VM_Name)
{
    $student_vms = $Global:MTC_Students_Folders | Get-VM *$VM_Name* 

    foreach ($vm in $student_vms)
    {
        if ($vm.PowerState -eq 'PoweredOn')
        {
           continue
        }
        else
        {
            Start-VM $vm -RunAsync | Out-Null
        }        
    }     
}

# Opens help file and saves it to desktop
function Help_File ()
{
    $helpFile = "C:\Users\$env:USERNAME\Desktop\MTC_HELP_FILE.txt"
    $helpText = "This will be a long help file."
    $helpText | out-file $helpFile
    Invoke-Item $helpFile
}

# Powers off VMs
function PowerOff ($VM_Name)
{
    
    $student_vms = $Global:MTC_Students_Folders | Get-VM *$VM_Name* 

    foreach ($vm in $student_vms)
    {
        if ($vm.PowerState -eq 'PoweredOff')
        {
           continue
        }
        else
        {
            if ($vm.guest.State -eq 'Running')
            {
                 Shutdown-VMGuest $vm -RunAsync -Confirm:$false | Out-Null
            }
            else
            {
                Stop-VM $vm -RunAsync -Confirm:$false | Out-Null
            }      
        }     
    }
}

# Connects to VCSA
function Connect ()
{
    while($true){
        ###clear-host
        [menu]::WriteLine('What is the IP or host name of your VCSA?')
        $vcsa = [Menu]::Prompt()
        ###clear-host
        $userAnswer = [Menu]::Confirm($vcsa)
        [system.console]::ForegroundColor = "White"
        if ($userAnswer -eq $true) {
            
            $Global:userCreds = Get-Credential
            ###clear-host
            Get-Module -ListAvailable VM* | Import-Module
            Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false 
            Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
            ###clear-host
            Write-Host "Connecting to VCSA..."
            #Connect-VIServer -Server $vcsa -Credential $Creds
            Connect-VIServer -Server $vcsa -Credential $Global:userCreds
            break

        }
        else {
            continue
        }



    } 
}

function ProvisonNetwork ()
{
    ###clear-host
    $VDSMenu = [menu]::new((Get-VDSwitch))
    $userSelectedVDS = $VDSMenu.RenderMenu("What VDS do you want your VPGs on?")
    Write-Host "Select your modified CSV"
    Start-Sleep 5
    $filepath = getCSV 
    $GLOBAL:CSV = Import-Csv -Path $filepath
    $vappCollection = Get-Folder Students | Get-VApp
    $vappCount = $vappCollection.count


    function New-Studentlist
    {
    
            Param( 
            
                [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
                [int]$amount
    
                ) 
    
            $numbers = 1..$amount
            $studentstring = 'Student '
            $students = @()
        
            foreach ($number in $numbers)
            {
        
                $studentnumber = 100 + $number
                $student = $studentstring + $studentnumber
                $students += ($student)    
            }

            $students
    }
 
    $studentlist = New-Studentlist -amount $vappCount
    $studentlistCounter = $studentlist.Count
    [System.Collections.ArrayList]$runningtasks = @()
    $vlanCounter = 101
    [System.Collections.ArrayList]$GLOBAL:VDPortgroupNames = @()

    function Get-VDPortgroupNames
    {  
        $csv = $GLOBAL:CSV
        $adaptercounter = 1
        $csvcounter = $csv.Count - 1

        while ($csv.Count -eq $null -and $adaptercounter -ne 11)
        {
            if ($adaptercounter -gt 10)
            {         
                $adaptercounter = 1
                $csvcounter --
                continue
            }

            $portgroup = $csv."Network Adapter $adaptercounter"

            if ($portgroup -eq $null)
            {
           
                $adaptercounter ++
                continue
            }
            $GLOBAL:VDPortgroupNames.Add($portgroup)
            $adaptercounter ++
        }

        while ($csvcounter -ne -1)
        {
        
            if ($adaptercounter -gt 10)
            {
            
                $adaptercounter = 1
                $csvcounter --
                continue
            }

            $portgroup = $csv[$csvcounter]."Network Adapter $adaptercounter"

            if ($portgroup -eq $null) 
            {
            
                $adaptercounter ++
                continue
            }

            $GLOBAL:VDPortgroupNames.Add($portgroup)
            $adaptercounter ++

        }

    }

    Get-VDPortgroupNames
    $UniqueVDPortgroupNames = $GLOBAL:VDPortgroupNames | Sort-Object -Unique

    if ($UniqueVDPortgroupNames.Count -le 1)
    {
            [System.Collections.ArrayList]$VDPortgroupNamesCopy = @() 
            $VDPortgroupNamesCopy.Add($UniqueVDPortgroupNames)
    }
    if ($UniqueVDPortgroupNames.Count -gt 1)
    {
            [System.Collections.ArrayList]$VDPortgroupNamesCopy = $UniqueVDPortgroupNames
    }

    while ($studentlistCounter -ne 0) {
    
        foreach ($student in $studentlist) {
        
            if ($studentlistCounter -ne 0 -and $VDPortgroupNamesCopy.Count -eq 0) {
            
                foreach ($portgroup in $UniqueVDPortgroupNames) {
                
                    $VDPortgroupNamesCopy.Add($portgroup)
                }
            }

            while ($VDPortgroupNamesCopy.Count -ne 0) {
            
                $VDPortgroupNamePop = $VDPortgroupNamesCopy[0]
                $task = Get-VDSwitch -Name $UserselectedVDS | New-VDPortgroup -Name "$student $VDPortgroupNamePop" `
                -VlanId $vlanCounter -RunAsync -NumPorts 8
                $runningtasks.Add($task)
                $VDPortgroupNamesCopy.Remove($VDPortgroupNamePop)
                $vlanCounter ++
            }
    
        $studentlistCounter --
        }          
    }

    $vmcount = $GLOBAL:CSV.count 
    $vmcounter = 0

    [System.Collections.ArrayList]$vms = @()

    while ($vmcounter -ne $vmcount)
    {
        if ($vmcount -eq $null)
        {
            Break
        }
        $vm = $GLOBAL:CSV[$vmcounter].VM
        $vms.Add($vm)
        $vmcounter ++
    }


    $vAppVMs = Get-VApp -name 'Student*' | get-vm
    $networkadapters = $vAppVMs | Get-NetworkAdapter
    $niccounter = $networkadapters.Count
    $trigger = $niccounter

    while ($trigger -gt 0)
    {
        foreach($vm in $vAppVMs)
        {
            if ($trigger -lt 0)
            {
                Break
            }
            $vmvApp = $vm.VApp.Name
            $regex = [regex]::match($vmvApp, 'Student \d{3}')
            $student = $regex.Value
            $networkadapters = $vm | Get-NetworkAdapter

         
            foreach ($nic in $networkadapters)
            {
                if ($trigger -lt 0)
                {
                    Break
                }
            ###clear-host
            $loadingstars = '*' * $trigger
            Write-Host $trigger $loadingstars
            
                if ($vm.Id -ne $nic.ParentId)
                {
                    continue
                }
                 
                if ($vms -contains $vm.Name -or $vms.Count -eq 0)
                {
                    $vmbeingprocessed = $GLOBAL:CSV | Where-Object {$_.VM -like $vm.Name}
                    
                    if ($nic.Name -like '*1')
                    {
                        
                        $portgroupname = $vmbeingprocessed.'Network Adapter 1'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*2')
                    {      
                        $portgroupname = $vmbeingprocessed.'Network Adapter 2'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*3')
                    {       
                        $portgroupname = $vmbeingprocessed.'Network Adapter 3'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*4')
                    {
                      
                        $portgroupname = $vmbeingprocessed.'Network Adapter 4'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*5')
                    {     
                        $portgroupname = $vmbeingprocessed.'Network Adapter 5'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*6')
                    {
                      
                        $portgroupname = $vmbeingprocessed.'Network Adapter 6'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*7')
                    {
                        
                        $portgroupname = $vmbeingprocessed.'Network Adapter 7'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*8')
                    {
                        
                        $portgroupname = $vmbeingprocessed.'Network Adapter 8'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*9')
                    {
                        
                        $portgroupname = $vmbeingprocessed.'Network Adapter 9'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }

                    if ($nic.Name -like '*10')
                    {        
                        $portgroupname = $vmbeingprocessed.'Network Adapter 10'
                        if ($portgroupname -eq $null)
                        {
                            $trigger --
                            continue    
                        }
                        $portgroupstring = $student + " " + $portgroupname
                        $portgroup = Get-VDPortgroup -name $portgroupstring
                        # attach VM networkadapter to port group
                        $task = $portgroup.AttachNetworkAdapter($nic) | Out-Null
                        $runningtasks.Add($task) | Out-Null
                        $trigger --
                    }
                }
            }
        }
    }

    $gns3vms = $vAppVMs | Where-Object {$_.Name -like '*gns3*'}
    $gns3Counter = $gns3vms.Count

    while ($gns3Counter -ne 0)
    {
        function Create-PowerShellScript {
        
                   param(
        
                       [Parameter(Mandatory=$true)]
                       [string]$NameOfScript,
    
                       [Parameter(Mandatory=$true)]
                       [string]$ScriptConent
                   )
           
                   $pathstring = "$env:USERPROFILE\Desktop\GNS3"
                   New-Item -Path "$pathstring" -Name "$NameOfScript.ps1" -ItemType file -Value $ScriptConent -Force
        
        }
        function Create-BatchScript {
        
                   param(
        
                       [Parameter(Mandatory=$true)]
                       [string]$NameOfScript,
    
                       [Parameter(Mandatory=$true)]
                       [string]$ScriptConent
                   )
           
                   $pathstring = "$env:USERPROFILE\Desktop\GNS3"
                   New-Item -Path "$pathstring" -Name "$NameOfScript.bat" -ItemType file -Value $ScriptConent -Force
        
        }
        # Setting Script strings 
        $renameNetworkAdaptersScript = '
        [System.Collections.ArrayList]$adapterslist = @(); 
        function Get-Networkadapters () {
    
    
            $adapters = Get-NetAdapter 

            foreach ($adapter in $adapters) {
        
                $adapterslist.Add($adapter)
        
            }

        }
        ;
        function Rename-Networkadapters () {
    
            Move-Item -Path "C:\GNS3\*csv" -Destination "C:\GNS3\SDN Config.csv"
            $adapterassigments = Import-Csv -Path "C:\GNS3\SDN Config.csv" 
            $GNS3 = $adapterassigments | Where-Object {$_.VM -like "*GNS3*"}
            $count = 1
    

            foreach ($adapter in $adapterssorted) {
        
                $adaptername = $GNS3."Network Adapter $count"
                $name = $adapter.Name
                Rename-NetAdapter -Name $name -NewName $adaptername
                $count ++
    
            }
        }
        ;
        Get-Networkadapters ;
        $adapterssorted = $adapterslist | Sort-Object -Property name ;
        Rename-Networkadapters;
        Get-childItem "C:\GNS3\" | Remove-Item -Recurse -Force ;
        Get-ChildItem "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" | Remove-Item -Recurse -Force
        '
        $elevateprocessscript = '
        function Elevate-Process  {
            param ([string]$exe = $(Throw "Pleave provide the name and path of an executable"),[string]$arguments)
            $startinfo = new-object System.Diagnostics.ProcessStartInfo 
            $startinfo.FileName = $exe
            $startinfo.Arguments = $arguments 
            $startinfo.verb = "RunAs" 
            $process = [System.Diagnostics.Process]::Start($startinfo)

        }
        ;
        Elevate-Process -Exe powershell.exe -Arguments "-noninteractive -command Invoke-Expression C:\GNS3\Rename-Networkadapters.ps1"'

        $kickOffScript = '
        cd C:\GNS3
        powershell.exe .\Elevate-Process.ps1
        '
        # Create Scripts
        Create-BatchScript -NameOfScript 'KickOff' -ScriptConent $kickOffScript
        Create-PowerShellScript -NameOfScript 'Rename-Networkadapters' -ScriptConent $renameNetworkAdaptersScript
        Create-PowerShellScript -NameOfScript 'Elevate-Process' -ScriptConent $elevateprocessscript

        # Creds for GNS3 Box
        $secpassword = ConvertTo-SecureString -AsPlainText 'PASSWORDFORGNS3BOX' -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ('Administrator', $secpassword)

         # Setting path variables to scripts
        $startUpDirectory = 'C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
        $destinationDirectory = 'C:\GNS3\'
        $pathstring = "$env:USERPROFILE\Desktop\GNS3"
        $kickOffBat =  "$pathstring\KickOff.bat"
        $ElevateProcessPS1 = "$pathstring\Elevate-Process.ps1"
        $RenameAdaptersPS1 = "$pathstring\Rename-Networkadapters.ps1"
        $csvFilepath = $filepath
    
        # Setting promiscuous mode on all GNS3 portgroups
        $studentPortGroups = Get-VDPortgroup -Name 'student*'
        foreach ($portgroup in $studentPortGroups) 
        {
            `Get-VDPortgroup -Name $portgroup | Get-VDSecurityPolicy | Set-VDSecurityPolicy -ForgedTransmits $true -AllowPromiscuous $true | Out-Null
        }
    
        foreach ($gns3vm in $gns3vms)
        {

            Copy-VMGuestFile -Source $kickOffBat `
            -Destination $startUpDirectory `
            -LocalToGuest `
            -VM $gns3vm `
            -GuestCredential $mycreds

            Copy-VMGuestFile -Source $ElevateProcessPS1 `
            -Destination $destinationDirectory `
            -LocalToGuest `
            -VM $gns3vm `
            -GuestCredential $mycreds

            Copy-VMGuestFile -Source $RenameAdaptersPS1 `
            -Destination $destinationDirectory `
            -LocalToGuest `
            -VM $gns3vm `
            -GuestCredential $mycreds                 

            Copy-VMGuestFile -Source $csvFilepath `
            -Destination $destinationDirectory `
            -LocalToGuest `
            -VM $gns3vm `
            -GuestCredential $mycreds

            $gns3Counter --
        
        }
    }        
}  

# Disconnects from VCSA
function Disconnect ()
{
    Write-Host 'Disconnecting from VCSA...'
    Start-Sleep .5
    Disconnect-VIServer -Server $vcsa -Confirm:$false 
    break
}

# Builds Black CSV for single vapp networking with 10 nics for each vm
function generateCSV ($vapp)
{
    $csvFile = "C:\Users\$env:USERNAME\Desktop\$vapp.csv"
    $csvHeader = 'VM,Network Adapter 1,Network Adapter 2,Network Adapter 3,Network Adapter 4,Network Adapter 5,Network Adapter 6,Network Adapter 7, Network Adapter 8,Network Adapter 9,Network Adapter 10'
    Write-Host " Creating $vapp.csv at $env:USERNAME\Desktop"
    Start-Sleep 5
    $csvHeader | Out-File $csvFile
    $vmNames = ($vapp | Get-VM).name
    foreach ($vm in $vmNames)
    {
      $vmCSV = "$vm"
      $vmCSV | Out-File -Append $csvFile  
    }
}

# Deletes all Vapps and vms in Student folders still need to do vms  
function CleanSlate ()
{
        ###clear-host

        Write-Host 
"
                  *******************                  
                  *   CLEAN SLATE   *                  
                  *******************                 
"
        Write-Host 
"
*******************************************************
*                    !!!WARNING!!!                    *
*      To blowout student VApps enter 'BLOWOUT'       *
*   To wipe everything for a new class enter 'WIPE'   *
*******************************************************
"
    $UserInput = [menu]::Prompt()
    $UserInputUpper = $UserInput.ToUpper()  
    $vappsToGetDeleted = $GLOBAL:MTC_Students_vAPP
    if ($UserInputUpper -eq 'BLOWOUT')
    {
        Start-Sleep .5   
        foreach ($Vapp in $vappsToGetDeleted)
        {
            Start-Sleep .5
            if ($Vapp.Status -eq 'Stopped')
                    {
           continue
        }
            else
                    {
            Stop-Vapp $Vapp -RunAsync -Confirm:$false | Out-Null      
         }              
        }
        Start-Sleep 5
        foreach ($Vapp in $vappsToGetDeleted)
        {
        Remove-VApp($Vapp) -DeletePermanently -Confirm:$false | Out-Null
    }

    }
    elseif ($UserInputUpper -eq "WIPE")
    {
        Start-Sleep .5   
        foreach ($Vapp in $vappsToGetDeleted)
        {
            Start-Sleep .5
            if ($Vapp.Status -eq 'Stopped')
            {
                continue
            }
            else
            {
                Stop-Vapp $Vapp -RunAsync -Confirm:$false | Out-Null      
            }        
        }

        Start-Sleep 5

        foreach ($Vapp in $vappsToGetDeleted)
        {
            Remove-VApp($Vapp) -DeletePermanently -Confirm:$false | Out-Null
        }
        Blowout-Networking
    }
    else 
    {
        ###clear-host
        Write-Host "Validation incorect! No VApps Deleted"
        Start-Sleep 3 
    }  
}

# Permanently deletes vm
function DeleteVM ($VM_Name) 
{
    
    $student_vms = $Global:MTC_Students_Folders | Get-VM *$VM_Name* 
    foreach ($VM in $student_vms) 
    {
        Remove-VM -vm $VM -DeletePermanently -RunAsync -Confirm:$false | Out-null   
    }
    
}

# Moves Vapp to Student folders 
function moveVapp ($studentNumber) 
{
    $vapp = Get-VApp *"$studentNumber"*
    $folder = Get-Folder "$studentNumber"
    Move-VApp -VApp $vapp -Destination $folder -RunAsync | Out-Null
}

# Opens file browser to select csv 
Function getCSV($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null 
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

# Genrates cronalogical list of student Numbers 
function ListOfStudents () 
{
    [Menu]::WriteLine("How many students?")
    $NumberOfStudents = [menu]::Prompt()
    
    $list = 1..$NumberOfStudents
    $listOfStudentNumbers = @()
    foreach ($i in $list) 
    {
        $StudentNumber = 100 + $i
        
        $listOfStudentNumbers +=  "Student $StudentNumber"
    }
    $listOfStudentNumbers
}

# Dynamic list of Vapps in Deployable Vapps folder for user selection 
function SelectVapp ()
{
    $FoldersMenu = [menu]::new((Get-Folder))
    $VAppRepo = $FoldersMenu.RenderMenu("Which folder is your is your VApp Repository?")
    $VAppMenu = [menu]::new((Get-Folder $VAppRepo.Name  | Get-VApp | Sort-Object -Unique))
    $selectedVApp = $VAppMenu.RenderMenu("Which VApp Would you like to deploy?")
    $selectedVApp
}


# Takes Snapshots of VMs
function Snapshot ()
{
    ###clear-host
    $studentVms =@()
    foreach ($m in $Global:MTC_Students_Folders)
    {
        $studentVms += Get-VM * -Location $m -ErrorAction SilentlyContinue | Select-Object *
    }

    ###clear-host
    $studentVms | Select-Object name, powerstate | Format-Table
    [Menu]::WriteLine("Which VMs do you want to take a snapshot of (* for all)?")
    $vmName = [Menu]::Prompt()
    ###clear-host
    $studentVms | ?{$_.Name -like "*$vmName*"} | Select-Object name, powerstate | Format-Table
    Write-Host ("_"*47)
    [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
    $correct = [Menu]::Prompt()

    if ($correct -eq 'x')
    {
        break 
    }
    elseif ($correct -ne "y")
    {
        do
        {
            ###clear-host
            $studentVms | select name, powerstate | ft
            [Menu]::WriteLine("Which VMs do you want to revert to day one (* for all)?")
            $vmName = [Menu]::Prompt()
            ###clear-host
            Start-Sleep .5
            $studentVms | ?{$_.Name -like "*$vmName*"} | select name, powerstate
            Write-Host ("_"*47)
            [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
            $correct = [Menu]::Prompt()
            
        }until ($correct -eq 'y' -or $correct -eq 'x')

        if ($correct -eq 'x')
        {
            break
        }
    }

    $filteredVMs = $studentVms | ?{$_.name -like "*$vmName*"}
    ###clear-host
    [Menu]::WriteLine("What do you want to name the Snapshot?")
    $SnapShot_Name = [Menu]::Prompt() 
    Stopwatch $sw
    foreach ($vm in $filteredVms)
    {
        new-Snapshot $SnapShot_Name -vm $VM -RunAsync -Memory:$false
    }
    Stopwatch $sw
}
function DeployVapp ()
{

    $studentnumbers = ListOfStudents
    $numberOfVapps = $studentnumbers.count
    [System.Collections.ArrayList]$studentName = @()
    $studentName = $studentnumbers
    $UserSelectedVapp = SelectVapp
    $throttlemax = 5
    $taillist = $studentnumbers[5..$studentnumbers.Count]
    $taillistcounter = $taillist.Count
    $throttlelist = $studentnumbers[0..4]
    $throttlecounter = $throttlelist.Count
    [System.Collections.ArrayList]$runningTasks = @()
    $ClusterMenu = [menu]::new((get-cluster))
    $Cluster = $ClusterMenu.RenderMenu("What Cluster would you like your VApps on?")
    $clusterString = $cluster[0].Name.ToString()
    $datastoresMenu = [menu]::new((get-datastore))
    $datastores = $datastoresMenu.RenderListBuilderMenu("What Datastore would you like your VApps on?", "Datastore")
    $dataStoresString = ""
    $datastores | ForEach-Object {$dataStoresString += $($_.Name.ToString() + " ")}
    $datastorecounter = $datastores.Count -1
    $datastorecounterReset = $datastores.Count -1
    $vmsSize = $UserSelectedVapp | Get-VM
    $vappSize = 0
    $bufferGB = 100
    $file = "C:\Users\$env:USERNAME\Desktop\Deployment_time.txt"
    $start = Get-Date 
    $start | Out-File $file

    while ($true) {
        [Menu]::WriteLine("Type 'Confirm' if the following parameters are correct.")
        $ConfirmChoices = @"
Number VApps: $($numberOfVApps)
Selected VApp template: $($UserSelectedVapp.Name)
Selected Cluster: $($clusterString)
Selected Datastore[s]: $($dataStoresString)
"@
        [Menu]::WriteLine($ConfirmChoices)
        $userSelected = [menu]::Prompt()
        if ($userSelected -eq "Confirm") {
            break
        }
        else{

            DeployVapp
        }
    }

    foreach($vm in $vmsSize)
    {
        $space = $vm.UsedSpaceGB
        $vappsize += $space
    }
    
    While ($true )
    {
        Write-Host "Creating $numberOfVapps VApps"
        Start-Sleep .5
        While ($throttlecounter -ne 0)
        {
            if ($runningtasks.Count -lt $throttlemax)
            {
                
                if($datastorecounter -eq -1)
                {
                    $datastorecounter = $datastorecounterReset               
                }
 
                $datastorestring = $datastores[$datastorecounter].Name
                $datastore = Get-Datastore $datastorestring
                $datastoreSize = $datastore.FreeSpaceGB - $bufferGB

                if($vmsSize -ge $datastoreSize)
                {
                    $datastorecounter --
                    Continue
                }

                $studentNamePop = $studentName[0]
                $date = Get-Date
                $helper = "Deployed $studentNamePop $UserSelectedVapp to $datastorestring at $date"
                $helper | Out-File -Append  "C:\Users\$env:USERNAME\Desktop\Deployment.txt"
                $task = New-VApp "$studentNamePop $UserSelectedVapp" -VApp $UserSelectedVapp -Datastore $datastorestring -Location (Get-Cluster $Cluster) -RunAsync
                $runningTasks.Add($task.Id)
                $throttlecounter -- 
                $studentName.Remove($studentNamePop)
                $datastorecounter --
                ###clear-host
                Write-Host "Deploying VApps"
            }
        }
    
        while($runningtasks.Count -ne 0)
        {
            ###clear-host
            Write-Host "Deploying VApps"
            foreach ($taskId in $runningTasks)
            {
                ###clear-host
                Write-Host "Deploying VApps"
                $task = Get-Task -Id $taskId
                Start-Sleep .5
                if($task.State -eq "Success")
                {
                    ###clear-host
                    Write-Host "Deploying VApps"
                    $studentCounter --
                    $runningTasks.Remove($taskId)
                    Start-Sleep .5
                    ###clear-host
                    Write-Host "Deploying VApps"
                }
                elseif($task.Result -eq "Error")
                {
                    ###clear-host
                    Write-Host "Deploying VApps"
                    $studentCounter --
                    $runningTasks.Remove($taskId)
                    Start-Sleep .5
                    ###clear-host
                    Write-Host "Deploying VApps"
                }
                ###clear-host
                Write-Host "Deploying VApps"
            }

            if($taillistcounter -ne 0 -and $runningtasks.Count -lt $throttlemax )
            {
                if($datastorecounter -eq -1)
                {    
                    $datastorecounter = $datastorecounterReset          
                }
                
                $datastorestring = $datastores[$datastorecounter].Name
                $datastore = Get-Datastore $datastorestring
                $datastoreSize = $datastore.FreeSpaceGB - $bufferGB

                if($vmsSize -ge $datastoreSize)
                {
                    $datastorecounter --
                    Continue
                } 
                $studentNamePop = $studentName[0]
                $date = Get-Date
                $helper = "Deployed $studentNamePop $UserSelectedVapp to $datastorestring at $date"
                $helper | Out-File -Append "C:\Users\$env:USERNAME\Desktop\Deployment.txt"
                $task = New-VApp "$studentNamePop $UserSelectedVapp" -VApp $UserSelectedVapp -Datastore $datastorestring -location (Get-ResourcePool $studentNamePop) -RunAsync
                $runningTasks.Add($task.Id)
                $datastorecounter --
                $taillistcounter --
                $studentName.Remove($studentNamePop)
                ###clear-host
                Write-Host "Deploying VApps"
            }  
        }
        
        if($taillistcounter -eq 0 -and $throttlecounter -eq 0)
        {
            Start-Sleep 10
            ###clear-host
            Write-Host 'Moving Vapps'

            foreach($studentnumber in $studentnumbers)
            {
                moveVapp ($studentnumber)
            }

            Start-Sleep 10

            foreach ($student in $studentnumbers)
            {
                Write-Output "starting vapps"
                Get-VApp *$student* | Start-VApp -RunAsync | Out-Null
                Start-Sleep 1
            }

            $stop = Get-Date
            $total_time = $stop - $start
            $stop | Out-File -Append $file
            $total_time | Out-File -Append $file 
            Invoke-Item $file
            Invoke-Item "C:\Users\$env:USERNAME\Desktop\Deployment.txt"
            break
        }    
    }
}

# Dynamic list of Vapps in Deployable Vapps folder for user selection 
function SelectTemplate ()
{
    $template_list = @()
    $template_list +=  Get-Folder Templates | Get-Template
    $each_counter = 1
    foreach ($template in $template_list) 
    {
        Write-Host "[$each_counter] $template"
        $each_counter += 1
    }
    $user_selection = [menu]::Prompt()
    $user_index = $user_selection - 1
    Write-Host " "
    $template_list[$user_index] 
}

function deployTemp ()
{
    $students = ListOfStudents
    $template = SelectTemplate
    [Menu]::WriteLine("What Do you want the VM name to be?")
    $vmName = [menu]::Prompt()
    foreach ($student in $students)
    {
        $resourcepool = Get-ResourcePool $student
        $name = $student + " " + $vmName
        $folder = Get-Folder Students | Get-Folder $student
        New-VM -Name $name -Template $template -ResourcePool $resourcepool -Location $folder -RunAsync
    }
}
function revertToDayOneSnapshot ()
{
    $studentVms =@()
    foreach ($m in $Global:MTC_Students_Folders)
    {
        $studentVms += Get-VM * -Location $m -ErrorAction SilentlyContinue
    }

    $results = get-uniqueVMObject $studentvms
    $results | ft
    [Menu]::WriteLine("Which VMs do you want to revert to day one (* for all)?")
    $vmName = [Menu]::Prompt()
    ###clear-host
    $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
    Write-Host ("_"*47)
    [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
    $correct = [Menu]::Prompt()

    if ($correct -eq 'x')
    {
        break
    }
    elseif ($correct -ne "y")
    {
        do
        {
            ###clear-host
            $results | ft
            [Menu]::WriteLine("Which VMs do you want to revert to day one (* for all)?")
            $vmName = [Menu]::Prompt()
            ###clear-host
            Start-Sleep .5
            $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
            Write-Host ("_"*47)
            [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
            $correct = [Menu]::Prompt()
            
        }until ($correct -eq 'y' -or $correct -eq 'x')

        if ($correct -eq 'x')
        {
            break
        }
    }

    $filteredVMs = $studentVms | ?{$_.name -like "*$vmName*"}
    ###clear-host

    Stopwatch $sw
    foreach ($vm in $filteredVms)
    {
        $snapShot = Get-Snapshot -VM $vm | sort -Property Created | select -First 1
        Set-VM -VM $vm -Snapshot $snapshot -Confirm:$false -RunAsync
    }
    Stopwatch $sw
}
function revertToMostRecentSnapshot ()
{
    $studentVms =@()
    foreach ($m in $Global:MTC_Students_Folders)
    {
        $studentVms += Get-VM * -Location $m -ErrorAction SilentlyContinue
    }

    ###clear-host
    $results = get-uniqueVMObject $studentVms
    $results | ft
    [Menu]::WriteLine("Which VMs do you want to revert to day one (* for all)?")
    $vmName = [Menu]::Prompt()
    ###clear-host
    $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
    Write-Host ("_"*47)
    [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
    $correct = [Menu]::Prompt() 

    if ($correct -eq 'x')
    {
        break 
    }
    elseif ($correct -ne "y")
    {
        do
        {
            ###clear-host
            $results | ft
            [Menu]::WriteLine("Which VMs do you want to revert to day one (* for all)?")
            $vmName = [Menu]::Prompt()
            ###clear-host
            Start-Sleep .5
            $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
            Write-Host ("_"*47)
            [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
            $correct = [Menu]::Prompt()
            
        }until ($correct -eq 'y' -or $correct -eq 'x')

        if ($correct -eq 'x')
        {
            break
        }
    }

    $filteredVMs = $studentVms | ?{$_.name -like "*$vmName*"}
    ###clear-host

    Stopwatch $sw
    foreach ($vm in $filteredVms)
    {
        $snapShot = Get-Snapshot -VM $vm | sort -Property Created -Descending | select -First 1
        Set-VM -VM $vm -Snapshot $snapshot -Confirm:$false -RunAsync
    }
    Stopwatch $sw
}
function revertToSnapshotMenu ()
{
    #clear-host
    while ($menuSelection -ne 9)
    {
Write-Host `
"********************
* Snapshot Options *
********************

[1] Revert To Earliest
[2] Revert To Most Recent
[3] Revert To Specific
[4] Delete Snapshot
[9] Back"

    $menuSelection = [menu]::Prompt()
                
    switch ($menuSelection)
    {
        1 { 
            stopwatch $sw
            revertToDayOneSnapshot
            stopwatch $sw
          }
        2 {
            stopwatch $sw
            revertToMostRecentSnapshot
            stopwatch $sw
          }
        3 {
            stopwatch $sw
            revertToSpecificSnapshot
            stopwatch $sw
          }
        4 {
            stopwatch $sw
            delete-snapshot
            stopwatch $sw
          }
        9 {break}
    }
    }
}
function revertToSpecificSnapshot ()
{
    $studentVms =@()
    foreach ($m in $Global:MTC_Students_Folders)
    {
        $studentVms += Get-VM * -Location $m -ErrorAction SilentlyContinue
    }

    ###clear-host
    $results = get-uniqueVMObject $studentVms
    $results | ft
    [Menu]::WriteLine("Which VMs do you want to revert (* for all)?")
    $vmName = [Menu]::Prompt()
    ###clear-host
    $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
    Write-Host ("_"*47)
    [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
    $correct = [Menu]::Prompt()

    if ($correct -eq 'x')
    {
        break 
    }
    elseif ($correct -ne "y")
    {
        do
        {
            ###clear-host

            $results | ft
            [Menu]::WriteLine("Which VMs do you want to revert (* for all)?")
            $vmName = [Menu]::Prompt()
            ###clear-host
            Start-Sleep .5
            $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
            Write-Host ("_"*47)
            [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
            $correct = [Menu]::Prompt()
            
        }until ($correct -eq 'y' -or $correct -eq 'x')

        if ($correct -eq 'x')
        {
            break
        }
    }

    $filteredVMs = $studentVms | ?{$_.name -like "*$vmName*"}
    ###clear-host

    $snapshots = @()
    foreach ($vm in $filteredVms)
    {
        $snapShots += Get-Snapshot -VM $vm -ErrorAction SilentlyContinue| sort -Property Created | select name, created
    }
    $results = get-uniqueVMObject $snapshots
    $results | ft
    [Menu]::WriteLine("Which snapshot you would like to revert to (X to exit)")
    $snapshotSelection = [Menu]::Prompt()
    if ($snapshotSelection -eq 'x')
    {
        break
    }
    $selectedSnapshot = $snapShots |?{$_.name -like "*$snapshotSelection*"}

    Stopwatch $sw
    foreach ($vm in $filteredVMs)
    {
         $ss = Get-Snapshot -VM $vm | ?{$_.Name -like "*$snapshotSelection*"}
         Set-VM -VM $vm -Snapshot $ss.Name -Confirm:$false -RunAsync
    }
    Stopwatch $sw
}
function Delete-Snapshot
{
    $studentVms =@()
    foreach ($m in $Global:MTC_Students_Folders)
    {
        $studentVms += Get-VM * -Location $m -ErrorAction SilentlyContinue
    }

    ###clear-host
    $results = get-uniqueVMObject $studentVms
    $results | ft
    [Menu]::WriteLine("Which VMs do you want to select (* for all)?")
    $vmName = [Menu]::Prompt()
    ###clear-host
    $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
    Write-Host ("_"*47)
    [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
    $correct = [Menu]::Prompt()

    if ($correct -eq 'x')
    {
        break 
    }
    elseif ($correct -ne "y")
    {
        do
        {
            ###clear-host

            $results | ft
            [Menu]::WriteLine("Which VMs do you want to select (* for all)?")
            $vmName = [Menu]::Prompt()
            ###clear-host
            Start-Sleep .5
            $studentVms | ?{$_.Name -like "*$vmName*"} | ft -Property name, @{Label = "PowerState"; Expression = {$_.powerstate}; Alignment = "Left"}
            Write-Host ("_"*47)
            [Menu]::WriteLine("Is this correct (Y/N, X to exit)?")
            $correct = [Menu]::Prompt()
            
        }until ($correct -eq 'y' -or $correct -eq 'x')

        if ($correct -eq 'x')
        {
            break
        }
    }

    $filteredVMs = $studentVms | ?{$_.name -like "*$vmName*"}
    ###clear-host

    $snapshots = @()
    foreach ($vm in $filteredVms)
    {
        $snapShots += Get-Snapshot -VM $vm -ErrorAction SilentlyContinue| sort -Property Created | select name, created
    }
    $results = get-uniqueVMObject $snapshots
    $results | ft
    [Menu]::WriteLine("Which snapshot you would like to delete (X to exit)?")
    $snapshotSelection = [Menu]::Prompt()
    if ($snapshotSelection -eq 'x')
    {
        break
    }
    $selectedSnapshot = $snapShots |?{$_.name -like "*$snapshotSelection*"}

    Stopwatch $sw
    foreach ($vm in $filteredVMs)
    {
         $ss = Get-Snapshot -VM $vm | ?{$_.Name -like "*$snapshotSelection*"}
         Remove-Snapshot -Snapshot $ss -RunAsync
    }
    Stopwatch $sw

}

<#
function get-studentvms ()
{

}
#>
function get-uniqueVMObject ($vmObjects)
{
    $count = 0
    $uniqueNames = $vmObjects | sort name | Select-Object name -Unique
    $results = @{}
    foreach ($name in $uniqueNames)
    {
        $objName = $name.Name
        $count = $($vmobjects.name -match $name.Name).count
        $results.add($objName,$count)
    }
    $results = $results | Format-Hashtable -KeyHeader 'Name' -ValueHeader 'Count'
    return $results
}
function Format-Hashtable
{
    param(
      [Parameter(Mandatory,ValueFromPipeline)]
      [hashtable]$Hashtable,

      [ValidateNotNullOrEmpty()]
      [string]$KeyHeader = 'Name',

      [ValidateNotNullOrEmpty()]
      [string]$ValueHeader = 'Value'
    )

    $Hashtable.GetEnumerator() |Select-Object @{Label=$KeyHeader;Expression={$_.Key}},@{Label=$ValueHeader;Expression={$_.Value}}

}
function Stopwatch ($sw)
{
    if ($sw.Elapsed -eq "00:00:00")
    {
        $sw.Start()
    }
    else
    {
        $seconds = $sw.Elapsed.Seconds
        $minutes = $sw.Elapsed.Minutes
        $hours = $sw.Elapsed.Hours
        $days = $sw.Elapsed.Days
        if ($days -ne 0)
        {
            Write-Host "Elapsed Time: " $days "days -" $hours "hours -" $minutes "minutes -" $seconds "seconds" -ForegroundColor Green
        }
        elseif ($hours -ne 0)
        {
            Write-Host "Elapsed Time: " $hours "hours -" $minutes "minutes -" $seconds "seconds" -ForegroundColor Green
        }
        elseif ($minutes -ne 0)
        {
            Write-Host "Elapsed Time: " $minutes "minutes -" $seconds "seconds" -ForegroundColor Green
        }
        else
        {
            Write-Host "Elapsed Time: " $seconds "seconds" -ForegroundColor Green
        }
        Pause
        $sw.Reset()
    }
    
}

# DSC TOOLS
#============================================================
function SetUpCWD () {
    
    $MOFDirectory = "$env:SystemDrive\MOF\";
    $result = Test-Path -Path $MOFDirectory;
    if ($result -ne $true) {
        
        mkdir $MOFDirectory
    }
    # Sets up the working directory
    Set-Location $MOFDirectory 

}
function CleanUp () {
    Start-Job -Credential $jobCred -ScriptBlock {
        Set-Location $env:HOMEDRIVE
        $CIM_Processes = Get-CIMinstance -class Win32_Process -Filter "Name LIKE 'powershell.exe'" -ErrorAction SilentlyContinue;
        $CommandLine = $CIM_Processes | Select-Object -ExpandProperty CommandLine | Where-Object {$_ -like "*nologo*"}
        while ($CommandLine.Count -ne 1) {
            $CIM_Processes = Get-CIMinstance -class Win32_Process -Filter "Name LIKE 'powershell.exe'" -ErrorAction SilentlyContinue;
            $CommandLine = $CIM_Processes | Select-Object -ExpandProperty CommandLine | Where-Object {$_ -like "*nologo*"}
            continue
        }
        $cwd = "$env:HOMEDRIVE\MOF"
        Remove-Item $cwd -Recurse -Force
    }
}
function Invoke-StartDSCConfiguration () {
    
    Param( 
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareVM,
        
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential

        )
    # Fill in -ComputerName variable to reflect appropriate according to copy-mof function and functionality
    $startDscScriptText = '
    Start-DscConfiguration -Path "$env:SystemDrive\MOF\"
    '
    Invoke-VMScript -VM $vmwareVM -ScriptText $startDscScriptText -GuestCredential $Credential -ScriptType Powershell
}
function Invoke-SetDscLocalConfigurationManager () {
    
    Param( 
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareVM,
        
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential

        )
    # Fill in -ComputerName variable to reflect appropriate according to copy-mof function and functionality
    $setDscScriptText = '
    Set-Location WSMan:\localhost\Client ; set-item TrustedHosts * -Confirm:$false -Force ; Restart-Service WinRM ; sleep 5 ; 
    Set-DscLocalConfigurationManager -Path "$env:SystemDrive\MOF\"
    '
    Invoke-VMScript -VM $vmwareVM -ScriptText $setDscScriptText -GuestCredential $Credential -ScriptType Powershell
}
function Copy-DSCModules () {
    
    Param( 
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string[]]$ModuleNames,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareVM,

        [Parameter(Mandatory=$true)]
        [pscredential]$Credential
        
        )
    $destinationDirectory = "$env:SystemDrive\Windows\System32\WindowsPowerShell\v1.0\Modules\"

    foreach ($module in $ModuleNames) {
        
        $modulepath = Get-Item -Path "$env:SystemDrive\Windows\System32\WindowsPowerShell\v1.0\Modules\$module" -ErrorAction SilentlyContinue
        
        
        Copy-VMGuestFile -Source $modulepath `
        -Destination $destinationDirectory `
        -LocalToGuest `
        -VM $vmwareVM `
        -GuestCredential $Credential -Force
    }
    
}
function Copy-MOF () {
    
    Param( 
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareVM,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareGestOSName,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$DSCConfigName,

        [Parameter(Mandatory=$true)]
        [pscredential]$Credential

        )

    $copymofScriptText = '
    $destinationDirectory = "$env:SystemDrive\MOF\";
    $result = Test-Path -Path $destinationDirectory;
    if ($result -ne $true) {
        
        New-Item -Path $env:SystemDrive\ -Name MOF -ItemType Directory -Force
    }
    '
    Invoke-VMScript -VM $vmwareVM -ScriptText $copymofScriptText  -GuestCredential $Credential -ScriptType Powershell 
    $sourcedirectory = Get-ChildItem -Recurse "$env:systemdrive\MOF\$DSCConfigName\*$vmwareGestOSName*"
    $destinationDirectory = "$env:SystemDrive\MOF\"

    Copy-VMGuestFile -Source $sourcedirectory `
    -Destination $destinationDirectory `
    -LocalToGuest `
    -VM $vmwareVM `
    -GuestCredential $Credential -Force `
}
function Invoke-RenameComputer () {
    
    Param( 
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareVM,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$vmwareGestOSName,

        [Parameter(Mandatory=$true)]
        [pscredential]$Credential

        )

    $renameComputerScriptText = "
    Rename-Computer -ComputerName localhost -NewName '$vmwareGestOSName' -Force -restart
    "
    Invoke-VMScript -VM $vmwareVM -ScriptText $renameComputerScriptText  -GuestCredential $Credential -ScriptType Powershell -RunAsync | Out-Null
}
function Start-DCDSC () {
    # Create PSD1 file for DSC
    New-DCPSD1
    Start-Sleep 5
    # Compile MOF's
    DomainBuild -ConfigurationData $GLOBAL:psd1File
    Start-Sleep 5
    # Create function definitions to inject in start-job scope
    $allFunctionDefs = "function Copy-DSCModules { ${function:Copy-DSCModules} }; function Copy-MOF { ${function:Copy-MOF} };function Invoke-RenameComputer { ${function:Invoke-RenameComputer} };function Invoke-SetDscLocalConfigurationManager { ${function:Invoke-SetDscLocalConfigurationManager} }; function Invoke-StartDSCConfiguration { ${function:Invoke-StartDSCConfiguration} };"
    # set variable for nodenames hashtable to keep track of guest OS hostnames
    $nodeNames = "$env:HOMEDRIVE\MOF\nodeNames"
    # Export nodenames hashtable
    $Global:nodenames | Export-Clixml $nodeNames
    # Export guestOS creds
    $creds = "$env:HOMEDRIVE\MOF\creds"
    $Global:userCreds | Export-Clixml "$env:HOMEDRIVE\MOF\creds"
    #$domainControllers = $GLOBAL:MTC_Students_vAPP = Get-Folder 'Students' | Get-VApp | Get-VM | Where-Object {$_.Name -like '*DC*'}
    $domainControllers = Get-Folder 'Students' | Get-VApp | Get-Vm | Where-Object {$_.Name -like '*DC*'}
    $count = 1
    foreach ($dc in $domainControllers) {

        $domainController = "$env:HOMEDRIVE\MOF\dc$count"
        $dc | Export-Clixml $domainController
        $count ++
        $jobCred = $Global:userCreds 
        $vmwarecred = $Global:userCreds 
        $localPassword = ConvertTo-SecureString -String 'PASSWORDFORDOMAINCONTROLLER' -AsPlainText -Force
        $creds = [pscredential]::new('Administrator', $localPassword)
        Start-Job -Name "DC$count" -Credential $jobCred -ArgumentList $allFunctionDefs, $nodeNames, $domainController, $creds, $vmwarecred -ScriptBlock {
            Param( 
                $allFunctionDefs,
                $nodeNames,
                $domainController,
                $creds, 
                $vmwarecred
                
            )
            # Import modules 
            Get-Module -ListAvailable '*vmware*' | Import-Module
            # Connect to VCSA via job session Pass global cred parameter here
            Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
            Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP:$false -Confirm:$false | Out-Null
            ## Need to pass $VCSA here to job as argument
            Connect-VIServer $SOMEVCSAVARIABLENEEDSTOGOHERE -Credential $vmwarecred
            # Recreate functions in job session
            .([ScriptBlock]::Create($allFunctionDefs))
            # import nodenames hashtable
            $nodeNames = Import-Clixml $nodeNames
            # import DC object
            $dc = Import-Clixml $domainController
            # Import Creds
            $creds = Import-Clixml $creds
            $key = $dc.VApp.Parent
            $value = $nodeNames[$key]
            $vmwareVM = $dc.Name
            $vmwareGestOSName = $value 
            Copy-DSCModules -ModuleNames "xActiveDirectory" -vmwareVM $vmwareVM -Credential $creds | Out-Null
            Copy-MOF -vmwareVM $vmwareVM -vmwareGestOSName $vmwareGestOSName -DSCConfigName "DomainBuild" -Credential $creds | Out-Null
            Invoke-RenameComputer -vmwareVM $vmwareVM -vmwareGestOSName $vmwareGestOSName -Credential $creds | Out-Null
            Start-Sleep 60
            Invoke-SetDscLocalConfigurationManager -vmwareVM $vmwareVM -Credential $creds | Out-Null
            start-sleep 5
            Invoke-SetDscLocalConfigurationManager -vmwareVM $vmwareVM -Credential $creds | Out-Null
            Invoke-StartDSCConfiguration -vmwareVM $vmwareVM -Credential $creds | Out-Null
        
        } 
    }

}
function DSCOptions () {
  
    SetUpCWD
    while ($true) {
        
        ###clear-host
        Write-Host "
        *******************
        *   DSC OPTIONS   *
        *******************

        [1] Provision Domain Controllers 
        [2]  
        [3]
        [4]
        [9] Back        
        "

        $userselctedoption = [menu]::Prompt()
        switch ($userselctedoption) {
            
            1{Start-DCDSC; CleanUp}
            2{}
            3{}
            4{}
            9{RenderMainMenu}
        }
    }
}
function New-DCPSD1 (){

    ###clear-host
    $studentlist = ListOfStudents
    $studentlistcounter = $studentlist.Count
    $studentNumber = $studentlistcounter + 100
    $GLOBAL:psd1File = "$env:HOMEDRIVE\MOF\DCConfigData.psd1"
    $GLOBAL:nodenames = @{}
    ###clear-host
    [Menu]::WriteLine("What would you like the students FQDN to be?`n")
    $FQDN = [menu]::Prompt()
    $configDataString = @"
@{
    AllNodes = 
    @(
        @{

            NodeName ="*"
            PSDscAllowPlainTextPassword = $('$true')
            Role = "Primary DC"
            RetryCount = 20
            RetryIntervalSec = 30
            
        }

        @{  $($NodeName = ('S' + $studentNumber + 'DC01'); $studentstring = "Student $studentNumber" ; $GLOBAL:nodenames.Add($studentstring, $nodename))
            NodeName =  "$NodeName"
            DomainName = "S$studentNumber$FQDN"
        },


"@
    $configDataString | Out-File -Append $psd1File
    $studentlistcounter --
    $studentTotal = $studentlist.Count -1 
    $counter = 1
    while ($counter -le $studentTotal) {

        $studentNumber = $studentlistcounter + 100

        if ($counter -lt $studentTotal) {

            $appendConfigDataString = @"
        @{
            $($NodeName = ('S' + $studentNumber + 'DC01'); $studentstring = "Student $studentNumber" ; $GLOBAL:nodenames.Add($studentstring, $nodename))
            NodeName =  "$NodeName"
            DomainName = "S$studentNumber$FQDN"   
        },
        
"@
            $appendConfigDataString | Out-File -Append $psd1File
            $counter ++
            $studentlistcounter -- 
            
        }

        if ($counter -eq $studentTotal) {
            
            $studentNumber = $studentlistcounter + 100
            $lastConfigDataappend = @"
        @{
            $($NodeName = ('S' + $studentNumber + 'DC01'); $studentstring = "Student $studentNumber" ; $GLOBAL:nodenames.Add($studentstring, $nodename))
            NodeName =  "$NodeName"
            DomainName = "S$studentNumber$FQDN"   
        }
    );
    
    NonNodeData = ""   
}
"@
            $lastConfigDataappend | Out-File -Append $psd1File
            $counter ++
            $studentlistcounter -- 
        }
    }
}
Configuration DomainBuild {
    $buildPassword = ConvertTo-SecureString -String 'PASSWORD FOR DOMAIN CONTROLLER' -AsPlainText -Force
    $buildcred = [pscredential]::new('Student', $buildPassword)
    
    #Import-DscResource -ModuleName xActiveDirectory 
   
    Node $AllNodes.NodeName {
        
        LocalConfigurationManager {
            
            ActionAfterReboot = 'ContinueConfiguration'
            RefreshMode = 'Push'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
    
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename {
        
        WindowsFeature ADDSInstall {

            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature 1 {

            Ensure = "Present"
            Name = "RSAT-Role-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature 2 {
        
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature 3 {
        
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature 4 {
        
            Ensure = "Present"
            Name = "RSAT-ADDS"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature 5 {
        
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
        
        WindowsFeature 6 {
        
            Ensure = "Present"
            Name = "RSAT-AD-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomain FirstDS {

            DomainName = $Node.DomainName
            DomainAdministratorCredential = $buildcred
            SafemodeAdministratorPassword = $buildcred 
            DependsOn = "[WindowsFeature]ADDSInstall"
            
        }

        xADUser NewUser {
            
            DomainName = $Node.DomainName
            UserName = "Student"
            PasswordNeverExpires = $true
            Password = $buildcred
            DependsOn = "[WindowsFeature]5"
            
        }

        xWaitForADDomain DscForestWait {

            DomainName = $Node.DomainName
            DomainUserCredential = $buildcred 
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        }
    }
}
function Set-StudentFolders() {

    $students = ListOfStudents
    $menu = [Menu]::new((Get-Datacenter))
    $DataCenter = $menu.RenderMenu("Which datacenter would you like your Student Folders created on?")
    
    [void](Get-View (Get-View -viewtype datacenter -filter @{"name"=$($DataCenter.Name)}).vmfolder).CreateFolder("Students")

    $StudentFolder = Get-View -viewtype Folder -filter @{"name"=$("Students")}

    if ($students.Count -eq 0) {
        break
        
    }

    foreach ($student in $students) {
        
        [void]$StudentFolder.CreateFolder($student)
    }

}

function Delete-StudentFolders {
    
    Get-Folder -Name "Students" | Remove-Folder -Confirm:$false 
}


function Set-VAppLibraryFolder {

    $menu = [Menu]::new((Get-Datacenter))
    $DataCenter = $menu.RenderMenu("Which datacenter would you like your VApp Repository created on?")
    
    [void](Get-View (Get-View -viewtype datacenter -filter @{"name"=$($DataCenter.Name)}).vmfolder).CreateFolder("VAppRepo")

    $VApps = Get-VApp
    if ($VApps.Count -eq 0) {
        Clear-Host
        [Menu]::WriteLine("`nYou do not have any VApps in your inventory. `n`nBefore you use the Deploy VApp feature ensure you create VApps and move them into the VAppRepo Folder.`n")
        [Menu]::WriteLine("Type 'AGREE' to continue")
        $UserInput = [menu]::Prompt()
        while ($UserInput -ne "AGREE") {
        Clear-Host
        [Menu]::WriteLine("`nYou do not have any VApps in your inventory. `n`nBefore you use the Deploy VApp feature ensure you create VApps and move them into the VAppRepo Folder.`n")
        [Menu]::WriteLine("Type 'AGREE' to continue")
        $UserInput = [menu]::Prompt()
        }
        
    }

    $VAppBuildMenu = [Menu]::new($VApps)
    $VAppsToProcess = $VAppBuildMenu.RenderListBuilderMenu("Which VApps would you like to add to your Master library?", "VApps")
    foreach ($VApp in $VAppsToProcess) {
        Move-VApp -VApp $VApp -Destination (Get-Folder -Name "VAppRepo") | Out-Null
    }
}

function Set-TemplateLibraryFolder {

    $menu = [Menu]::new((Get-Datacenter))
    $DataCenter = $menu.RenderMenu("Which datacenter would you like your Template Repository created on?")
    
    [void](Get-View (Get-View -viewtype datacenter -filter @{"name"=$($DataCenter.Name)}).vmfolder).CreateFolder("Templates")

    $Templates = Get-Template
    if ($Templates.Count -eq 0) {
        Clear-Host
        [Menu]::WriteLine("`nYou do not have any Templates in your inventory. `n`nBefore you can use the VM Option 'Deploy VM(s)' ensure you create a VM Template and move it into the Templates Folder.`n")
        [Menu]::WriteLine("Type 'AGREE' to continue")
        $UserInput = [menu]::Prompt()
        while ($UserInput -ne "AGREE") {
        Clear-Host
        [Menu]::WriteLine("`nYou do not have any Templates in your inventory. `n`nBefore you can use the VM Option 'Deploy VM(s)' ensure you create a VM Template and move it into the Templates Folder.`n")
        [Menu]::WriteLine("Type 'AGREE' to continue")
        $UserInput = [menu]::Prompt()
        }
        
    }

    $templateBuildMenu = [Menu]::new($Templates)
    $TemplatesToProcess = $templateBuildMenu.RenderListBuilderMenu("Which Templates would you like to add to your Template library?", "Templates")
    foreach ($template in $TemplatesToProcess) {
        Move-Template -Template $template -Destination (Get-Folder -Name "Templates") -RunAsync | Out-Null
    }
    
}

function Set-EnvironmentForFirstUse {
    # Install DSC resoruces here
    Install-Module -Name xActiveDirectory, xComputerManagement -Confirm:$false -Force
    Set-StudentFolders
    Set-VAppLibraryFolder
    Set-TemplateLibraryFolder

}

#End DSC Tools
#=============================================================
# Starts Main
$global:sw = New-Object -TypeName system.diagnostics.stopwatch
Main