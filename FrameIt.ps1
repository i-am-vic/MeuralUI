<#
Main dialog
    Show galleries that exist on the Netgear Meural server
    Create and remove galleries
    Move galleries to and from Canvas

Dialogues that branch off of Main dialog
    Manage files in a given Gallery
        List current files at server
        Add/remove files from local PC
        Copy new files to gallery at server
        Remove files from gallery at server
        Move gallery to and from Canvas
        Display the files, whether local to PC or on server

    Manage files in the logged in account
        List all files in the logged in account
        Add/remove files from local PC
        Copy new files to user account at server
        Remove files from user account at server
        Display the files, whether local to PC or on server

The very first dialog that pops up is a hack.  Without this the 
other dialogs will not show correctly unless running under ISE.
Must bring in/set some attribute that I have yet to figure out.


Source Code Layout:

	File scoped variables
	
	Utility functions
	
		Interactions with the Meural API are via a set of 
		functions named API.....
		
		Function authenticateMe does exactly that.  Dispite many
		invocations, authentication only happens once.
		
	For each of the dialogs there are grouped together
	
		Logic functions
		A function that builds the dialog
		
	Driver is at the bottom of the file
	
		Search for MAIN START


Victor Gettler
#>

#----------------------------------------------
#Import the Assemblies
#----------------------------------------------
try {
    
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase | Out-Null
    Add-Type -AssemblyName System.Drawing | Out-Null
    Add-Type -AssemblyName System.Windows.Forms | Out-Null

}

catch [Exception] {

    Write-Host "Error loading PresentationCore,PresentationFramework,WindowsBase,system.windows.forms"

}

[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[System.WIndows.Forms.Application]::EnableVisualStyles()


#
# General Useful Variables
#
$Script:myVersion = '2.0'
$Script:formGalleriesTitle = $Script:myVersion + ' Gallery Garden'

$Script:emailID = 'xxxxxxxx@xxxxxx.xxx'  # Meural account ID
$Script:emailPassword = 'xxxxxxxxxxxx'    # Meural account PWD

$Script:MaxUserItemCount = 2000
$Script:MaxGalleries = 500
$Script:meuralID = '0'
$Script:MasterAuthenticationToken = ''


#
# Working file info
#
$Script:iconFolder = $PSScriptRoot + "\Icon\"
$Script:defaultIconFolder = $PSScriptRoot + "\"
$Script:defaultIconFileName = "Default_IconPhoto.jpg"

$Script:LocalFileListUserPath =  $PSScriptRoot + "\"
$Script:LocalFileListUserName = 'LocalFileListUserName.csv'

$Script:LocalFileListGalleryPath =  $PSScriptRoot + "\"
$Script:LocalFileListGalleryPrefix = 'LocalFileListGallery'
$Script:LocalFileListGallerySuffix = '.csv'

$Script:helpFolder = $PSScriptRoot + "\Help\"


#
# Info on the gallery being worked on
#
$Script:ActiveGalleryName = ""
$Script:ActiveGalleryDesc = ""
$Script:ActiveGalleryOrientation = ""
$Script:ActiveGalleryID = ""
$Script:ActiveGalleryItemCount = ""



#
# Login
#
$Script:formLogin = New-Object 'System.Windows.Forms.Form'
$Script:InitialFormWindowStateLogin = New-Object 'System.Windows.Forms.FormWindowState'
$Script:labelID = New-Object 'System.Windows.Forms.Label'
$Script:txtboxID = New-Object 'System.Windows.Forms.TextBox'
$Script:labelPassword = New-Object 'System.Windows.Forms.Label'
$Script:txtboxPassword = New-Object 'System.Windows.Forms.TextBox'
$Script:buttonLogin = New-Object 'System.Windows.Forms.Button'
$Script:buttonLoginCancel = New-Object 'System.Windows.Forms.Button'


#
# Gallery Files: A particular gallery and its objects (photos, videos, etc.)
#
$Script:formGalleryFiles = New-Object 'System.Windows.Forms.Form'
$Script:InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
$Script:labelGalleryName = New-Object 'System.Windows.Forms.Label'
$Script:labelGalleryNameText = New-Object 'System.Windows.Forms.Label'
$Script:buttonFileAdd = New-Object 'System.Windows.Forms.Button'
$Script:buttonFileRemove = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryToServer = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryToCanvas = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryFromCanvas = New-Object 'System.Windows.Forms.Button'
$Script:buttonPartsFromServer = New-Object 'System.Windows.Forms.Button'
$Script:buttonFileDisplay = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryLocalFileSave = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryLocalFileLoad = New-Object 'System.Windows.Forms.Button'
$Script:buttonDone = New-Object 'System.Windows.Forms.Button'
$Script:labelGalleryFiles = New-Object 'System.Windows.Forms.Label'
$Script:labelGalleryFileCount = New-Object 'System.Windows.Forms.Label'
$Script:dgvGalleryFiles = New-Object 'System.Windows.Forms.DataGridView' 
$Script:alGalleryFileList = New-Object 'System.Collections.ArrayList'         # List of files in current gallery


#
# Galleries are listed
#
$Script:formGalleries = New-Object 'System.Windows.Forms.Form'
$Script:InitialFormWindowStateGWW = New-Object 'System.Windows.Forms.FormWindowState'
$Script:labelGalleriesAccount = New-Object 'System.Windows.Forms.Label'
$Script:buttonDeleteGalleries = New-Object 'System.Windows.Forms.Button'
$Script:buttonListGalleries = New-Object 'System.Windows.Forms.Button'
$Script:buttonCreateGallery = New-Object 'System.Windows.Forms.Button'
$Script:buttonBuildGallery = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryToCanvas2 = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryFromCanvas2 = New-Object 'System.Windows.Forms.Button'
$Script:buttonWorkWithFiles = New-Object 'System.Windows.Forms.Button'
$Script:buttonGalleryDone = New-Object 'System.Windows.Forms.Button'
$Script:dgvGalleryList = New-Object 'System.Windows.Forms.DataGridView' 
$Script:galleryBank = New-Object 'System.Collections.ArrayList'                       # List of galleries


#
# Create a gallery
#
$Script:formCreateGallery = New-Object 'System.Windows.Forms.Form'
$Script:InitialFormWindowStateCreateGallery = New-Object 'System.Windows.Forms.FormWindowState'
$Script:labelNewGalleryInfo = New-Object 'System.Windows.Forms.Label'
$Script:labelNewGalleryName = New-Object 'System.Windows.Forms.Label'
$Script:txtboxNewGalleryName = New-Object 'System.Windows.Forms.TextBox'
$Script:labelNewGalleryDesc = New-Object 'System.Windows.Forms.Label'
$Script:txtboxNewGalleryDesc = New-Object 'System.Windows.Forms.TextBox'
$Script:labelNewGalleryOrientation = New-Object 'System.Windows.Forms.Label'
$Script:listboxNewGalleryOrientation = New-Object 'System.Windows.Forms.ListBox'
$Script:buttonCreateGalleryCreate = New-Object 'System.Windows.Forms.Button'
$Script:buttonCreateGalleryCancel = New-Object 'System.Windows.Forms.Button'


#
# User Files
#
$Script:formFiles = New-Object 'System.Windows.Forms.Form'
$Script:InitialFormWindowStateFiles = New-Object 'System.Windows.Forms.FormWindowState'
$Script:buttonServerFileDownLoad = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileDelete = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileAdd = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileUpload = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileDisplay = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileSave = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileLoad = New-Object 'System.Windows.Forms.Button'
$Script:buttonServerFileDone = New-Object 'System.Windows.Forms.Button'
$Script:labelFileList = New-Object 'System.Windows.Forms.Label'
$Script:labelFileCount = New-Object 'System.Windows.Forms.Label'
$Script:dgvFiles = New-Object 'System.Windows.Forms.DataGridView' 
$Script:alFileList = New-Object 'System.Collections.ArrayList'



#========================================================
# Utility functions =====================================
#========================================================

function MaxDialogSizeTweak (){
    $ScreenSize = [System.Windows.Forms.Screen]::PrimaryScreen
    $PrimaryScrW = $ScreenSize.WorkingArea.Width
    $PrimaryScrH = $ScreenSize.Bounds.Height  # not presently using this
    # either workingArea or Bounds seems to work
    Switch ($PrimaryScrW) {
        "1920" {
            $Script:WidthMax = 1900
            $Script:HeightMax = 900
        }
        default {
            $Script:WidthMax = 2700
            $Script:HeightMax = 1600
        }
    }
}
function Resize-Image
{
   <#
    .SYNOPSIS
        Resize-Image resizes an image file

    .DESCRIPTION
        This function uses the native .NET API to resize an image file, and optionally save it to a file or display it on the screen. You can specify a scale or a new resolution for the new image.
        
        It supports the following image formats: BMP, GIF, JPEG, PNG, TIFF 

        Resize-Image -InputFile "C:\kitten.jpg" -Display

        Resize the image by 50% and display it on the screen.

    .EXAMPLE
        Resize-Image -InputFile "C:\kitten.jpg" -Width 200 -Height 400 -Display

        Resize the image to a specific size and display it on the screen.

    .EXAMPLE
        Resize-Image -InputFile "C:\kitten.jpg" -Scale 30 -OutputFile "C:\kitten2.jpg"

        Resize the image to 30% of its original size and save it to a new file.

    .LINK
        Author: Patrick Lambert - http://dendory.net
    #>
    Param([Parameter(Mandatory=$true)][string]$InputFile, [string]$OutputFile, [int32]$Width, [int32]$Height, [int32]$Scale, [Switch]$Display)

    # Add System.Drawing assembly
    Add-Type -AssemblyName System.Drawing

    try {

        # Open image file
        $img = [System.Drawing.Image]::FromFile((Get-Item $InputFile))

        # Define new resolution
        if($Width -gt 0) { [int32]$new_width = $Width }
        elseif($Scale -gt 0) { [int32]$new_width = $img.Width * ($Scale / 100) }
        else { [int32]$new_width = $img.Width / 2 }
        if($Height -gt 0) { [int32]$new_height = $Height }
        elseif($Scale -gt 0) { [int32]$new_height = $img.Height * ($Scale / 100) }
        else { [int32]$new_height = $img.Height / 2 }

        # Create empty canvas for the new image
        $img2 = New-Object System.Drawing.Bitmap($new_width, $new_height)

        # Draw new image on the empty canvas
        $graph = [System.Drawing.Graphics]::FromImage($img2)
        $graph.DrawImage($img, 0, 0, $new_width, $new_height)

        # Create window to display the new image
        if($Display)
        {
            Add-Type -AssemblyName System.Windows.Forms
            $win = New-Object Windows.Forms.Form
            $box = New-Object Windows.Forms.PictureBox
            $box.Width = $new_width
            $box.Height = $new_height
            $box.Image = $img2
            $win.Controls.Add($box) | Out-Null
            $win.AutoSize = $true
            $win.ShowDialog() | Out-Null
            $win.Close() | Out-Null
            $win.Dispose() | Out-Null
            $box.Dispose() | Out-Null
        }

        # Save the image
        if($OutputFile -ne "")
        {
            $imageFormat = “System.Drawing.Imaging.ImageFormat” -as [type]
            $img2.Save($OutputFile, $imageFormat::icon) | Out-Null
        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

        $img.Dispose() | Out-Null
        $img2.Dispose() | Out-Null
        $graph.Dispose() | Out-Null   

    }

}


Function authenticateMe {

    $authenticationToken = ''

	try {

        #
        # The authentication token only needs to be gotten once.  
        # Store the first one gotten in a file scoped variable and use that one
        #
        if ($Script:MasterAuthenticationToken -eq '') {

            <#
            curl --location -X POST "https://api.meural.com/v0/authenticate/" ^
            --data-urlencode "email=xxxxxxxx@xxxxxx.com" ^
            --data-urlencode "username=xxxxxxxx@xxxxxx.com"
            --data-urlencode "password=xxxxxxxxx" >AuthToken.txt
            #>
           
            $param = @{
                Uri         = "https://api.meural.com/v0/authenticate"
                Method      = "Post"
                Body        = @{
                    email=$Script:emailID
                    username=$Script:emailID
                    password=$Script:emailPassword
                }
    
            }
    
            $RESPONSE = Invoke-RestMethod @param # -OutFile PSOutputFile.txt
    
            $authenticationToken = $RESPONSE.token
    
            $Script:MasterAuthenticationToken = $authenticationToken

        }
        else {

            $authenticationToken = $Script:MasterAuthenticationToken
        }

    }

    catch [Exception] {
    
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
        
    }

    finally {
    
    }

    #
    # Put token on output stream
    #
    $authenticationToken

}


Function APIPOSTItemToUser () {

    Param($MyFile, $AuthenticationToken)

    try {

        <#
        curl --location --request POST '{{API_ORIGIN}}{{VERSION}}/items' \
            --header 'Authorization: Token {{TOKEN}}' \
            --form 'image=@/path/to/file'
        #>

        $param = @{
            Uri         = "https://api.meural.com/v0/items"
            Method      = "POST"                         
        }

        $headers1 = @{
            Authorization="Token $AuthenticationToken"
            Content = 'image/jpeg'
        }

        $Form = @{
            image = Get-Item $MyFile -Force
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers1 -Form $Form -ContentType 'multipart/form-data' 
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIDELETEUserItem () {

    Param($MyItemID, $AuthenticationToken)

    try {

        #curl --location --request DELETE '{{API_ORIGIN}}{{VERSION}}/items/{{itemId}}' \
        #--header 'Authorization: Token {{TOKEN}}'

        $param = @{
            Uri         = "https://api.meural.com/v0/items/$MyItemID"
            Method      = "DELETE"      
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIGETUserItems () {

    Param($MaxUserItemCount, $AuthenticationToken)

    try {
        <# ---------------
        curl --location --request GET '{{API_ORIGIN}}{{VERSION}}/user/items?count=10&page=1' \
            --header 'Authorization: Token {{TOKEN}}'
        ----------------- #>

        $param = @{
            Uri = "https://api.meural.com/v0/user/items?count=$MaxUserItemCount&page=1"
            Method = "GET"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

    }
    
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIPOSTItemToGallery () {

    Param($GalleryID, $ItemID, $AuthenticationToken)

    try {
        #
        # Associate file with gallery
        #
        <#
        curl --location --request POST '{{API_ORIGIN}}{{VERSION}}/galleries/{{galleryId}}/items/{{itemId}}' \
            --header 'Authorization: Token {{TOKEN}}'
        #>

        $param = @{
            Uri         = "https://api.meural.com/v0/galleries/" + $GalleryID + "/items/" + $ItemID
            Method      = "POST"                         
        }

        $headers = @{
            Authorization = "Token $AuthenticationToken"
            Content = 'application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIGetGalleryItems {

    Param ($GalleryName, $GalleryID, $MaxItems, $AuthenticationToken)

    try {

        <# ---------------
        curl --location --request GET '{{API_ORIGIN}}{{VERSION}}/galleries/18359/items' \
            --data-urlencode 'name=My first playlist' \
            --data-urlencode 'description=My greate playlist' \
            --data-urlencode 'orientation=vertical'
        ----------------- #>

        $param = @{
            Uri = "https://api.meural.com/v0/galleries/$GalleryID/items?count=$MaxItems&page=1"
            Method = "GET"
            Body = @{
                name=$GalleryName
            }            
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE
}


Function APIDELETEItemFromGallery {

    Param($GalleryID, $MyItemID, $AuthenticationToken)

    try {
        <#
        curl --location DELETE '{{API_ORIGIN}}{{VERSION}}/galleries/{{galleryId}}/items/{{itemId}}' \
            --header 'Authorization: Token {{TOKEN}}'
        #>

        $param = @{
            Uri         = "https://api.meural.com/v0/galleries/" + $GalleryID + "/items/" + $MyItemID
            Method      = "DELETE"      
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIDELETEGallary () {

    Param($CurrentID, $AuthenticationToken)

    try {
        <#---
        curl --location --request DELETE '{{API_ORIGIN}}{{VERSION}}/galleries/37361' \
            --header 'Authorization: Token {{TOKEN}}'
        ---#>

        $param = @{
            Uri         = "https://api.meural.com/v0/galleries/" + $CurrentID
            Method      = "Delete"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIGetDeviceID () {

    Param ($AuthenticationToken)

    try {
        #
        # Get ID of the device
        #
        # curl --location --request GET '{{API_ORIGIN}}{{VERSION}}/user/devices?count=10&page=1' \
        # --header 'Authorization: Token {{TOKEN}}'

        $MeuralID = ""

        $param = @{
            Uri         = "https://api.meural.com/v0/user/devices?count=10&page=1"
            Method      = "Get"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

        if ($RESPONSE.count -eq 0) {
            $MeuralID= ""
        } else {
            $MeuralID = $RESPONSE.data[0].id
        }
    
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    #
    # Put ID into the stream
    #
    $MeuralID
}


Function APIPOSTGallery () {

    Param($NewGalleryName, $NewGalleryDesc, $NewGalleryOrientation, $AuthenticationToken)

    try {

        #
        # Define Gallery at the server
        #
        <#
        curl --location --request POST '{{API_ORIGIN}}{{VERSION}}/galleries' \
            --header 'Authorization: Token {{TOKEN}}' \
            --data-urlencode 'name=My first playlist' \
            --data-urlencode 'description=My greate playlist' \
            --data-urlencode 'orientation=vertical'
        #>

        $param = @{
            Uri         = "https://api.meural.com/v0/galleries"
            Method      = "Post"
            Body        = @{
                name=$NewGalleryName
                description=$NewGalleryDesc
                orientation=$NewGalleryOrientation
            }
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

    }
    
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIDELETEItem () {

    Param($MyItemID, $AuthenticationToken)

    try {
        <#---
        curl --location --request DELETE '{{API_ORIGIN}}{{VERSION}}/items/{{itemId}}' \
        --header 'Authorization: Token {{TOKEN}}'
        ---#>

        $param = @{
            Uri = "https://api.meural.com/v0/items/" + $MyItemID
            Method = "Delete"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE
}



Function APIDELETEGalaryFromCanvas () {

    Param ($MeuralID,$CurrentID,$AuthenticationToken)

    try {
        #
        # curl --location --request DELETE '{{API_ORIGIN}}{{VERSION}}/devices/{{galleryId}}/galleries/{{deviceId}}' \
        # --header 'Authorization: Token {{TOKEN}}'

        $myURI="https://api.meural.com/v0/devices/$MeuralID/galleries/$CurrentID"

        $param = @{
            Uri         = $myURI
            Method      = "Delete"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt
    }
        
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE

}


Function APIGetUserGalleries () {
    
    Param ($AuthenticationToken)

    try {
    
        # curl --location --request GET '{{API_ORIGIN}}{{VERSION}}/user/galleries?count=10&page=1' \
        # --header 'Authorization: Token {{TOKEN}}'

        $param = @{
            Uri         = "https://api.meural.com/v0/user/galleries?count=200&page=1"
            Method      = "Get"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param -Headers $headers # -OutFile PSOutputFile.txt 
    }
    
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE
        
}


Function APIGetGalleriesOnDevice () {

    Param ($MeuralID, $GalleriesPerPage, $AuthenticationToken)

    try {

        # curl --location --request GET '{{API_ORIGIN}}{{VERSION}}/devices/1545/galleries?count=10&page=1' \
        # --header 'Authorization: Token {{TOKEN}}'

        $param = @{
            Uri         = "https://api.meural.com/v0/devices/$MeuralID/galleries?count=$GalleriesPerPage&page=1"
            Method      = "Get"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param -Headers $headers # -OutFile PSOutputFile.txt 

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE
        


}


Function APIPOSTGalleryToCanvas () {

    Param ($MeuralID, $CurrentID, $AuthenticationToken)

    try {

        $myURI="https://api.meural.com/v0/devices/$MeuralID/galleries/$CurrentID"
        $param = @{
            Uri         = $myURI
            Method      = "Post"
        }

        $headers = @{
            Authorization="Token $AuthenticationToken"
            Content='application/json'
        }

        $RESPONSE = Invoke-RestMethod @param  -Headers $headers # -OutFile PSOutputFile.txt

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

    $RESPONSE
}



Function GetGalleryFiles () {

    try {

        #
        # For the current gallery, read whatever parts that are in it at the 
        # server side and populate the datagridview
        #
        if ($Script:ActiveGalleryItemCount -gt 0) {

            $authenticationToken = authenticateMe

            $RESPONSE = APIGetGalleryItems  $Script:ActiveGalleryName  `
                                            $Script:ActiveGalleryID $Script:ActiveGalleryItemCount `
                                            $authenticationToken

            foreach ($itemObj in $RESPONSE.data) {

                $myPath = $itemObj.image
                $FName = $itemObj.name
                $filecreateTime = $itemObj.updatedAt
                $myItemID = $itemObj.id

                #
                # Create the icon filename and make sure it does not exist in the working folder
                #           
                if (($myPath.Length -gt 8) -and ($myPath.Substring(0,8) -eq '\Public\')) {

                    $fullFileName = "C:\Users" + $myPath + "\" + $FName

                    if (!(Test-Path $fullFileName)) {
                        $fullFileName = $Script:defaultIconFolder + $Script:defaultIconFileName
                    }
                }

                else {
                    $fullFileName = $Script:defaultIconFolder + $Script:defaultIconFileName
                }


                $iconFileName = $Script:iconFolder + $FName

                if (Test-Path $iconFileName) {
                    Remove-Item $iconFileName | Out-Null
                }

                Resize-Image -InputFile $fullFileName -Scale 1 -OutputFile $iconFileName
                $img = [System.Drawing.Image]::Fromfile($iconFileName)
                $icon = [System.Drawing.Icon]::FromHandle($img.GetHicon())  

                #
                # Coming from netgear server
                #
                $atServer = "Yes" 

                #
                # Populate the next row.
                #  
                $row1 = @($FName, "Image", $atServer, $myPath, $filecreateTime, $icon, $myItemID)

                #
                # Put new row in repository for display
                #
                $Script:dgvGalleryFiles.Rows.Add($row1) | Out-Null

                #
                # Free space, cleanup, get rid of locks
                #
                $img.Dispose() | Out-Null
                $icon.Dispose() | Out-Null

            } # foreach


            #
            # Resize the columns 
            #
            $Script:dgvGalleryFiles.AutoResizeColumn(0) | Out-Null     # File name
            $Script:dgvGalleryFiles.AutoResizeColumn(1) | Out-Null     # Type
            $Script:dgvGalleryFiles.AutoResizeColumn(2) | Out-Null     # On server flag
            #$Script:dgvGalleryFiles.AutoResizeColumn(3) | Out-Null     # Path segment
            $Script:dgvGalleryFiles.AutoResizeColumn(4) | Out-Null     # Creation date
            $Script:dgvGalleryFiles.AutoResizeColumn(5) | Out-Null     # Thumbnail
            $Script:dgvGalleryFiles.AutoResizeColumn(6) | Out-Null     # ID in gallery

        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

}



#========================================================
# Login =================================================
#========================================================

Function formLogin_Load 
{
		
	try {

        $Script:txtboxID.Text = $Script:emailID
        $Script:txtboxPassword.Text = $Script:emailPassword

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }
    
    finally {

    }

}


Function buttonLogin_Click ()
{  
    try {

        if ($Script:txtboxID.Text -eq "" -or $Script:txtboxPassword.Text -eq "") {

            #
            # Error.  Both fields need a value
            #
            $Msg = 'ID and Password must both be filled in.'
            [System.Windows.MessageBox]::Show($Msg,'Login', 0, 16) | Out-Null

            $Script:formLogin.DialogResult = "Retry"

        } 
        
        else {
            
            $Script:emailID = $Script:txtboxID.Text
            $Script:emailPassword = $Script:txtboxPassword.Text

            $Script:formLogin.DialogResult = 'OK'

        }
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

        $Script:formLogin.DialogResult = 'Cancel'
    }

    finally {
        
    }
}


function buttonLoginCancel_Click() 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
        
    }

    finally {

    }

}


Function txtboxID_Change () {

    try {

    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


Function txtboxPassword_Change () {

    try {


    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


function formLogin_Closing () 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formLogin_Help () {

    try {
    
        $helpFilePDF = $Script:helpFolder + 'formLogin.pdf'

        Invoke-Item $helpFilePDF | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}




Function Build_Login_Dialog () 
{
    try {

	    [System.Windows.Forms.Application]::EnableVisualStyles() 

        $Script:formLogin = New-Object 'System.Windows.Forms.Form'
        $Script:InitialFormWindowStateLogin = New-Object 'System.Windows.Forms.FormWindowState'
        $Script:labelID = New-Object 'System.Windows.Forms.Label'
        $Script:txtboxID = New-Object 'System.Windows.Forms.TextBox'
        $Script:labelPassword = New-Object 'System.Windows.Forms.Label'
        $Script:txtboxPassword = New-Object 'System.Windows.Forms.TextBox'
        $Script:buttonLogin = New-Object 'System.Windows.Forms.Button'
        $Script:buttonLoginCancel = New-Object 'System.Windows.Forms.Button'
        

	    #
	    # formGalleriesWorkWith
        #
	    $Script:formLogin.Controls.Add($Script:labelID)
        $Script:formLogin.Controls.Add($Script:txtboxID)
  	    $Script:formLogin.Controls.Add($Script:labelPassword)
        $Script:formLogin.Controls.Add($Script:txtboxPassword)
        $Script:formLogin.Controls.Add($Script:buttonLogin)
        $Script:formLogin.Controls.Add($Script:buttonLoginCancel)

        $Script:formLogin.Location = New-Object System.Drawing.Point(2000,500)
        $Script:formLogin.StartPosition = 'CenterScreen'
        $Script:formLogin.WindowState = 'Normal'
        $Script:formLogin.ClientSize = New-Object System.Drawing.Size(1100,450)
	    $Script:formLogin.Name = 'formLogin'
        $Script:formLogin.Text = 'Netgear Login Credentials'
        
        $Script:formLogin.MaximizeBox = $false
        $Script:formLogin.MinimizeBox = $false
        $Script:formLogin.HelpButton = $false    # No need for now

        $Script:formLogin.Add_Load({formLogin_Load})
        $Script:formLogin.Add_Closing({formLogin_Closing})
        $Script:formLogin.Add_HelpButtonClicked({formLogin_Help})

        $NewGalleryDataLeftSide = 75

	    #
	    # ID label
	    #
	    $Script:labelID.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25)
        $Script:labelID.Location = New-Object System.Drawing.Point($NewGalleryDataLeftSide,
                                                                   $NewGalleryDataLeftSide)
	    $Script:labelID.Name = 'newGalleryName'
	    $Script:labelID.Size = New-Object System.Drawing.Size(200,40)
	    $Script:labelID.Text = 'ID:'

	    #
	    # ID text box
	    #
        $Script:txtboxID.Location = New-Object System.Drawing.Point(($Script:labelID.Right+10),
                                                                    ($Script:labelID.Top))
	    $Script:txtboxID.Name = 'txtboxID'
	    $Script:txtboxID.Size = New-Object System.Drawing.Size(750,200)
        $Script:txtboxID.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
	    $Script:txtboxID.TabIndex = 3
        $Script:txtboxID.add_TextChanged({txtboxID_Change})

        #
	    # Password label
	    #
	    $Script:labelPassword.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25)    
        $Script:labelPassword.Location = New-Object System.Drawing.Point(($Script:labelID.Left),
                                                                         ($Script:labelID.Bottom+30))
	    $Script:labelPassword.Name = 'labelPassword'
	    $Script:labelPassword.Size = New-Object System.Drawing.Size(200,40)
	    $Script:labelPassword.Text = 'Password:'

	    #
	    # Password text box
	    #
        $Script:txtboxPassword.Location = New-Object System.Drawing.Point(($Script:txtboxID.Left),
                                                                          ($Script:labelPassword.Top))
	    $Script:txtboxPassword.Name = 'txtboxPassword'
	    $Script:txtboxPassword.Size = New-Object System.Drawing.Size(750,200)
        $Script:txtboxPassword.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
	    $Script:txtboxPassword.TabIndex = 4
        $Script:txtboxPassword.add_TextChanged({txtboxPassword_Change})

   	    #
	    # Login
	    #
        $Script:buttonLogin.DialogResult = 'OK'
        $Script:buttonLogin.Location = New-Object System.Drawing.Point( ($Script:labelPassword.Left+250),
                                                                        ($Script:txtboxPassword.Bottom+100))
	    $Script:buttonLogin.Name = 'buttonLogin'
	    $Script:buttonLogin.Size = New-Object System.Drawing.Size(170,90)
	    $Script:buttonLogin.TabIndex = 1
	    $Script:buttonLogin.Text = 'Login'
        $Script:buttonLogin.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonLogin.UseVisualStyleBackColor = $True
	    $Script:buttonLogin.add_Click({buttonLogin_Click})

	    #
	    # Cancel
	    #
	    $Script:buttonLoginCancel.DialogResult = 'Cancel'
        $Script:buttonLoginCancel.Location = New-Object System.Drawing.Point(   ($Script:buttonLogin.Right+50),
                                                                                        ($Script:buttonLogin.Top))
	    $Script:buttonLoginCancel.Name = 'buttonDone'
	    $Script:buttonLoginCancel.Size = New-Object System.Drawing.Size(170,90)
	    $Script:buttonLoginCancel.TabIndex = 2
	    $Script:buttonLoginCancel.Text = 'Cancel'
        $Script:buttonLoginCancel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonLoginCancel.UseVisualStyleBackColor = $True
	    $Script:buttonLoginCancel.add_Click({buttonLoginCancel_Click})


    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}





#========================================================
# Gallery List ==========================================
#========================================================
Function reloadGalleryList
{

	try {

        #
        # Load the array list with the Galleries found under our account
        #

        $authenticationToken = authenticateMe

        #
        # Just clear out the entire galleryBank array list and refill it
        # Might be just as efficient as adding in the new stuff
        #
        $Script:galleryBank.Clear() | Out-Null

        if ($Script:meuralID -ne "") {

            $RESPONSE = APIGetGalleriesOnDevice $Script:meuralID $Script:MaxGalleries $authenticationToken

            Foreach ($galleryObj in $RESPONSE.data) {

                $count = $count + 1
                $myName = $galleryObj.name
                $myID = $galleryObj.id
                $myItemCount = $galleryObj.itemCount
                $myDescription = $galleryObj.description
                $myOrientation = $galleryObj.orientation
                $myDate = $galleryObj.updatedAt
                $Null = $Script:galleryBank.Add((New-Object -TypeName psobject `
                    -Property @{Name=$myName;ItemCount=$myItemCount;ID=$myID;
                        Orientation=$myOrientation;Date=$myDate;
                        Description=$myDescription;OnCanvas='Yes'}))

            }

        }


        $RESPONSE = APIGetUserGalleries $authenticationToken
        
        Foreach ($galleryObj in $RESPONSE.data) {

            $myID = $galleryObj.id

            $FoundIt = $False
            Foreach ($bankObj in $Script:galleryBank) {
                If ($bankObj.ID -eq $myID) {
                    $FoundIt = $True
                    Break
                }
            }

            if ($FoundIt -eq $False) {

                $myName = $galleryObj.name
                $myItemCount = $galleryObj.itemCount    # itemIds
                $myDescription = $galleryObj.description
                $myOrientation = $galleryObj.orientation
                $myDate = $galleryObj.updatedAt
                $myOnCanvas = 'No'
                $Null = $Script:galleryBank.Add((New-Object -TypeName psobject `
                    -Property @{Name=$myName;ItemCount=$myItemCount;ID=$myID;
                        Orientation=$myOrientation;Date=$myDate;
                        Description=$myDescription;OnCanvas=$myOnCanvas}))
    
            } else {
                #
                # Just update the number of items
                #
                $myItemCount = $galleryObj.itemCount

            }

        }


        #
        # Empty the datagridview object if it contains more than just the initial blank row
        #
        if ($Script:dgvGalleryList.RowCount -gt 1) {

            $Script:dgvGalleryList.Rows.Clear() | Out-Null

        }


        #
        # Now add the galleries found to the displayed view
        #
        foreach ($GInfo in $Script:galleryBank)
        {    
            $GalleryName = $GInfo.Name
            $ItemCount = $GInfo.ItemCount
            $Orient = $GInfo.Orientation
            $Desc = $GInfo.Description
            $GalleryID = $GInfo.ID
            $Date = $GInfo.Date
            $OnCanvas = $GInfo.OnCanvas
            
            #
            # Populate the next row.
            #
            $row1 = @($GalleryName, $ItemCount, $Orient, $Desc, $Date, $OnCanvas, $GalleryID)

            #
            # Put new row in repository
            #
            $Script:dgvGalleryList.Rows.Add($row1) | Out-Null
        }

        #
        # Resize the columns 
        #
        $Script:dgvGalleryList.AutoResizeColumn(0) | Out-Null     # Name
        $Script:dgvGalleryList.AutoResizeColumn(1) | Out-Null     # Item Count
        $Script:dgvGalleryList.AutoResizeColumn(2) | Out-Null     # Orientation
        $Script:dgvGalleryList.AutoResizeColumn(3) | Out-Null     # Description
        $Script:dgvGalleryList.AutoResizeColumn(4) | Out-Null     # Date Updated
        $Script:dgvGalleryList.AutoResizeColumn(5) | Out-Null     # On Canvas?
        $Script:dgvGalleryList.AutoResizeColumn(6) | Out-Null     # ID
       
        
        #
        # HOW TO SORT THE NAME COLUMN ????????????????????
        #
        #$Script:dgvGalleryList.Sort($datagridviewResults.Columns[4],'Descending')

        $Script:dgvGalleryList.ClearSelection() | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }
    
    finally {

    }

}


Function formGalleries_Load 
{
		
	try {

        reloadGalleryList | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }
    
    finally {

    }

}


Function BuildGallery_Click () {

    try {

        #
        # Display form for adding, removing photos, videos to selected gallery
        #

        # Make sure one and only 1 gallery selected
        # Put up message and return if that's not the case

        if ($Script:dgvGalleryList.SelectedRows.Count -eq 1) {

            formGalleriesWorkWith_InProgress | Out-Null

            $Script:formGalleryFiles.SuspendLayout() | Out-Null

            foreach ($Row in $Script:dgvGalleryList.SelectedRows) {

                #
                # Save pertinant info on the active gallery 
                #
                $Script:labelGalleryNameText.Text = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Name'].Value
                $Script:ActiveGalleryName = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Name'].Value
                $Script:ActiveGalleryItemCount = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Items at Server'].Value
                $Script:ActiveGalleryOrientation = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Orientation'].Value
                $Script:ActiveGalleryDesc = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Description'].Value
                $Script:ActiveGalleryID = $Script:dgvGalleryList.Rows[$Row.Index].Cells['ID'].Value

            } # foreach


            #
            # Start with no files in cache
            #
            $Script:dgvGalleryFiles.Rows.Clear() | Out-Null

            #
            # List the items already under selected gallery on the server
            #
            GetGalleryFiles | Out-Null

            #
            # Update the number of files in the current gallery
            #
            $myCount = $Script:dgvGalleryFiles.Rows.Count - 1
            $Script:labelGalleryFileCount.Text = "$myCount"

            
            $Script:formGalleryFiles.ResumeLayout() | Out-Null
            $Script:formGalleryFiles.Refresh() | Out-Null
            

            Do {

                $Script:formGalleryFiles.ShowDialog() | Out-Null
            
            }
            Until ($Script:formGalleryFiles.DialogResult -ne "Retry")
            
            formGalleriesWorkWith_Waiting | Out-Null

        }

        else {

            #
            # Error.  Must select one and ONLY one gallery to build
            #
            $Msg = 'Select one and only one gallery to build.'
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery Build', 0, 16)
        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


Function WorkWithFilesButton_Click () {

    try {

        formGalleriesWorkWith_InProgress | Out-Null

        $Script:dgvFiles.Rows.Clear()

        Do {

            $Script:formFiles.ShowDialog() | Out-Null
        
        }
        Until ($Script:formFiles.DialogResult -ne "Retry")
       
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {
        
    }

    formGalleriesWorkWith_Waiting | Out-Null

}


function AddGalleryToCanvasButton2_Click()
{
    #
    #  Send a gallery to the Meural Canvas itself
    #

    try {

        #
        # Set status
        #
        formGalleriesWorkWith_InProgress | Out-Null

        $Script:formGalleries.SuspendLayout() | Out-Null

        #
        # Tell server to send the selected Galleries to the Canvas
        #
        # Loop through rows 
        #
        if ($Script:dgvGalleryList.SelectedRows.Count -gt 0) {

            if ($Script:meuralID -ne "") {

                $authenticationToken = authenticateMe

                foreach ($Row in $Script:dgvGalleryList.SelectedRows) {
    
                    $currentName = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Name'].Value
                    $itemsInGallery = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Items at Server'].Value
                    $currentID = $Script:dgvGalleryList.Rows[$Row.Index].Cells['ID'].Value
    
                    if ($itemsInGallery -eq 0) {
    
                        $Msg = 'Gallery "' + $currentName + '" is empty. It will NOT be sent to Canvas.'
                        [System.Windows.MessageBox]::Show($Msg,'Remove Gallery from Canvas', 0, 16) | Out-Null
    
                    } elseif ($currentID -ne "") {
    
                        #
                        # Tell server to send the named Gallery to the Canvas
                        #
    
                        $authenticationToken = authenticateMe   

                        $RESPONSE = APIPOSTGalleryToCanvas $Script:meuralID `
                                        $currentID $authenticationToken
                    }
    
                } # foreach
    
                #
                # refresh the Gallery name list
                #
                reloadGalleryList | Out-Null

            }

        } else {

            #
            # No Galleries selected
            #
            $Msg = 'No Gallery selected.'
            [System.Windows.MessageBox]::Show($Msg,'Send Gallery to Canvas', 0, 16) | Out-Null

        }

        #
        # Set status
        #
        formGalleriesWorkWith_Done | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }

}


Function DeleteGalleries_Click ()
{
  
    try {

        $authenticationToken = authenticateMe

        #
        # Loop through rows and remove the selected ones
        #

        if ($Script:dgvGalleryList.SelectedRows.Count -gt 0) {

            formGalleriesWorkWith_InProgress | Out-Null

            foreach ($Row in $Script:dgvGalleryList.SelectedRows) {

                $currentName = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Name'].Value
                $galleryFileCount = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Items at Server'].Value
                # $currentOrientation = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Orientation'].Value
                # $currentDesc = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Description'].Value
                $onCanvas = $Script:dgvGalleryList.Rows[$Row.Index].Cells['On Canvas'].Value
                $currentID = $Script:dgvGalleryList.Rows[$Row.Index].Cells['ID'].Value

                $Msg = 'Delete gallery "' + $currentName + '", id ' + $currentID + '?'
                $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery Deletion','YesNo',32)  

                switch  ($msgBoxInput) {

                'Yes' {

                    $originalTitle = $Script:formGalleries.Text

                    #
                    # If on Canvas, remove the gallery from there too, first
                    #
                    if ($onCanvas -eq 'Yes') {

                        $Script:formGalleries.Text = 
                            $originalTitle + 
                            " Removing gallery $currentName from Canvas"
                        #
                        # Tell server to remove the named Gallery from the Canvas
                        # #

                        $RESPONSE = APIDELETEGalaryFromCanvas $Script:meuralID $currentID $authenticationToken

                    }


                    #
                    # Remove from the server all files pointed to by the gallery
                    #

                    if ($galleryFileCount -gt 0) {

                        #
                        # Get a list of the files in the gallery
                        #
                        $RESPONSE = APIGetGalleryItems $currentName $currentID $galleryFileCount $authenticationToken

                        #
                        # Delete each file in the gallery from the server
                        #
                        $deletedFileCount = 0
                        foreach ($itemObj in $RESPONSE.data) {

                            $deletedFileCount = $deletedFileCount + 1
                            
                            $myName = $itemObj.name

                            $Script:formGalleries.Text = 
                                $originalTitle + 
                                " Deleting file $myName, $deletedFileCount of $galleryFileCount"


                            $myItemID = $itemObj.id

                            $RESPONSE = APIDELETEItem $myItemID $authenticationToken
                        } #foreach

                    } #if
 
                    #
                    # Remove the gallery from the server next
                    #

                    $Script:formGalleries.Text = $originalTitle + " Deleting gallery $currentName"

                    $RESPONSE = APIDELETEGallary $currentID $authenticationToken

                } #switch


                'No' {

                      ## Do something

                }
               
                } # end of switch

            } # foreach

            reloadGalleryList | Out-Null

            formGalleriesWorkWith_Done | Out-Null

        } else {

            #
            # No Galleries selected to remove
            #
            $Msg = 'No Gallery selected for removal.'
            [System.Windows.MessageBox]::Show($Msg,'Remove Gallery from Canvas', 0, 16) | Out-Null

        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {
        
    }
}


Function formGalleriesWorkWith_InProgress () {

    try {

        #
        # Set status message to IN PROGRESS
        #
        $Script:formGalleries.Text = $Script:formGalleriesTitle + ":  IN PROGRESS!!!!!!!!!!!!!!!!!!!!"

        #
        # Disable buttons
        #
        $Script:buttonDeleteGalleries.Enabled = $False
        $Script:buttonListGalleries.Enabled = $False
        $Script:buttonCreateGallery.Enabled = $False
        $Script:buttonBuildGallery.Enabled = $False
        $Script:buttonGalleryDone.Enabled = $False
        $Script:buttonGalleryToCanvas2.Enabled = $False
        $Script:buttonGalleryFromCanvas2.Enabled = $False
        $Script:buttonWorkWithFiles.Enabled = $False

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formGalleriesWorkWith_Waiting () {

    try {

        #
        # Set status message to just ready
        #

        $Script:formGalleries.Text = $Script:formGalleriesTitle

        #
        # Enable buttons
        #
        $Script:buttonDeleteGalleries.Enabled = $True
        $Script:buttonListGalleries.Enabled = $True
        $Script:buttonCreateGallery.Enabled = $True
        $Script:buttonBuildGallery.Enabled = $True
        $Script:buttonGalleryDone.Enabled = $True
        $Script:buttonGalleryToCanvas2.Enabled = $True
        $Script:buttonGalleryFromCanvas2.Enabled = $True
        $Script:buttonWorkWithFiles.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formGalleriesWorkWith_Done () {

    try {

        #
        # Set status message to IN PROGRESS
        #

        $Script:formGalleries.Text = $Script:formGalleriesTitle + '    DONE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

        #
        # Enable buttons
        #
        $Script:buttonDeleteGalleries.Enabled = $True
        $Script:buttonListGalleries.Enabled = $True
        $Script:buttonCreateGallery.Enabled = $True
        $Script:buttonBuildGallery.Enabled = $True
        $Script:buttonGalleryDone.Enabled = $True
        $Script:buttonGalleryToCanvas2.Enabled = $True
        $Script:buttonGalleryFromCanvas2.Enabled = $True
        $Script:buttonWorkWithFiles.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


function RemoveGalleryFromCanvasButton2_Click()
{
    #
    #  Remove a gallery from the Meural Canvas itself
    #

    try {

        #
        # Set status
        #
        formGalleriesWorkWith_InProgress | Out-Null

        $Script:formGalleries.SuspendLayout() | Out-Null

        #
        # Tell server to remove the selected Galleries from the Canvas
        #
        # Loop through rows and make sure the On Canvas is set to Yes on selected rows
        #
        if ($Script:dgvGalleryList.SelectedRows.Count -gt 0) {

            $authenticationToken = authenticateMe

            foreach ($Row in $Script:dgvGalleryList.SelectedRows) {

                $currentName = $Script:dgvGalleryList.Rows[$Row.Index].Cells['Gallery Name'].Value
                $onCanvas = $Script:dgvGalleryList.Rows[$Row.Index].Cells['On Canvas'].Value
                $currentID = $Script:dgvGalleryList.Rows[$Row.Index].Cells['ID'].Value

                if ($onCanvas -ne 'Yes') {
                    #
                    # tell user gallery is NOT on canvas
                    #
                    $Msg = 'Gallery "' + $currentName + '" NOT ON the Canvas.'
                    [System.Windows.MessageBox]::Show($Msg,'Remove Gallery from Canvas', 0, 16) | Out-Null

                }
                elseif ($currentID -ne "" -and $onCanvas -eq 'Yes') {

                    $RESPONSE = APIDELETEGalaryFromCanvas $Script:meuralID $currentID $authenticationToken

                } #if

            } #foreach

            #
            # refresh the Gallery name list
            #
            reloadGalleryList | Out-Null

        } else {

            #
            # No Galleries selected
            #
            $Msg = 'No Gallery selected.'
            [System.Windows.MessageBox]::Show($Msg,'Send Gallery to Canvas', 0, 16) | Out-Null

        }

        #
        # Set status
        #
        formGalleriesWorkWith_Done | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleries.ResumeLayout() | Out-Null
        $Script:formGalleries.Refresh() | Out-Null

    }

}


Function CreateGalleryDialog_Click ()
{  
    try {

        Do {

            $Script:formCreateGallery.ShowDialog() | Out-Null
        
        }
        Until ($Script:formGalleryFiles.DialogResult -ne "Retry")
       
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {
        
    }
}


Function ListGalleries_Click ()
{
    
    try {

        reloadGalleryList | Out-Null  

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {
        
    }
}


function formGalleries_Done_Button_Click() 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


function formGalleries_Closing() 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formGalleries_Help () {

    try {
    
        $helpFilePDF = $Script:helpFolder + 'formGalleries.pdf'

        Invoke-Item $helpFilePDF | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


Function Build_Define_Galleries_Dialog () 
{
    try {
 
        [System.Windows.Forms.Application]::EnableVisualStyles

	    $Script:formGalleries.SuspendLayout()

	    #
	    # formGalleries
        #
        $Script:formGalleries.Controls.Add($Script:labelGalleriesAccount)
        $Script:formGalleries.Controls.Add($Script:buttonDeleteGalleries)
        # $Script:formGalleries.Controls.Add($Script:buttonListGalleries)
        $Script:formGalleries.Controls.Add($Script:buttonCreateGallery)
        $Script:formGalleries.Controls.Add($Script:buttonBuildGallery)
        $Script:formGalleries.Controls.Add($Script:buttonGalleryToCanvas2)
        $Script:formGalleries.Controls.Add($Script:buttonGalleryFromCanvas2)
        $Script:formGalleries.Controls.Add($Script:buttonWorkWithFiles)
        $Script:formGalleries.Controls.Add($Script:buttonGalleryDone)
        $Script:formGalleries.Controls.Add($Script:dgvGalleryList)

        $Script:formGalleries.Location  = New-Object System.Drawing.Point(1000,500)
        $Script:formGalleries.StartPosition = 'CenterScreen'
        $Script:formGalleries.WindowState = 'Normal'
        $Script:formGalleries.ClientSize = New-Object System.Drawing.Size($WidthMax,$HeightMax)
        $Script:formGalleries.Name = 'formGalleriesWorkWith'
        $Script:formGalleries.Text = $Script:formGalleriesTitle
         
        $Script:formGalleries.MaximizeBox = $False
        $Script:formGalleries.MinimizeBox = $False
        $Script:formGalleries.HelpButton = $True


        $Script:formGalleries.ShowInTaskBar = $True

        $Script:formGalleries.Add_Load({formGalleries_Load})
        $Script:formGalleries.Add_Closing({formGalleries_Closing})
        $Script:formGalleries.Add_HelpButtonClicked({formGalleries_Help})

        $buttonHeight = 110

   	    #
	    # Create a gallery
	    #
	    $Script:buttonCreateGallery.DialogResult = 'None'
	    $Script:buttonCreateGallery.Location = New-Object System.Drawing.Point(50,50)
	    $Script:buttonCreateGallery.Name = 'CreateGallery'
	    $Script:buttonCreateGallery.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonCreateGallery.TabIndex = 1
	    $Script:buttonCreateGallery.Text = 'Create Gallery on Server'
        $Script:buttonCreateGallery.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonCreateGallery.UseVisualStyleBackColor = $True
	    $Script:buttonCreateGallery.add_Click({CreateGalleryDialog_Click})

	    #
	    # Work with gallery files
	    #
	    $Script:buttonBuildGallery.DialogResult = 'None'
	    $Script:buttonBuildGallery.Location = New-Object System.Drawing.Point(($Script:buttonCreateGallery.Right+20),($Script:buttonCreateGallery.Top))
	    $Script:buttonBuildGallery.Name = 'WorkWithGalleryFiles'
	    $Script:buttonBuildGallery.Size = New-Object System.Drawing.Size(330,$buttonHeight)
	    $Script:buttonBuildGallery.TabIndex = 2
	    $Script:buttonBuildGallery.Text = 'Work With Gallery Files'
        $Script:buttonBuildGallery.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonBuildGallery.UseVisualStyleBackColor = $True
	    $Script:buttonBuildGallery.add_Click({BuildGallery_Click})

	    #
	    # Delete the highlighted galleries
	    #
	    $Script:buttonDeleteGalleries.DialogResult = 'None'
	    $Script:buttonDeleteGalleries.Location = New-Object System.Drawing.Point(($Script:buttonBuildGallery.Right+20),($Script:buttonBuildGallery.Top))
	    $Script:buttonDeleteGalleries.Name = 'DeleteGalleries'
	    $Script:buttonDeleteGalleries.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonDeleteGalleries.TabIndex = 3
	    $Script:buttonDeleteGalleries.Text = 'Delete Gallery From Server'
        $Script:buttonDeleteGalleries.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonDeleteGalleries.UseVisualStyleBackColor = $True
	    $Script:buttonDeleteGalleries.add_Click({DeleteGalleries_Click})

	    #
	    # buttonGalleryToCanvas
	    #
	    $Script:buttonGalleryToCanvas2.DialogResult = 'None' #'Retry'
	    $Script:buttonGalleryToCanvas2.Location = New-Object System.Drawing.Point(($Script:buttonDeleteGalleries.Right+200),($Script:buttonDeleteGalleries.Top))
	    $Script:buttonGalleryToCanvas2.Name = 'GalleryToCanvas'
	    $Script:buttonGalleryToCanvas2.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonGalleryToCanvas2.TabIndex = 4
	    $Script:buttonGalleryToCanvas2.Text = 'Send Gallery to Canvas'
        $Script:buttonGalleryToCanvas2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryToCanvas2.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryToCanvas2.add_Click({AddGalleryToCanvasButton2_Click})

        #
	    # buttonGalleryFromCanvas
	    #
	    $Script:buttonGalleryFromCanvas2.DialogResult = 'None' #'Retry'
	    $Script:buttonGalleryFromCanvas2.Location = New-Object System.Drawing.Point(($Script:buttonGalleryToCanvas2.Right+20),($Script:buttonGalleryToCanvas2.Top))
	    $Script:buttonGalleryFromCanvas2.Name = 'GalleryFromCanvas'
	    $Script:buttonGalleryFromCanvas2.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonGalleryFromCanvas2.TabIndex = 5
	    $Script:buttonGalleryFromCanvas2.Text = 'Remove Gallery from Canvas'
        $Script:buttonGalleryFromCanvas2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryFromCanvas2.UseVisualStyleBackColor = $True
        $Script:buttonGalleryFromCanvas2.add_Click({RemoveGalleryFromCanvasButton2_Click})

	    #
	    # List the galleries in the account
	    #
	    # $Script:buttonListGalleries.DialogResult = 'None'
	    # $Script:buttonListGalleries.Location = New-Object System.Drawing.Point(($Script:buttonDeleteGalleries.Right+20),($Script:buttonDeleteGalleries.Top))
	    # $Script:buttonListGalleries.Name = 'ListGalleries'
	    # $Script:buttonListGalleries.Size = New-Object System.Drawing.Size(260,$buttonHeight)
	    # $Script:buttonListGalleries.TabIndex = 5
	    # $Script:buttonListGalleries.Text = 'List Galleries'
        # $Script:buttonListGalleries.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25, [System.Drawing.FontStyle]::Bold)
	    # $Script:buttonListGalleries.UseVisualStyleBackColor = $True
	    # $Script:buttonListGalleries.add_Click({ListGalleries_Click})

   	    #
	    # Work with server files
	    #
	    $Script:buttonWorkWithFiles.DialogResult = 'None'
        $Script:buttonWorkWithFiles.Location = New-Object System.Drawing.Point(($Script:buttonGalleryFromCanvas2.Right+150),
                                                                               ($Script:buttonGalleryFromCanvas2.Top))
	    $Script:buttonWorkWithFiles.Name = 'WorkWithFiles'
	    $Script:buttonWorkWithFiles.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonWorkWithFiles.TabIndex = 6
	    $Script:buttonWorkWithFiles.Text = 'User Files Workbench'
        $Script:buttonWorkWithFiles.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonWorkWithFiles.UseVisualStyleBackColor = $True
	    $Script:buttonWorkWithFiles.add_Click({WorkWithFilesButton_Click})




	    #
	    # Done
	    #
	    $Script:buttonGalleryDone.DialogResult = 'OK'
        $Script:buttonGalleryDone.Location = New-Object System.Drawing.Point(($Script:buttonWorkWithFiles.Right+150),
                                                                             ($Script:buttonWorkWithFiles.Top))
	    $Script:buttonGalleryDone.Name = 'buttonDone'
	    $Script:buttonGalleryDone.Size = New-Object System.Drawing.Size(170,$buttonHeight)
	    $Script:buttonGalleryDone.TabIndex = 7
	    $Script:buttonGalleryDone.Text = 'Leave'
        $Script:buttonGalleryDone.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryDone.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryDone.add_Click({formGalleries_Done_Button_Click})

        #
	    # Label for gallery list
	    #
        $Script:labelGalleriesAccount.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:labelGalleriesAccount.ForeColor = [Drawing.Color]::Black
        $Script:labelGalleriesAccount.Location = New-Object System.Drawing.Point(50,($Script:buttonCreateGallery.Bottom+75))
	    $Script:labelGalleriesAccount.Name = 'galleriesAccount'
	    $Script:labelGalleriesAccount.Size = New-Object System.Drawing.Size(350,50)
	    $Script:labelGalleriesAccount.Text = 'Galleries'
        $Script:labelGalleriesAccount.Visible = $True

        #
        # Data Grid View
        #
        $Script:dgvGalleryList.Location = New-Object System.Drawing.Point(100,($Script:labelGalleriesAccount.Bottom+30))
        $Script:dgvGalleryList.Size = New-Object System.Drawing.Size(2500,1200)  
        $Script:dgvGalleryList.ScrollBars = 'Both' # 'Vertical'
        $Script:dgvGalleryList.ColumnCount = 7
        $Script:dgvGalleryList.Visible = $True
        $Script:dgvGalleryList.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
        $Script:dgvGalleryList.SelectionMode = 'FullRowSelect'
        $Script:dgvGalleryList.ColumnHeadersHeightSizeMode = 'AutoSize'
        $Script:dgvGalleryList.AutoSizeRowsMode = "DisplayedCells" #"None" #AllCells, None, AllHeaders, DisplayedHeaders, DisplayedCells

        $Script:dgvGalleryList.Add_CellMouseDoubleClick({BuildGallery_Click})

        $Script:dgvGalleryList.Columns[0].Name = "Gallery Name"
        $Script:dgvGalleryList.Columns[1].Name = "Gallery Items at Server"
        $Script:dgvGalleryList.Columns[2].Name = "Orientation"
        $Script:dgvGalleryList.Columns[3].Name = "Description"
        $Script:dgvGalleryList.Columns[4].Name = "Date Changed"
        $Script:dgvGalleryList.Columns[5].Name = "On Canvas"
        $Script:dgvGalleryList.Columns[6].Name = "ID"

        $Script:dgvGalleryList.Columns[0].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[1].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[2].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[3].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[4].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[5].SortMode = 'Automatic'
        $Script:dgvGalleryList.Columns[6].SortMode = 'Automatic'

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleries.ResumeLayout() | Out-Null

    }

}


#========================================================
# New Gallery ===========================================
#========================================================
Function formCreateGallery_Load 
{
		
	try {

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }
    
    finally {

    }

}


Function CreateGallery_Click ()
{  
    try {

        $targetID = 'NotFound'

        #
        # Gallery name must not be blank
        #
        if ($Script:txtboxNewGalleryName.Text -eq "") {
            
            $targetID = "BlankName"  # something other than NotFound
            $Msg = 'Gallery name not specified.'

        }
        else {

            #
            # do not allow duplicate gallery names
            #

            $currentName = $Script:txtboxNewGalleryName.Text
            
            foreach ($entry in $Script:galleryBank) {

                if ($entry.Name -eq $currentName) {

                    $targetID = $entry.ID  # something other than NotFound
                    Break    # got what is needed so stop loop

                }

            } # foreach

        } # else


        if ($targetID -eq 'NotFound') {

            $authenticationToken = authenticateMe

            #
            # Define Gallery at the server
            #       
            $RESPONSE = APIPOSTGallery  $Script:txtboxNewGalleryName.Text `
                                        $Script:txtboxNewGalleryDesc.Text `
                                        $Script:listboxNewGalleryOrientation.Text `
                                        $authenticationToken
            #
            # refresh the Gallery name list
            #
            reloadGalleryList | Out-Null

            #
            # Select the row with the newly added name
            #
            #$Script:dgvGalleryList.Column[0]........


            #
            # tell user
            #
            #$Msg = 'Gallery "' + $currentName + '" created.'
            #$msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery Creation','OK','Information')

            #
            # reset entry fields
            #
            $Script:txtboxNewGalleryName.Text = ""
            $Script:txtboxNewGalleryDesc.Text = ""
            $Script:listboxNewGalleryOrientation.Text = 'horizontal'


        }
        else {

            #
            # Gallery xyz already exists or no name specified
            #

            if ($targetID -eq "BlankName") {
                $Msg = 'Gallery name is blank!'
            } else {
                $Msg = 'Gallery "' + $currentName + '" already exists.'
            }

            [System.Windows.MessageBox]::Show($Msg,'Gallery Creation', 0, 16) | Out-Null
            
        }
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {
        
    }
}


Function txtboxNewGalleryName_Change () {

    try {

        $Script:formGalleryFiles.SuspendLayout() | Out-Null



        $Script:formGalleryFiles.ResumeLayout() | Out-Null

    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


Function txtboxTextGeneral_Change () {

    try {


    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


function formCreateGalleryCancel_Button_Click() 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


function formCreateGallery_Closing () 
{

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        #

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formCreateGallery_Help () {

    try {
    
        $helpFilePDF = $Script:helpFolder + 'formCreateGallery.pdf'

        Invoke-Item $helpFilePDF | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}



Function Build_Create_Gallery_Dialog () 
{
    try {

	    [System.Windows.Forms.Application]::EnableVisualStyles() 

	    #
	    # formGalleriesWorkWith
        #
	    $Script:formCreateGallery.Controls.Add($Script:labelNewGalleryName)
        $Script:formCreateGallery.Controls.Add($Script:txtboxNewGalleryName)
  	    $Script:formCreateGallery.Controls.Add($Script:labelNewGalleryDesc)
        $Script:formCreateGallery.Controls.Add($Script:txtboxNewGalleryDesc)
        $Script:formCreateGallery.Controls.Add($Script:labelNewGalleryOrientation)
        $Script:formCreateGallery.Controls.Add($Script:listboxNewGalleryOrientation)
        $Script:formCreateGallery.Controls.Add($Script:buttonCreateGalleryCreate)
        $Script:formCreateGallery.Controls.Add($Script:buttonCreateGalleryCancel)
        $Script:formCreateGallery.Location  = New-Object System.Drawing.Point(2000,100)
        $Script:formCreateGallery.StartPosition = 'CenterScreen'
        $Script:formCreateGallery.WindowState = 'Normal'
        $Script:formCreateGallery.ClientSize = New-Object System.Drawing.Size(1200,700)
	    $Script:formCreateGallery.Name = 'formGalleriesWorkWith'
        $Script:formCreateGallery.Text = 'Create New Gallery'

        $Script:formCreateGallery.MaximizeBox = $False
        $Script:formCreateGallery.MinimizeBox = $False
        $Script:formCreateGallery.HelpButton = $True

        $Script:formCreateGallery.Add_Load({formCreateGallery_Load})
        $Script:formCreateGallery.Add_Closing({formCreateGallery_Closing})
        $Script:formCreateGallery.Add_HelpButtonClicked({formCreateGallery_Help})
        

        $NewGalleryDataLeftSide = 75

	    #
	    # Gallery name label
	    #
	    $Script:labelNewGalleryName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25)
        $Script:labelNewGalleryName.Location = New-Object System.Drawing.Point($NewGalleryDataLeftSide,
                                                                               $NewGalleryDataLeftSide)
	    $Script:labelNewGalleryName.Name = 'newGalleryName'
	    $Script:labelNewGalleryName.Size = New-Object System.Drawing.Size(250,40)
	    $Script:labelNewGalleryName.Text = 'Gallery Name:'

	    #
	    # Gallery name text box
	    #
        $Script:txtboxNewGalleryName.Location = New-Object System.Drawing.Point(($Script:labelNewGalleryName.Right+10),
                                                                                ($Script:labelNewGalleryName.Top))
	    $Script:txtboxNewGalleryName.Name = 'txtboxGalleryName'
	    $Script:txtboxNewGalleryName.Size = New-Object System.Drawing.Size(750,200)
        $Script:txtboxNewGalleryName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
	    $Script:txtboxNewGalleryName.TabIndex = 1
        $Script:txtboxNewGalleryName.add_TextChanged({txtboxNewGalleryName_Change})

        #
	    # Gallery desc label
	    #
	    $Script:labelNewGalleryDesc.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25)    
        $Script:labelNewGalleryDesc.Location = New-Object System.Drawing.Point( ($Script:labelNewGalleryName.Left),
                                                                                ($Script:labelNewGalleryName.Bottom+30))
	    $Script:labelNewGalleryDesc.Name = 'galleryDesc'
	    $Script:labelNewGalleryDesc.Size = New-Object System.Drawing.Size(200,40)
	    $Script:labelNewGalleryDesc.Text = 'Description:'

	    #
	    # Gallery desc text box
	    #
        $Script:txtboxNewGalleryDesc.Location = New-Object System.Drawing.Point(($Script:txtboxNewGalleryName.Left),
                                                                                ($Script:labelNewGalleryDesc.Top))
	    $Script:txtboxNewGalleryDesc.Name = 'txtboxGalleryDesc'
	    $Script:txtboxNewGalleryDesc.Size = New-Object System.Drawing.Size(750,200)
        $Script:txtboxNewGalleryDesc.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
	    $Script:txtboxNewGalleryDesc.TabIndex = 2
        $Script:txtboxNewGalleryDesc.add_TextChanged({txtboxTextGeneral_Change})

        #
	    # Gallery orientation label
	    #
	    $Script:labelNewGalleryOrientation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25)
        $Script:labelNewGalleryOrientation.Location = New-Object System.Drawing.Point(  ($Script:labelNewGalleryName.Left),
                                                                                        ($Script:labelNewGalleryDesc.Bottom+30))
	    $Script:labelNewGalleryOrientation.Name = 'galleryOrientation'
	    $Script:labelNewGalleryOrientation.Size = New-Object System.Drawing.Size(200,40)
	    $Script:labelNewGalleryOrientation.Text = 'Orientation:'

	    #
	    # Gallery orientation list box
	    #
        $Script:listboxNewGalleryOrientation.Location = New-Object System.Drawing.Point(($Script:txtboxNewGalleryDesc.Left),
                                                                                        ($Script:labelNewGalleryOrientation.Top))
	    $Script:listboxNewGalleryOrientation.Name = 'listboxGalleryOrient'
	    $Script:listboxNewGalleryOrientation.Size = New-Object System.Drawing.Size(250,105)
        $Script:listboxNewGalleryOrientation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
	    $Script:listboxNewGalleryOrientation.TabIndex = 3
        $Script:listboxNewGalleryOrientation.add_TextChanged({txtboxTextGeneral_Change})
        [void] $Script:listboxNewGalleryOrientation.Items.Add('horizontal')
        [void] $Script:listboxNewGalleryOrientation.Items.Add('vertical')
        $Script:listboxNewGalleryOrientation.Text = 'horizontal'         # default

   	    #
	    # Create a gallery
	    #
	    $Script:buttonCreateGalleryCreate.DialogResult = 'OK'
        $Script:buttonCreateGalleryCreate.Location = New-Object System.Drawing.Point(   ($NewGalleryDataLeftSide*4),
                                                                                        ($Script:listboxNewGalleryOrientation.Bottom+150))
	    $Script:buttonCreateGalleryCreate.Name = 'CreateGallery'
	    $Script:buttonCreateGalleryCreate.Size = New-Object System.Drawing.Size(300,90)
	    $Script:buttonCreateGalleryCreate.TabIndex = 4
	    $Script:buttonCreateGalleryCreate.Text = 'Create Gallery'
        $Script:buttonCreateGalleryCreate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonCreateGalleryCreate.UseVisualStyleBackColor = $True
	    $Script:buttonCreateGalleryCreate.add_Click({CreateGallery_Click})

	    #
	    # Cancel
	    #
	    $Script:buttonCreateGalleryCancel.DialogResult = 'OK'
	    $Script:buttonCreateGalleryCancel.Location = New-Object System.Drawing.Point(($Script:buttonCreateGalleryCreate.Right+50),($Script:buttonCreateGalleryCreate.Top))
	    $Script:buttonCreateGalleryCancel.Name = 'buttonDone'
	    $Script:buttonCreateGalleryCancel.Size = New-Object System.Drawing.Size(170,90)
	    $Script:buttonCreateGalleryCancel.TabIndex = 5
	    $Script:buttonCreateGalleryCancel.Text = 'Cancel'
        $Script:buttonCreateGalleryCancel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonCreateGalleryCancel.UseVisualStyleBackColor = $True
	    $Script:buttonCreateGalleryCancel.add_Click({formCreateGalleryCancel_Button_Click})


    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


#========================================================
# Gallery Files =========================================
#========================================================
Function formGallery_Load 
{
	try {

        #
        # Resize the columns 
        #
        $Script:dgvGalleryFiles.AutoResizeColumn(0) | Out-Null     # File name
        $Script:dgvGalleryFiles.AutoResizeColumn(1) | Out-Null     # Type
        $Script:dgvGalleryFiles.AutoResizeColumn(2) | Out-Null     # On server flag
        #$Script:dgvGalleryFiles.AutoResizeColumn(3) | Out-Null     # Path segment
        $Script:dgvGalleryFiles.AutoResizeColumn(4) | Out-Null     # Creation date
        $Script:dgvGalleryFiles.AutoResizeColumn(5) | Out-Null     # Thumbnail
        $Script:dgvGalleryFiles.AutoResizeColumn(6) | Out-Null     # ID in gallery


    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }
    
    finally {

    }
        
}


Function DisplayFileImageButton_Click () {

    try {       

        #
        # Loop through rows and display the selected ones
        #

        if ($Script:dgvGalleryFiles.SelectedRows.Count -gt 0) {

            foreach ($Row in $Script:dgvGalleryFiles.SelectedRows) {

                $onServer = $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['On Server'].Value

                if ($onServer -eq "Yes") {

                    $myURL = $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['Path'].Value

                    start $myURL

                }

                else {
                    #
                    # File is on PC.
                    #
                    $myName = $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['File Name'].Value

                    #
                    # Avoid the blank row being highlighted
                    #
                    if ($myName.Length -gt 0) {

                        $myPath = 
                            $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['Path'].Value + "\" +
                            $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['File Name'].Value

                        Invoke-Item $myPath

                    }

                }

            }

        }

    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }
}


function FileAddButton_Click()
{
    
    #
    # Show Open File dialog
    # User selects files
    # Add files to the array list
    #

    try {

        #
        # Set status
        #
        formGallery_InProgress | Out-Null

        $Script:formGalleryFiles.SuspendLayout() | Out-Null

        <#
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Multiselect = $true
            }
        #>

        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = 'C:\Users\Public' 
            Multiselect = $true
        }
                    
        $result = $FileBrowser.ShowDialog()

        if ($result -ne 'Cancel') {
            $NameList = New-Object System.Collections.ArrayList

            foreach ($FName in $FileBrowser.SafeFileNames) {
    
                $NameList.Add($FName) | Out-Null
    
            }
    
            $numberOfFileNames = $FileBrowser.FileNames.Count
    
            $FIdx = 0
            foreach ($FName in $FileBrowser.FileNames) 
            {    
    
                $fileProperty = Get-ItemProperty -Path $FName

                if ($fileProperty.Extension -eq '.jpg' -or $fileProperty.Extension -eq '.jpeg') {
    
                    $filecreateTime = $fileProperty.LastWriteTime
    
                    #
                    # figure out path starting at \Public\
                    #
                    # $startIndex = $fileProperty.DirectoryName.IndexOf('\Public\')
                    # if ($startIndex -lt 0) {
                    #     $myPath = $fileProperty.DirectoryName
                    # }
                    # else {
                    #     $myPath = $fileProperty.DirectoryName.Substring(($startIndex))
                    # }               
                    $myPath = $fileProperty.DirectoryName
        
        
                    #
                    # Create the icon filename and make sure it does not exist in the working folder
                    #
                    $iconFileName = $Script:iconFolder + $NameList.Item($FIdx)
        
                    if (Test-Path $iconFileName) {
                        Remove-Item $iconFileName | Out-Null
                    }
        
                    Resize-Image -InputFile $FName -Scale 1 -OutputFile $iconFileName
                    $img = [System.Drawing.Image]::Fromfile($iconFileName)
                    $icon = [System.Drawing.Icon]::FromHandle($img.GetHicon())
        
                    #
                    # Meural ID, Meural image is unknown at this time
                    #
                    $myID = ""
        
                    #
                    # Local to PC
                    #
                    $atServer = "No"
        
                    #
                    # Populate the next row.
                    #    
                    $row1 = @($NameList.Item($FIdx), "Image", $atServer, $myPath, $filecreateTime, $icon, $myID)
        
        
                    #
                    # Put new row in repository for display
                    #
                    $Script:dgvGalleryFiles.Rows.Add($row1) | Out-Null
        
                    #
                    # Free space
                    #
                    $img.Dispose() | Out-Null
                    $icon.Dispose() | Out-Null
    
                }
                else {

                    $myName = $NameList.Item($FIdx)
                    $Msg = "$myName does not have type .jpg or .jpeg"
                    [System.Windows.MessageBox]::Show($Msg,'Add a File', 0, 16) | Out-Null


                }
        
    
                #
                # Go to next file name in the list
                #
                $Fidx = $Fidx + 1
    
                $Script:labelGalleryFileCount.Text = "$Fidx of $numberOfFileNames new files added"
                $Script:labelGalleryFiles.Refresh()
                
            } # foreach
    
            $myCount = $Script:dgvGalleryFiles.Rows.Count - 1
            $Script:labelGalleryFileCount.Text = "$myCount"
    
            #
            # Resize the columns 
            #
            $Script:dgvGalleryFiles.AutoResizeColumn(0) | Out-Null     # File name
            $Script:dgvGalleryFiles.AutoResizeColumn(1) | Out-Null     # Type
            $Script:dgvGalleryFiles.AutoResizeColumn(2) | Out-Null     # On server flag
            #$Script:dgvGalleryFiles.AutoResizeColumn(3) | Out-Null     # Path segment
            $Script:dgvGalleryFiles.AutoResizeColumn(4) | Out-Null     # Creation date
            $Script:dgvGalleryFiles.AutoResizeColumn(5) | Out-Null     # Thumbnail
            $Script:dgvGalleryFiles.AutoResizeColumn(6) | Out-Null     # ID

        }

        
        #
        # Set status
        #
        formGallery_Done | Out-Null
        
        
        #
        # Cleanup
        #
        $FileBrowser.Dispose() | Out-Null
    }


    catch
    {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }


    finally
    {
        $Script:formGalleryFiles.ResumeLayout() | Out-Null
    }


    <#

    #Populate the rows.
    $row1 = @($True,"DSC_001","Image", "20190411", $icon)
    $row2 = @($True,"DSC_002","Image", "20190412", $icon)
    $row3 = @($True,"DSC_005","Image", "20190413", $icon)
    $row4 = @($True,"DSC_001","Image", "20190414", $icon)
    $rows = @($row1, $row2, $row3, $row4)
	
    foreach ($row in $rows){
        $DGV.Rows.Add($row)
    }

    #>



}


function FileRemoveButton_Click()
{
    #
    # Remove from the array list the highlighted files
    #

    try {

        #
        # Set status
        #
        formGallery_InProgress | Out-Null
        
        $Script:formGalleryFiles.SuspendLayout() | Out-Null

        #
        # Loop through rows and remove the selected ones
        #

        if ($Script:dgvGalleryFiles.SelectedRows.Count -gt 0) {

            $totalDeleted = $Script:dgvGalleryFiles.SelectedRows.Count
            $myCount = 0

            $Msg = 'Remove highlighted files from gallery and server?'
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'File Removal','YesNo',32) 

            if ($msgBoxInput -eq "Yes") {

                $authenticationToken = authenticateMe

                foreach ($Row in $Script:dgvGalleryFiles.SelectedRows) {

                    #
                    # If file is in gallery on server, remove from that gallery
                    #
                    $onServer = $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['On Server'].Value
    
                    if ($onServer -eq "Yes") {
    
                        #
                        # Remove file from the gallery
                        #
                        $myItemID = $Script:dgvGalleryFiles.Rows[$Row.Index].Cells['ID'].Value
    
                        # $authenticationToken = authenticateMe
    
                        $RESPONSE = APIDELETEItemFromGallery $Script:ActiveGalleryID $myItemID $authenticationToken
                    
                        #
                        # Delete the file from server
                        #               
                        $RESPONSE = APIDELETEItem $myItemID $authenticationToken
        
                    } #if on server
    
                    #
                    # Check for Yes and No to screen out that all blank row that sometimes sneaks in
                    #
                    if ($onServer -eq "Yes" -or $onServer -eq "No") {
    
                        #
                        # Take file out of current gallery list
                        #
                        $Script:dgvGalleryFiles.Rows.RemoveAt($Row.Index) | Out-Null
                    }
    
                    #
                    # Update the file count label
                    #
                    $myCount = $myCount + 1
                    $Script:labelGalleryFileCount.Text = "$myCount of $totalDeleted removed"
            
                } #foreach
    
            }

            #
            # Update the file count label
            #
            # Subtract 1 for the blank row
            #
            $myCount = $Script:dgvGalleryFiles.Rows.Count - 1
            $Script:labelGalleryFileCount.Text = "$myCount"

        } #if


        #
        # Recalculate the info for the gallery table
        #
        reloadGalleryList | Out-Null

        #
        # Set status
        #
        formGallery_Done | Out-Null
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }

}


Function GalleryLocalFileSaveButton_Click () {

    try {

        formGallery_InProgress | Out-Null

        $count = $Script:dgvGalleryFiles.Rows.Count
        $foundIt = $false

        if ($count -gt 1) {

            $targetFile = 
                $Script:LocalFileListGalleryPath + 
                $Script:LocalFileListGalleryPrefix + 
                $Script:ActiveGalleryName + 
                $Script:LocalFileListGallerySuffix

            if (Test-Path $targetFile) {
                Remove-Item $targetFile | Out-Null
            }
            
            $numberFileNamesSaved = 0
            $myIdx = 0

            do {
    
                if ($Script:dgvGalleryFiles.Rows[$myIdx].Cells['On Server'].Value -eq "No") {

                    $myName = $Script:dgvGalleryFiles.Rows[$myIdx].Cells['File Name'].Value
                    $myPath = $Script:dgvGalleryFiles.Rows[$myIdx].Cells['Path'].Value
                    $myQualifiedValue = $myPath + '\' + $myName

                    Add-Content -Path $targetFile -Value $myQualifiedValue

                    $numberFileNamesSaved += 1
                }
                
                $myIdx = $myIdx + 1

            } until ($myIdx -eq $count -or $foundIt -eq $True)

            if ($numberFileNamesSaved -eq 0) {
                
                $Msg = 'No local file names found to save.'
                [System.Windows.MessageBox]::Show($Msg,'Save Names of Local Files', 0, 16) | Out-Null

            }

        } else {

            $Msg = 'No local file names found to save.'
            [System.Windows.MessageBox]::Show($Msg,'Save Names of Local Files', 0, 16) | Out-Null

        }

    }

    
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

    formGallery_Done | Out-Null

}


Function GalleryLocalFileLoadButton_Click () {

    try {

        formGallery_InProgress | Out-Null

        $Script:formGalleryFiles.SuspendLayout() | Out-Null

        $targetFile = 
            $Script:LocalFileListGalleryPath + 
            $Script:LocalFileListGalleryPrefix + 
            $Script:ActiveGalleryName + 
            $Script:LocalFileListGallerySuffix

        if ((Test-Path $targetFile) -eq $True) {
    
            $file_data = Get-Content -Path $targetFile

            if ($file_data.count -gt 0) {

                $FIdx = 0
    
                foreach ($line in $file_data) {
        
                    $fileProperty = Get-ItemProperty -Path $line
        
                    $myFileName = $fileProperty.Name
                    $filecreateTime = $fileProperty.LastWriteTime
                    $myPath = $fileProperty.DirectoryName
            
                    #
                    # Create the icon filename and make sure it does not exist in the working folder
                    #
                    $iconFileName = $Script:iconFolder + $myFileName
        
                    if (Test-Path $iconFileName) {
                        Remove-Item $iconFileName | Out-Null
                    }
        
                    Resize-Image -InputFile $line -Scale 1 -OutputFile $iconFileName
                    $img = [System.Drawing.Image]::Fromfile($iconFileName)
                    $icon = [System.Drawing.Icon]::FromHandle($img.GetHicon())
        
                    #
                    # Meural ID, Meural image is unknown at this time
                    #
                    $myID = ""
        
                    #
                    # Local to PC
                    #
                    $atServer = "No"
        
                    #
                    # Populate the next row.
                    #    
                    $row1 = @($myFileName, 
                              "Image", 
                              $atServer, 
                              $myPath, 
                              $filecreateTime, 
                              $icon, 
                              $myID)
        
        
                    #
                    # Put new row in repository for display
                    #
                    $Script:dgvGalleryFiles.Rows.Add($row1) | Out-Null
        
                    #
                    # Free space
                    #
                    $img.Dispose() | Out-Null
                    $icon.Dispose() | Out-Null
        
                    #
                    # Go to next file name in the list
                    #
                    $Fidx = $Fidx + 1
        
                    $Script:labelGalleryFileCount.Text = "$Fidx of $numberOfFileNames new files added"
                    $Script:labelGalleryFiles.Refresh()
                    
                } # foreach
        
                $myCount = $Script:dgvGalleryFiles.Rows.Count - 1
                $Script:labelGalleryFileCount.Text = "$myCount"
        
                #
                # Resize the columns 
                #
                $Script:dgvGalleryFiles.AutoResizeColumn(0) | Out-Null     # File name
                $Script:dgvGalleryFiles.AutoResizeColumn(1) | Out-Null     # Type
                $Script:dgvGalleryFiles.AutoResizeColumn(2) | Out-Null     # On server flag
                #$Script:dgvGalleryFiles.AutoResizeColumn(3) | Out-Null     # Path segment
                $Script:dgvGalleryFiles.AutoResizeColumn(4) | Out-Null     # Creation date
                $Script:dgvGalleryFiles.AutoResizeColumn(5) | Out-Null     # Thumbnail
                $Script:dgvGalleryFiles.AutoResizeColumn(6) | Out-Null     # ID
    
            } else {

                # 
                # No lines in the file
                #
                $Msg = 'No files named in the saved list.'
                [System.Windows.MessageBox]::Show($Msg,'Load Local Files From Saved List', 0, 16) | Out-Null   

            }


        } else {
            #
            # File not found
            #
            $Msg = 'Saved list of files was not found.'
            [System.Windows.MessageBox]::Show($Msg,'Load Local Files From Saved List', 0, 16) | Out-Null

        }
       
    }

    
    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        #
        # Set status
        #
        formGallery_Done | Out-Null

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }

}





function GalleryToServerButton_Click()
{
    #
    # Add gallery and all files to the server
    #
    # Gallery will be on server to have gotten to this point 
    # For each specified file, if not already on server, upload the file
    # If not already tied to gallery, add file to gallery
    #

    <#

        $Script:dgvGalleryFiles.Columns[0].Name = "File Name"
        $Script:dgvGalleryFiles.Columns[1].Name = "Type"
        $Script:dgvGalleryFiles.Columns[2].Name = "On Server"
        $Script:dgvGalleryFiles.Columns[3].Name = "Path"
        $Script:dgvGalleryFiles.Columns[4].Name = "Creation Date"   
        $Script:dgvGalleryFiles.Columns.Insert(5,$iconCol)
        $Script:dgvGalleryFiles.Columns[5].Name = "Icon"
        $Script:dgvGalleryFiles.Columns[6].Name = "ID"

        $Script:ActiveGalleryID

    #>

    try {

        #
        # There will always be at least one row due to blank row 
        #
        if ($Script:dgvGalleryFiles.Rows.Count -gt 1) {

            #
            # Set status
            #
            formGallery_InProgress | Out-Null

            $Script:formGalleryFiles.SuspendLayout() | Out-Null      
        
            #
            # Subtract 1 for the blank row that is always at the end
            #
            $RowCount = $Script:dgvGalleryFiles.Rows.Count - 1

            $RowIndex = 0

            do {

                $authenticationToken = authenticateMe

                $atServer = $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['On Server'].Value

                if ($atServer -eq "No") {

                    #
                    # Send file to server before tieing it to gallery
                    #
                    <#
                    curl --location --request POST '{{API_ORIGIN}}{{VERSION}}/items' \
                        --header 'Authorization: Token {{TOKEN}}' \
                        --form 'image=@/path/to/file'
                    #>

                    $myFile =
                        $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['Path'].Value + "\" + 
                        $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['File Name'].Value


                    $param = @{
                        Uri         = "https://api.meural.com/v0/items"
                        Method      = "POST"                         
                    }

                    $headers1 = @{
                        Authorization="Token $authenticationToken"
                        Content = 'image/jpeg'
                    }

                    $Form = @{
                        image = Get-Item $myFile -Force
                    }
            
                    $RESPONSE = Invoke-RestMethod @param  -Headers $headers1 -Form $Form -ContentType 'multipart/form-data' 

                    #
                    # Update file data since it is now on the server
                    #
                    $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['On Server'].Value = "Yes"
                    $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['Path'].Value = $RESPONSE.data.image
                    $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['ID'].Value = $RESPONSE.data.id

                }

                #
                # Associate file with gallery
                #

                $myID = $Script:dgvGalleryFiles.Rows[$RowIndex].Cells['ID'].Value

                $RESPONSE = APIPOSTItemToGallery $Script:ActiveGalleryID $myID $authenticationToken

                $RowIndex = $RowIndex + 1

            } until($RowIndex -eq $RowCount)

            #
            # Recalculate the info for the gallery table
            #
            reloadGalleryList | Out-Null


            #
            # Update status
            #
            formGallery_Done | Out-Null

        }
        else {

            #
            # No files to send up is an error
            #
            $Msg = "No files found to send up."
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery to Server', 0, 16)

        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)        
        Write-Host $Error.Message
    }

    finally {

        formGallery_Done | Out-Null

    }

}


function AddGalleryToCanvasButton_Click()
{
    #
    #  Send a gallery to the Meural Canvas itself
    #

    try {

        #
        # Set status
        #
        formGallery_InProgress | Out-Null

        $itemsInGallery = $Script:dgvGalleryFiles.RowCount

        if ($itemsInGallery -eq 1) {

            $Msg = 'Gallery "' + $Script:ActiveGalleryName + '" is empty. It will NOT be sent to Canvas.'
            [System.Windows.MessageBox]::Show($Msg,'Remove Gallery from Canvas', 0, 16) | Out-Null

        } 
        else {

            $Script:formGalleryFiles.SuspendLayout() | Out-Null

            #
            # Get ID of the device
            #  
    
            if ($Script:meuralID -ne "" ) {

                #
                # Tell server to send the named Gallery to the Canvas
                #
        
                $RESPONSE = APIPOSTGalleryToCanvas $Script:meuralID $Script:ActiveGalleryID $authenticationToken
        
                # 
                # Maybe later, if files are in the list, add the files 
                # to the Gallery at the server and then tell server to 
                # send Gallery
                # 
        
                #
                # refresh the Gallery name list
                #
                reloadGalleryList | Out-Null

            }

        } 

        #
        # Set status
        #
        formGallery_Done | Out-Null
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }

}


# Author field contains lower end of item path name.
#              blank means search local PC folders for the item name.
# Add attribute to internal array list containing the lower end of the item path name.
#
# Add attribute to displayed datagridview to indicate "on server" "not on server"
#                  internal array list
function PartsFromServerButton_Click()
{

    try {

        #
        # Set status
        #
        formGallery_InProgress | Out-Null

        $Script:formGalleryFiles.SuspendLayout() | Out-Null

        #
        # Remove records for files from server
        # Work backwards so that when a row is removed the next index will
        #   be unchanged.
        #
        $count = $Script:dgvGalleryFiles.Rows.Count
        if ($count -gt 1) {
            $myIdx = $count - 1
            do {
    
                if ($Script:dgvGalleryFiles.Rows[$myIdx].Cells['On Server'].Value -eq "Yes") {
                    $Script:dgvGalleryFiles.Rows.RemoveAt($myIdx)
                }
                
                $myIdx = $myIdx - 1
            } until ($myIdx -lt 0)
    
        }


        GetGalleryFiles | Out-Null


        #
        # Set status
        #
        formGallery_Done | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }
}


function RemoveGalleryFromCanvasButton_Click()
{
    #
    #  Remove a gallery from the Meural Canvas itself
    #

    try {

        #
        # Set status
        #
        formGallery_InProgress | Out-Null

        $Script:formGalleryFiles.SuspendLayout() | Out-Null

        #
        # Get ID of the device
        #

        if ($Script:meuralID -ne "") {

            #
            # Tell server to remove the named Gallery from the Canvas
            #
            $RESPONSE = APIDELETEGalaryFromCanvas   $Script:meuralID `
                                                    $Script:ActiveGalleryID `
                                                    $authenticationToken
            #
            # refresh the Gallery name list
            #
            reloadGalleryList | Out-Null

        }


        #
        # Set status
        #
        formGallery_Done | Out-Null
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null
        $Script:formGalleryFiles.Refresh() | Out-Null

    }

}


Function formGallery_InProgress () {

    try {

        #
        # Set status message to IN PROGRESS
        #

        $Script:formGalleryFiles.Text = $Script:myVersion + ' Work With Gallery Files:     IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

        #
        # Disable buttons
        #
        $Script:buttonFileAdd.Enabled = $false
        $Script:buttonFileRemove.Enabled = $false
        $Script:buttonGalleryToServer.Enabled = $false
        $Script:buttonGalleryToCanvas.Enabled = $false
        $Script:buttonGalleryFromCanvas.Enabled = $false
        $Script:buttonPartsFromServer.Enabled = $false
        $Script:buttonFileDisplay.Enabled = $false
        $Script:buttonGalleryLocalFileSave.Enabled = $false
        $Script:buttonGalleryLocalFileLoad.Enabled = $false
        $Script:buttonDone.Enabled = $false

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formGallery_Waiting () {

    try {

        #
        # Set status message to IN PROGRESS
        #

        $Script:formGalleryFiles.Text = $Script:myVersion + ' Work With Gallery Files'

        #
        # Disable buttons
        #
        $Script:buttonFileAdd.Enabled = $True
        $Script:buttonFileRemove.Enabled = $True
        $Script:buttonGalleryToServer.Enabled = $True
        $Script:buttonGalleryToCanvas.Enabled = $True
        $Script:buttonGalleryFromCanvas.Enabled = $True
        $Script:buttonPartsFromServer.Enabled = $True
        $Script:buttonFileDisplay.Enabled = $True
        $Script:buttonGalleryLocalFileSave.Enabled = $True
        $Script:buttonGalleryLocalFileLoad.Enabled = $True
        $Script:buttonDone.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formGallery_Done () {

    try {

        #
        # Set status message to IN PROGRESS
        #

        $Script:formGalleryFiles.Text = $Script:myVersion + ' Work With Gallery Files:     DONE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

        #
        # Disable buttons
        #
        $Script:buttonFileAdd.Enabled = $True
        $Script:buttonFileRemove.Enabled = $True
        $Script:buttonGalleryToServer.Enabled = $True
        $Script:buttonGalleryToCanvas.Enabled = $True
        $Script:buttonGalleryFromCanvas.Enabled = $True
        $Script:buttonPartsFromServer.Enabled = $True
        $Script:buttonFileDisplay.Enabled = $True
        $Script:buttonGalleryLocalFileSave.Enabled = $True
        $Script:buttonGalleryLocalFileLoad.Enabled = $True
        $Script:buttonDone.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


function formGallery_Done_Button_Click() 
{

    try {

        # if dgvGalleryFiles has file not yet pushed to server, ask if list should be saved
        # if YES export-csv     name, path, date
        # to dgvGalleryFiles.csv in folder .....\CanvasApp\

        $count = $Script:dgvGalleryFiles.Rows.Count
        $foundIt = $false

        if ($count -gt 1) {
            $myIdx = 0
            do {

                if ($Script:dgvGalleryFiles.Rows[$myIdx].Cells['On Server'].Value -eq "No") {
                    $foundIt = $True
                }
                
                $myIdx = $myIdx + 1
            } until ($myIdx -eq $count -or $foundIt -eq $True)

        }

        if ($foundIt -eq $True) {

            # there are files in the list that are not at the server yet.
            # ask if still want to end out? 

            #hereherehere
            $Msg = 'Some files have not been sent to server.  Still want to leave?'
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery Files','YesNo',32)  

            switch  ($msgBoxInput) {

                'Yes' {
                    
                    # do nothing

                } #switch

                'No' {

                    $Script:formGalleryFiles.DialogResult = 'Retry'
                }
        
            } # end of switch

        }

    }

    catch [Exception] {
            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


function formGallery_Closing ()
{

    try {
        
        #
        # Reset status of main panel
        #
        formGallery_Waiting | Out-Null

        #
        # Recalculate the info for the gallery table on main panel
        #
        reloadGalleryList | Out-Null

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formGalleryFiles_Help () {

    try {
    
        $helpFilePDF = $Script:helpFolder + 'formGalleryFiles.pdf'

        Invoke-Item $helpFilePDF | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}



Function Build_Work_With_Gallery_Dialog () 
{

    try {

	    [System.Windows.Forms.Application]::EnableVisualStyles

	    $Script:formGalleryFiles.SuspendLayout()

	    #
	    # formGallery
        #
        $Script:formGalleryFiles.Controls.Add($Script:labelGalleryName)
        $Script:formGalleryFiles.Controls.Add($Script:labelGalleryNameText)
        $Script:formGalleryFiles.Controls.Add($Script:buttonFileAdd)
        $Script:formGalleryFiles.Controls.Add($Script:buttonFileRemove)
        $Script:formGalleryFiles.Controls.Add($Script:buttonGalleryToServer)
        $Script:formGalleryFiles.Controls.Add($Script:buttonGalleryToCanvas)
        $Script:formGalleryFiles.Controls.Add($Script:buttonGalleryFromCanvas)
        # $Script:formGalleryFiles.Controls.Add($Script:buttonPartsFromServer)
        $Script:formGalleryFiles.Controls.Add($Script:buttonFileDisplay)
        $Script:formGalleryFiles.Controls.Add($Script:buttonGalleryLocalFileSave)
        $Script:formGalleryFiles.Controls.Add($Script:buttonGalleryLocalFileLoad)
        $Script:formGalleryFiles.Controls.Add($Script:buttonDone)
        $Script:formGalleryFiles.Controls.Add($Script:labelGalleryFiles)
        $Script:formGalleryFiles.Controls.Add($Script:labelGalleryFileCount)
        $Script:formGalleryFiles.Controls.Add($Script:dgvGalleryFiles)

        $Script:formGalleryFiles.Location = New-Object System.Drawing.Point(1000,500)
        $Script:formGalleryFiles.StartPosition = 'CenterScreen'
        $Script:formGalleryFiles.WindowState = 'Normal'
        $Script:formGalleryFiles.ClientSize = New-Object System.Drawing.Size($WidthMax,$HeightMax)
        $Script:formGalleryFiles.Name = 'formGallery'
        $Script:formGalleryFiles.Text = $Script:myVersion + ' Work With Gallery Files'
        
        $Script:formGalleryFiles.MaximizeBox = $False
        $Script:formGalleryFiles.MinimizeBox = $False
        $Script:formGalleryFiles.HelpButton = $True
        
        $Script:formGalleryFiles.Add_Load({formGallery_Load})
        $Script:formGalleryFiles.Add_Closing({formGallery_Closing})
        $Script:formGalleryFiles.Add_HelpButtonClicked({formGalleryFiles_Help})

        $buttonHeight = 110

	    #
	    # Gallery name label
	    #
	    $Script:labelGalleryName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25) 
	    $Script:labelGalleryName.Location = New-Object System.Drawing.Point(50,20)
	    $Script:labelGalleryName.Name = 'galleryName'
	    $Script:labelGalleryName.Size = New-Object System.Drawing.Size(200,40)
	    $Script:labelGalleryName.Text = 'Gallery:'

	    #
	    # Gallery name, readable only
	    #
        $Script:labelGalleryNameText.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25) 
        $Script:labelGalleryNameText.Location = New-Object System.Drawing.Point(($Script:labelGalleryName.Right+10),
                                                                                ($Script:labelGalleryName.Top))
	    $Script:labelGalleryNameText.Name = 'txtboxGalleryName'
	    $Script:labelGalleryNameText.Size = New-Object System.Drawing.Size(600,40)
        $Script:labelGalleryNameText.Text = $Script:txtboxNewGalleryName.Text

	    #
	    # buttonFileAdd
	    #
	    $Script:buttonFileAdd.DialogResult = 'None' #'Retry'
        $Script:buttonFileAdd.Location = New-Object System.Drawing.Point(($Script:labelGalleryName.Left),
                                                                         ($Script:labelGalleryName.Bottom+50))
	    $Script:buttonFileAdd.Name = 'buttonFileAdd'
	    $Script:buttonFileAdd.Size = New-Object System.Drawing.Size(350,$buttonHeight)
	    $Script:buttonFileAdd.TabIndex = 1
	    $Script:buttonFileAdd.Text = 'Add File from PC'
        $Script:buttonFileAdd.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonFileAdd.UseVisualStyleBackColor = $True
	    $Script:buttonFileAdd.add_Click({FileAddButton_Click})

        #
        # button to get gallery parts from server
        #
	    # $Script:buttonPartsFromServer.DialogResult = 'None' #'Retry'
	    # $Script:buttonPartsFromServer.Location = New-Object System.Drawing.Point(($Script:buttonFileAdd.Right+20),($Script:buttonFileAdd.Top))
	    # $Script:buttonPartsFromServer.Name = 'PartsFromServer'
	    # $Script:buttonPartsFromServer.Size = New-Object System.Drawing.Size(420,$buttonHeight)
	    # $Script:buttonPartsFromServer.TabIndex = 2
	    # $Script:buttonPartsFromServer.Text = 'List Files at Server'
        # $Script:buttonPartsFromServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    # $Script:buttonPartsFromServer.UseVisualStyleBackColor = $True
	    # $Script:buttonPartsFromServer.add_Click({PartsFromServerButton_Click})

	    #
	    # buttonFileRemove
	    #
	    $Script:buttonFileRemove.DialogResult = 'None' #'Retry'
        $Script:buttonFileRemove.Location = New-Object System.Drawing.Point(($Script:buttonFileAdd.Right+20),
                                                                            ($Script:buttonFileAdd.Top))
	    $Script:buttonFileRemove.Name = 'buttonFileRemove'
        $Script:buttonFileRemove.Size = New-Object System.Drawing.Size(350,$buttonHeight)
	    $Script:buttonFileRemove.TabIndex = 2
	    $Script:buttonFileRemove.Text = 'Remove File from Gallery'
        $Script:buttonFileRemove.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonFileRemove.UseVisualStyleBackColor = $True
	    $Script:buttonFileRemove.add_Click({FileRemoveButton_Click})


        
        #
	    # buttonFileDisplay
	    #
	    $Script:buttonFileDisplay.DialogResult = 'None' #'Retry'
        $Script:buttonFileDisplay.Location = New-Object System.Drawing.Point(($Script:buttonFileRemove.Right+75),
                                                                             ($Script:buttonFileRemove.Top))
	    $Script:buttonFileDisplay.Name = 'DisplayFileImage'
	    $Script:buttonFileDisplay.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonFileDisplay.TabIndex = 3
	    $Script:buttonFileDisplay.Text = 'Display File'
        $Script:buttonFileDisplay.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonFileDisplay.UseVisualStyleBackColor = $True
        $Script:buttonFileDisplay.add_Click({DisplayFileImageButton_Click})



	    #
	    # buttonGalleryToServer
	    #
	    $Script:buttonGalleryToServer.DialogResult = 'None' #'Retry'
        $Script:buttonGalleryToServer.Location = New-Object System.Drawing.Point(($Script:buttonFileDisplay.Right+75),
                                                                                 ($Script:buttonFileDisplay.Top))
	    $Script:buttonGalleryToServer.Name = 'GalleryToServer'
	    $Script:buttonGalleryToServer.Size = New-Object System.Drawing.Size(425,$buttonHeight)
	    $Script:buttonGalleryToServer.TabIndex = 4
	    $Script:buttonGalleryToServer.Text = 'Send All Files to Gallery on Server'
        $Script:buttonGalleryToServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryToServer.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryToServer.add_Click({GalleryToServerButton_Click})

	    #
	    # buttonGalleryToCanvas
	    #
	    $Script:buttonGalleryToCanvas.DialogResult = 'None' #'Retry'
        $Script:buttonGalleryToCanvas.Location = New-Object System.Drawing.Point(($Script:buttonGalleryToServer.Right+75),
                                                                                 ($Script:buttonGalleryToServer.Top))
	    $Script:buttonGalleryToCanvas.Name = 'GalleryToCanvas'
	    $Script:buttonGalleryToCanvas.Size = New-Object System.Drawing.Size(425,$buttonHeight)
	    $Script:buttonGalleryToCanvas.TabIndex = 5
	    $Script:buttonGalleryToCanvas.Text = 'Send Gallery to Canvas'
        $Script:buttonGalleryToCanvas.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryToCanvas.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryToCanvas.add_Click({AddGalleryToCanvasButton_Click})

        #
	    # buttonGalleryFromCanvas
	    #
	    $Script:buttonGalleryFromCanvas.DialogResult = 'None' #'Retry'
        $Script:buttonGalleryFromCanvas.Location = New-Object System.Drawing.Point(($Script:buttonGalleryToCanvas.Right+20),
                                                                                   ($Script:buttonGalleryToCanvas.Top))
	    $Script:buttonGalleryFromCanvas.Name = 'GalleryFromCanvas'
	    $Script:buttonGalleryFromCanvas.Size = New-Object System.Drawing.Size(450,$buttonHeight)
	    $Script:buttonGalleryFromCanvas.TabIndex = 6
	    $Script:buttonGalleryFromCanvas.Text = 'Remove Gallery from Canvas'
        $Script:buttonGalleryFromCanvas.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryFromCanvas.UseVisualStyleBackColor = $True
        $Script:buttonGalleryFromCanvas.add_Click({RemoveGalleryFromCanvasButton_Click})


        #
        #
        #
 	    $Script:buttonGalleryLocalFileSave.DialogResult = 'None'
        $Script:buttonGalleryLocalFileSave.Location = New-Object System.Drawing.Point(($Script:buttonGalleryFromCanvas.Right-350),
                                                                                      ($Script:buttonGalleryFromCanvas.Bottom+50))
	    $Script:buttonGalleryLocalFileSave.Name = 'buttonGalleryLocalFileSave'
	    $Script:buttonGalleryLocalFileSave.Size = New-Object System.Drawing.Size(350,$buttonHeight)
	    $Script:buttonGalleryLocalFileSave.TabIndex = 7
	    $Script:buttonGalleryLocalFileSave.Text = 'Save Names of Files Not On Server'
        $Script:buttonGalleryLocalFileSave.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryLocalFileSave.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryLocalFileSave.add_Click({GalleryLocalFileSaveButton_Click})


        #
        #
        #
        $Script:buttonGalleryLocalFileLoad.DialogResult = 'None'
        $Script:buttonGalleryLocalFileLoad.Location = New-Object System.Drawing.Point(($Script:buttonGalleryLocalFileSave.Left),
                                                                                      ($Script:buttonGalleryLocalFileSave.Bottom+20))
	    $Script:buttonGalleryLocalFileLoad.Name = 'buttonGalleryLocalFileLoad'
	    $Script:buttonGalleryLocalFileLoad.Size = New-Object System.Drawing.Size(350,$buttonHeight)
	    $Script:buttonGalleryLocalFileLoad.TabIndex = 8
	    $Script:buttonGalleryLocalFileLoad.Text = 'Load Local Files Per Saved List'
        $Script:buttonGalleryLocalFileLoad.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonGalleryLocalFileLoad.UseVisualStyleBackColor = $True
	    $Script:buttonGalleryLocalFileLoad.add_Click({GalleryLocalFileLoadButton_Click})

        
	    #
	    # buttonOK
	    #
	    $Script:buttonDone.DialogResult = 'OK'
        $Script:buttonDone.Location = New-Object System.Drawing.Point(($Script:buttonGalleryLocalFileLoad.Right-300),
                                                                      ($Script:buttonGalleryLocalFileLoad.Bottom+50))
	    $Script:buttonDone.Name = 'buttonDone'
	    $Script:buttonDone.Size = New-Object System.Drawing.Size(300,$buttonHeight)
	    $Script:buttonDone.TabIndex = 9
	    $Script:buttonDone.Text = 'Leave'
        $Script:buttonDone.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
	    $Script:buttonDone.UseVisualStyleBackColor = $True
	    $Script:buttonDone.add_Click({formGallery_Done_Button_Click})

        #
        # Label for table of things inside of the gallery
        #
        $Script:labelGalleryFiles.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25, [System.Drawing.FontStyle]::Bold) 
        $Script:labelGalleryFiles.Location = New-Object System.Drawing.Point(50,
                                                                             ($Script:buttonFileAdd.Bottom+40))
	    $Script:labelGalleryFiles.Name = 'labelGalleryFilesList'
	    $Script:labelGalleryFiles.Size = New-Object System.Drawing.Size(350,40)
        $Script:labelGalleryFiles.Text = 'Files in the Gallery'

        #
        # Label for number of files in the dgv
        #
        $Script:labelGalleryFileCount.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10.25, [System.Drawing.FontStyle]::Bold) 
        $Script:labelGalleryFileCount.Location = New-Object System.Drawing.Point(($Script:labelGalleryFiles.Right+10),
                                                                                 ($Script:buttonFileAdd.Bottom+40))
	    $Script:labelGalleryFileCount.Name = 'labelGalleryFileCount'
	    $Script:labelGalleryFileCount.Size = New-Object System.Drawing.Size(400,40)
        $Script:labelGalleryFileCount.Text = ' '



        #
        # Data Grid View
        #
        $Script:dgvGalleryFiles.Location = New-Object System.Drawing.Point(($Script:labelGalleryFiles.Left+30),
                                                                           ($Script:labelGalleryFiles.Bottom+20))
        $Script:dgvGalleryFiles.Size = New-Object System.Drawing.Size(2000,1200)  
        $Script:dgvGalleryFiles.ScrollBars = 'Both'
        $Script:dgvGalleryFiles.ColumnCount = 7
        $Script:dgvGalleryFiles.Visible = $True
        $Script:dgvGalleryFiles.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
        $Script:dgvGalleryFiles.SelectionMode = 'FullRowSelect'
        $Script:dgvGalleryFiles.ColumnHeadersHeightSizeMode = 'AutoSize'
        $Script:dgvGalleryFiles.AutoSizeRowsMode = "DisplayedCells" #"None" #AllCells, None, AllHeaders, DisplayedHeaders, DisplayedCells
        $Script:dgvGalleryFiles.TabIndex = 10

        $Script:dgvGalleryFiles.Add_CellMouseDoubleClick({DisplayFileImageButton_Click})


        $iconCol = New-Object System.Windows.Forms.DataGridViewImageColumn

        $Script:dgvGalleryFiles.Columns[0].Name = "File Name"
        $Script:dgvGalleryFiles.Columns[1].Name = "Type"
        $Script:dgvGalleryFiles.Columns[2].Name = "On Server"
        $Script:dgvGalleryFiles.Columns[3].Name = "Path"
        $Script:dgvGalleryFiles.Columns[4].Name = "Creation Date"   
        $Script:dgvGalleryFiles.Columns.Insert(5,$iconCol)
        $Script:dgvGalleryFiles.Columns[5].Name = "Icon"
        $Script:dgvGalleryFiles.Columns[6].Name = "ID"

        $Script:dgvGalleryFiles.Columns[0].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[1].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[2].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[3].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[4].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[5].SortMode = 'Automatic'
        $Script:dgvGalleryFiles.Columns[6].SortMode = 'Automatic'

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formGalleryFiles.ResumeLayout() | Out-Null

    }

}


#========================================================
# User Files ============================================
#========================================================
Function ServerFileAddButton_Click() {

    #
    # Show Open File dialog
    # User selects files
    # Add files to the array list
    #

    try {

        #
        # Set status
        #
        formFiles_InProcess | Out-Null

        $Script:formFiles.SuspendLayout() | Out-Null


        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = 'C:\Users\Public' 
            Multiselect = $true
        }

                    
        $FileBrowser.ShowDialog() | Out-Null


        $NameList = New-Object System.Collections.ArrayList

        foreach ($FName in $FileBrowser.SafeFileNames) {

            $NameList.Add($FName) | Out-Null

        }


        $FIdx = 0
        foreach ($FName in $FileBrowser.FileNames) 
        {    

            $fileProperty = Get-ItemProperty -Path $FName

            if ($fileProperty.Extension -eq '.jpg' -or $fileProperty.Extension -eq '.jpeg') {

                $filecreateTime = $fileProperty.LastWriteTime

                #
                # figure out path starting at \Public\
                #
                # $startIndex = $fileProperty.DirectoryName.IndexOf('\Public\')
                # if ($startIndex -lt 0) {
                #     $myPath = $fileProperty.DirectoryName
                # }
                # else {
                #     $myPath = $fileProperty.DirectoryName.Substring(($startIndex))
                # }               
                $myPath = $fileProperty.DirectoryName
    
                #
                # Meural ID, Meural image is unknown at this time
                #
                $myID = ""
    
                #
                # Local to PC
                #
                $atServer = "No"
    
                $myGalleryCount = 0
                $myGalleryList = ""
    
                #
                # Populate the next row.
                #    
                $row1 = @($NameList.Item($FIdx), "Image", $atServer, $myPath, 
                          $filecreateTime, $myID, $myGalleryCount, $myGalleryList)
    
                #
                # Put new row in repository for display
                #
                $Script:dgvFiles.Rows.Add($row1) | Out-Null
    
            }
            else {

                $myName = $NameList.Item($FIdx)
                $Msg = "$myName does not have type .jpg or .jpeg"
                [System.Windows.MessageBox]::Show($Msg,'Add a File', 0, 16) | Out-Null

            }

            #
            # Go to next file name in the list
            #
            $Fidx = $Fidx + 1

            $tempNbr = $FileBrowser.FileNames.Count
            $Script:labelFileCount.Text = "$Fidx out of $tempNbr"

        } # foreach

        $tempNbr = $Script:dgvFiles.Rows.Count - 1
        $Script:labelFileCount.Text = "$tempNbr"


        #
        # Resize the columns 
        #
        $Script:dgvFiles.AutoResizeColumn(0) | Out-Null     # File name
        $Script:dgvFiles.AutoResizeColumn(1) | Out-Null     # Type
        $Script:dgvFiles.AutoResizeColumn(2) | Out-Null     # On server flag
        #$Script:dgvFiles.AutoResizeColumn(3) | Out-Null     # Path segment
        $Script:dgvFiles.AutoResizeColumn(4) | Out-Null     # Creation date
        $Script:dgvFiles.AutoResizeColumn(5) | Out-Null     # ID
        $Script:dgvFiles.AutoResizeColumn(6) | Out-Null     # gallery count
        $Script:dgvFiles.AutoResizeColumn(7) | Out-Null     # gallery name list

        
        #
        # Set status
        #
        formFiles_Done | Out-Null
        
        
        #
        # Cleanup
        #
        $FileBrowser.Dispose() | Out-Null
    }


    catch
    {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }


    finally
    {
        $Script:formGalleryFiles.ResumeLayout() | Out-Null
    }


}


Function AddGalleryConnections () {

    try {

        $myIndex = 0
        do {
            if ($Script:galleryBank[$myIndex].ItemCount -gt 0) {
                #
                # Retrieve from server list of all items in gallery
                #
                $authenticationToken = authenticateMe

                $RESPONSE = APIGetGalleryItems $Script:galleryBank[$myIndex].Name $Script:galleryBank[$myIndex].ID `
                                               $Script:galleryBank[$myIndex].ItemCount $authenticationToken


                #
                # for each item in the gallery, find that item the dgvFiles array
                # and increment it's gallery count and name list
                #
                foreach ($responseObj in $RESPONSE.data) {
                    $dgvIndex = 0
                    do {
                        if ($dgvFiles.Rows[$dgvIndex].Cells['ID'].Value -eq $responseObj.ID) {
                            break
                        }

                        $dgvIndex = $dgvIndex + 1

                    } while($dgvIndex -lt $Script:dgvFiles.Rows.Count)

                    if ($dgvIndex -lt $Script:dgvFiles.Rows.Count) {
                        $dgvFiles.Rows[$dgvIndex].Cells['Gallery Count'].Value = $dgvFiles.Rows[$dgvIndex].Cells['Gallery Count'].Value + 1
                        if ($dgvFiles.Rows[$dgvIndex].Cells['Galleries'].Value -eq "") {
                            $dgvFiles.Rows[$dgvIndex].Cells['Galleries'].Value = $Script:galleryBank[$myIndex].Name

                        } else {
                            $dgvFiles.Rows[$dgvIndex].Cells['Galleries'].Value = $dgvFiles.Rows[$dgvIndex].Cells['Galleries'].Value + 
                            ', ' + $Script:galleryBank[$myIndex].Name

                        }

                    }

                } #foreach

            }
            $myIndex = $myIndex + 1

        } while ($myIndex -lt $Script:galleryBank.Count)
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message


    }
    
    finally {

    }

}


Function GetUserFiles () {

    try {

        #
        # For the current user, read whatever parts that are in it at the 
        # server side and populate the datagridview
        #
        
        $authenticationToken = authenticateMe

        $RESPONSE = APIGETUserItems $Script:MaxUserItemCount $authenticationToken

        $fileCount = 0

        foreach ($itemObj in $RESPONSE.data) {

            $myPath = $itemObj.image
            $FName = $itemObj.name
            $filecreateTime = $itemObj.updatedAt
            $myItemID = $itemObj.id

            #
            # Create the icon filename and make sure it does not exist in the working folder
            #           
            if (($myPath.Length -gt 8) -and ($myPath.Substring(0,8) -eq '\Public\')) {

                $fullFileName = "C:\Users" + $myPath + "\" + $FName

                if (!(Test-Path $fullFileName)) {
                    $fullFileName = $Script:defaultIconFolder + $Script:defaultIconFileName
                }
            }

            else {
                $fullFileName = $Script:defaultIconFolder + $Script:defaultIconFileName
            }

            #
            # Coming from netgear server
            #
            $atServer = "Yes" 

            #
            # To be updated later
            #
            $galleryCount = 0
            $galleryNames = ""

            #
            # Populate the next row.
            #  
            $row1 = @($FName, "Image", $atServer, $myPath, $filecreateTime, $myItemID, $galleryCount, $galleryNames)

            #
            # Put new row in repository for display
            #
            $Script:dgvFiles.Rows.Add($row1) | Out-Null

            $fileCount = $fileCount + 1

        } # foreach


        #
        # Resize the columns 
        #
        $Script:dgvFiles.AutoResizeColumn(0) | Out-Null     # File name
        $Script:dgvFiles.AutoResizeColumn(1) | Out-Null     # Type
        $Script:dgvFiles.AutoResizeColumn(2) | Out-Null     # On server flag
        #$Script:dgvFiles.AutoResizeColumn(3) | Out-Null     # Path segment
        $Script:dgvFiles.AutoResizeColumn(4) | Out-Null     # Creation date
        $Script:dgvFiles.AutoResizeColumn(5) | Out-Null     # ID in gallery
        $Script:dgvFiles.AutoResizeColumn(6) | Out-Null     # Number of galleries file is in
        $Script:dgvFiles.AutoResizeColumn(7) | Out-Null     # Names of galleries containing file
       
        $Script:labelFileCount.Text = "$fileCount"

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

}


Function formFiles_Load () {
		
	try {

        GetUserFiles | Out-Null

        AddGalleryConnections | Out-Null

        $Script:dgvFiles.AutoResizeColumn(0) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(1) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(2) | Out-Null
        #$Script:dgvFiles.AutoResizeColumn(3) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(4) | Out-Null   
        $Script:dgvFiles.AutoResizeColumn(5) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(6) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(7) | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }
    
    finally {

    }


}


Function DisplayServerFileImageButton_Click () {

    try {       

        #
        # Loop through rows and display the selected ones
        #

        if ($Script:dgvFiles.SelectedRows.Count -gt 0) {

            foreach ($Row in $Script:dgvFiles.SelectedRows) {

                $onServer = $Script:dgvFiles.Rows[$Row.Index].Cells['On Server'].Value

                if ($onServer -eq "Yes") {

                    $myURL = $Script:dgvFiles.Rows[$Row.Index].Cells['Path'].Value

                    start $myURL

                }

                else {
                    #
                    # File is on PC.
                    #
                    $myName = $Script:dgvFiles.Rows[$Row.Index].Cells['File Name'].Value
                    
                    #
                    # Avoid trying to display the blank row
                    #
                    if ($myName.Length -gt 0) {

                        $myPath = 
                            $Script:dgvFiles.Rows[$Row.Index].Cells['Path'].Value + "\" +
                            $Script:dgvFiles.Rows[$Row.Index].Cells['File Name'].Value

                        Invoke-Item $myPath

                    }

                }

            }

        }

    }

    catch [Exception] {
        
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message

    }

    finally {

    }

}


Function ServerFileDeleteButton_Click() {

    try {

        #
        # Set status
        #
        formFiles_InProcess | Out-Null
        
        $Script:formFiles.SuspendLayout() | Out-Null

        #
        # Loop through rows and remove the selected ones
        #

        if ($Script:dgvFiles.SelectedRows.Count -gt 0) {

            $Msg = 'Remove highlighted files from list and server?'
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'File Removal','YesNo',32) 

            if ($msgBoxInput -eq "Yes") {

                $authenticationToken = authenticateMe

                foreach ($Row in $Script:dgvFiles.SelectedRows) {
    
                    #
                    # If file is on server, remove from that gallery
                    #
                    $onServer = $Script:dgvFiles.Rows[$Row.Index].Cells['On Server'].Value
    
                    if ($onServer -eq "Yes") {
                                   
                        #
                        # Delete the file from server
                        #
    
                        $myItemID = $Script:dgvFiles.Rows[$Row.Index].Cells['ID'].Value
    
                        $RESPONSE = APIDELETEUserItem $myItemID $authenticationToken
                    
                    } #if
    
                    #
                    # Check for Yes and No to screen out that all blank row that sometimes sneaks in
                    #
                    if ($onServer -eq "Yes" -or $onServer -eq "No") {
    
                        #
                        # Take file out of current gallery list
                        #
                        $Script:dgvFiles.Rows.RemoveAt($Row.Index) | Out-Null
                    }
    
                    $fileCount = $Script:dgvFiles.Rows.Count - 1
                    $Script:labelFileCount.Text = "$fileCount"
    
                } #foreach
    
            } #if

        } #if


        #
        # Set status
        #
        formFiles_Done | Out-Null
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formFiles.ResumeLayout() | Out-Null
        $Script:formFiles.Refresh() | Out-Null

    }

}


Function ServerFileUploadButton_Click () {

    try {

        #
        # There will always be at least one row due to blank row 
        #
        if ($Script:dgvFiles.Rows.Count -gt 1) {

            #
            # Set status
            #
            formFiles_InProcess | Out-Null

            $Script:formFiles.SuspendLayout() | Out-Null      
        
            #
            # Subtract 1 for the blank row that is always at the end
            #
            $RowCount = $Script:dgvFiles.Rows.Count - 1

            $RowIndex = 0

            $NumberSent = 0

            $authenticationToken = authenticateMe

            do {

                $atServer = $Script:dgvFiles.Rows[$RowIndex].Cells['On Server'].Value

                if ($atServer -eq "No") {

                    #
                    # Send file to server
                    #
        
                    $myFile = $Script:dgvFiles.Rows[$RowIndex].Cells['Path'].Value + "\" + `
                                $Script:dgvFiles.Rows[$RowIndex].Cells['File Name'].Value

                    $RESPONSE = APIPOSTItemToUser $myFile $authenticationToken
                    #
                    # Update file data since it is now on the server
                    #
                    $Script:dgvFiles.Rows[$RowIndex].Cells['On Server'].Value = "Yes"
                    $Script:dgvFiles.Rows[$RowIndex].Cells['Path'].Value = $RESPONSE.data.image
                    $Script:dgvFiles.Rows[$RowIndex].Cells['ID'].Value = $RESPONSE.data.id

                    $NumberSent = $NumberSent + 1

                } #if

                $RowIndex = $RowIndex + 1

                $Script:labelFileCount.Text = "$NumberSent sent"

            } until($RowIndex -eq $RowCount)

            #
            # Update status
            #
            formFiles_Done | Out-Null

        }
        else {

            #
            # No files to send up is an error
            #
            $Msg = "No files found to send up."
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Gallery to Server', 0, 16)

        }

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)        
        Write-Host $Error.Message
    }

    finally {

    }

}


Function ServerFileDownloadButton_Click()
{

    try {

        #
        # Set status
        #
        formFiles_InProcess | Out-Null

        $Script:formFiles.SuspendLayout() | Out-Null

        #
        # Remove records for files from server
        # Work backwards so that when a row is removed the next index will
        #   be unchanged.
        #
        $count = $Script:dgvFiles.Rows.Count
        if ($count -gt 1) {
            $myIdx = $count - 1
            do {
    
                if ($Script:dgvFiles.Rows[$myIdx].Cells['On Server'].Value -eq "Yes") {
                    $Script:dgvFiles.Rows.RemoveAt($myIdx)
                }
                
                $myIdx = $myIdx - 1
            } until ($myIdx -lt 0)
    
        }

        GetUserFiles | Out-Null

        AddGalleryConnections | Out-Null

        $Script:dgvFiles.AutoResizeColumn(0) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(1) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(2) | Out-Null
        #$Script:dgvFiles.AutoResizeColumn(3) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(4) | Out-Null   
        $Script:dgvFiles.AutoResizeColumn(5) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(6) | Out-Null
        $Script:dgvFiles.AutoResizeColumn(7) | Out-Null

        #
        # Set status
        #
        formFiles_Done | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

        $Script:formFiles.ResumeLayout() | Out-Null

    }


}


Function formFiles_Done () {

    try {

        $Script:formFiles.Text = $Script:myVersion + ' Work With Server Files' + ' DONE !!!!!!!!!!!!!'

        $Script:buttonServerFileAdd.Enabled = $True
        $Script:buttonServerFileDelete.Enabled = $True
        $Script:buttonServerFileUpload.Enabled = $True
        $Script:buttonServerFileDownLoad.Enabled = $True
        $Script:buttonServerFileDisplay.Enabled = $True
        $Script:buttonServerFileSave.Enabled = $True
        $Script:buttonServerFileLoad.Enabled = $True
        $Script:buttonServerFileDone.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formFiles_InProcess () {

    try {

        $Script:formFiles.Text = $Script:myVersion + ' Work With Server Files' + ' In Process !!!!!!!!!!!!!!!!!!!!'

        $Script:buttonServerFileAdd.Enabled = $False
        $Script:buttonServerFileDelete.Enabled = $False
        $Script:buttonServerFileUpload.Enabled = $False
        $Script:buttonServerFileDownLoad.Enabled = $False
        $Script:buttonServerFileDisplay.Enabled = $False
        $Script:buttonServerFileSave.Enabled = $False
        $Script:buttonServerFileLoad.Enabled = $False
        $Script:buttonServerFileDone.Enabled = $False

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formFiles_Waiting () {

    try {

        $Script:formFiles.Text = $Script:myVersion + ' Work With Server Files'

        $Script:buttonServerFileAdd.Enabled = $True
        $Script:buttonServerFileDelete.Enabled = $True
        $Script:buttonServerFileUpload.Enabled = $True
        $Script:buttonServerFileDownLoad.Enabled = $True
        $Script:buttonServerFileDisplay.Enabled = $True
        $Script:buttonServerFileSave.Enabled = $True
        $Script:buttonServerFileLoad.Enabled = $True
        $Script:buttonServerFileDone.Enabled = $True

    }

    catch [Exception] {
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }
}


Function formFiles_Done_Button_Click() {

    try {

        # if dgvFiles has file not yet pushed to server, ask if list should be saved
        # if YES export-csv     name, path, date
        # to dgvFiles.csv in folder .....\CanvasApp\

        $count = $Script:dgvFiles.Rows.Count
        $foundIt = $false

        if ($count -gt 1) {
            $myIdx = 0
            do {
    
                if ($Script:dgvFiles.Rows[$myIdx].Cells['On Server'].Value -eq "No") {
                    $foundIt = $True
                }
                
                $myIdx = $myIdx + 1
            } until ($myIdx -eq $count -or $foundIt -eq $True)
    
        }

        if ($foundIt -eq $True) {

            # there are files in the list that are not at the server yet.
            # ask if still want to end out? 

            $Msg = 'Some files have not been sent to server.  Still want to leave?'
            $msgBoxInput = [System.Windows.MessageBox]::Show($Msg,'Server Files','YesNo',32)  

            switch  ($msgBoxInput) {

                'Yes' {
                    
                    # do nothing

                } #switch

                'No' {

                    $Script:formFiles.DialogResult = 'Retry'
                }
           
            } # end of switch

        }

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formFiles_Closing() {

    try {

        #
        # Closing dialog box ... save data if need be, cleanup
        # Moved to right before dialog is opened
        #
        #$Script:dgvFiles.Rows.Clear() | Out-Null

        #
        # Reset status of form being left
        #
        formFiles_Waiting | Out-Null

        #
        # Recalculate the info for the gallery table
        #
        reloadGalleryList | Out-Null

    }

    catch [Exception] {

            Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
            Write-Host $Error.Message
    }

    finally {

    }

}


Function formFiles_Save_Button_Click () {

    try {

        $count = $Script:dgvFiles.Rows.Count

        if ($count -gt 1) {

            $targetFile = $Script:LocalFileListUserPath + $Script:LocalFileListUserName

            if (Test-Path $targetFile) {
                Remove-Item $targetFile | Out-Null
            }

            $numberFileNamesSaved = 0
            $myIdx = 0

            do {
    
                if ($Script:dgvFiles.Rows[$myIdx].Cells['On Server'].Value -eq "No") {

                    $myName = $Script:dgvFiles.Rows[$myIdx].Cells['File Name'].Value
                    $myPath = $Script:dgvFiles.Rows[$myIdx].Cells['Path'].Value
                    $myQualifiedValue = $myPath + '\' + $myName

                    Add-Content -Path $targetFile -Value $myQualifiedValue

                    $numberFileNamesSaved += 1

                }
                
                $myIdx = $myIdx + 1

            } until ($myIdx -eq $count)
    
            if ($numberFileNamesSaved -eq 0) {
                
                $Msg = 'No local file names found to save.'
                [System.Windows.MessageBox]::Show($Msg,'Save Names of Local Files', 0, 16) | Out-Null

            }

        } else {

            $Msg = 'No local file names found to save.'
            [System.Windows.MessageBox]::Show($Msg,'Save Names of Local Files', 0, 16) | Out-Null

        }
        
    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}



Function formFiles_Load_Button_Click () {

try {

        $targetFile = $Script:LocalFileListUserPath + $Script:LocalFileListUserName

        if ((Test-Path $targetFile) -eq $True) {
    
            $file_data = Get-Content -Path $targetFile

            if ($file_data.count -gt 0) {
    
                $FIdx = 0
    
                foreach ($line in $file_data) {
        
                    $fileProperty = Get-ItemProperty -Path $line
        
                    $myPath = $fileProperty.DirectoryName
                    $myFileName = $fileProperty.Name
                    $filecreateTime = $fileProperty.LastWriteTime
        
                    #
                    # Meural ID, Meural image is unknown at this time
                    #
                    $myID = ""
        
                    #
                    # Local to PC
                    #
                    $atServer = "No"
        
                    $myGalleryCount = 0
                    $myGalleryList = ""
        
                    #
                    # Populate the next row.
                    #    
                    $row1 = @($myFileName, "Image", $atServer, $myPath, 
                              $filecreateTime, $myID, 
                              $myGalleryCount, $myGalleryList)
        
                    #
                    # Put new row in repository for display
                    #
                    $Script:dgvFiles.Rows.Add($row1) | Out-Null
        
                    #
                    # Go to next file name in the list
                    #
                    $Fidx = $Fidx + 1
        
                    $tempNbr = $FileBrowser.FileNames.Count
                    $Script:labelFileCount.Text = "$Fidx out of $tempNbr"   
            
                }
        
                $tempNbr = $Script:dgvFiles.Rows.Count - 1
                $Script:labelFileCount.Text = "$tempNbr"
        
                    
                #
                # Resize the columns 
                #
                $Script:dgvFiles.AutoResizeColumn(0) | Out-Null     # File name
                $Script:dgvFiles.AutoResizeColumn(1) | Out-Null     # Type
                $Script:dgvFiles.AutoResizeColumn(2) | Out-Null     # On server flag
                #$Script:dgvFiles.AutoResizeColumn(3) | Out-Null     # Path segment
                $Script:dgvFiles.AutoResizeColumn(4) | Out-Null     # Creation date
                $Script:dgvFiles.AutoResizeColumn(5) | Out-Null     # ID
                $Script:dgvFiles.AutoResizeColumn(6) | Out-Null     # gallery count
                $Script:dgvFiles.AutoResizeColumn(7) | Out-Null     # gallery name list  
    
            }
            else {
    
                #
                # Nothing to load, Empty file
                #
                $Msg = 'Saved list of files was not found.'
                [System.Windows.MessageBox]::Show($Msg,'Load Local Files From Saved List', 0, 16) | Out-Null
                
            }
    
        }
        else {

            #
            # Nothing to load, File not found
            #
            $Msg = 'Saved list of files was not found.'
            [System.Windows.MessageBox]::Show($Msg,'Load Local Files From Saved List', 0, 16) | Out-Null

        }

      
        #
        # Set status
        #
        formFiles_Done | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}



Function formFiles_Help () {

    try {
    
        $helpFilePDF = $Script:helpFolder + 'formFiles.pdf'

        Invoke-Item $helpFilePDF | Out-Null

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}



Function Build_Server_Files_Dialog () {

    # For working files on the server
    
    try {
    
        [System.Windows.Forms.Application]::EnableVisualStyles
    
        $Script:formFiles.SuspendLayout()
    
        #
        # formGallery
        #
        $Script:formFiles.Controls.Add($Script:buttonServerFileAdd)
        $Script:formFiles.Controls.Add($Script:buttonServerFileDelete)
        $Script:formFiles.Controls.Add($Script:buttonServerFileUpload)
        $Script:formFiles.Controls.Add($Script:buttonServerFileDownLoad)
        $Script:formFiles.Controls.Add($Script:buttonServerFileDisplay)
        $Script:formFiles.Controls.Add($Script:buttonServerFileSave)
        $Script:formFiles.Controls.Add($Script:buttonServerFileLoad)
        $Script:formFiles.Controls.Add($Script:buttonServerFileDone)
        $Script:formFiles.Controls.Add($Script:labelFileList)
        $Script:formFiles.Controls.Add($Script:labelFileCount)
        $Script:formFiles.Controls.Add($Script:dgvFiles)
        $Script:formFiles.Location = New-Object System.Drawing.Point(1000,500)
        $Script:formFiles.StartPosition = 'CenterScreen'
        $Script:formFiles.WindowState = 'Normal'
        $Script:formFiles.ClientSize = New-Object System.Drawing.Size(3375,1600)
        $Script:formFiles.Name = 'formFiles'
        $Script:formFiles.Text = $Script:myVersion + ' Work With Server Files'

        $Script:formFiles.MaximizeBox = $False
        $Script:formFiles.MinimizeBox = $False
        $Script:formFiles.HelpButton = $True
        
        $Script:formFiles.Add_Load({formFiles_Load})
        $Script:formFiles.Add_Closing({formFiles_Closing})
        $Script:formFiles.Add_HelpButtonClicked({formFiles_Help})
    
        $buttonHeight = 110
    
        #
        # buttonServerFileAdd
        #
        $Script:buttonServerFileAdd.DialogResult = 'None'
        $Script:buttonServerFileAdd.Location = New-Object System.Drawing.Point((100),(100))
        $Script:buttonServerFileAdd.Name = 'buttonServerFileAdd'
        $Script:buttonServerFileAdd.Size = New-Object System.Drawing.Size(350,$buttonHeight)
        $Script:buttonServerFileAdd.TabIndex = 1
        $Script:buttonServerFileAdd.Text = 'Add File from PC'
        $Script:buttonServerFileAdd.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileAdd.UseVisualStyleBackColor = $True
        $Script:buttonServerFileAdd.add_Click({ServerFileAddButton_Click})
    
        #
        # buttonServerFileRemove
        #
        $Script:buttonServerFileDelete.DialogResult = 'None' #'Retry'
        $Script:buttonServerFileDelete.Location = New-Object System.Drawing.Point(($Script:buttonServerFileAdd.Right+20),
                                                                                  ($Script:buttonServerFileAdd.Top))
        $Script:buttonServerFileDelete.Name = 'buttonServerFileDelete'
        $Script:buttonServerFileDelete.Size = New-Object System.Drawing.Size(350,$buttonHeight)
        $Script:buttonServerFileDelete.TabIndex = 2
        $Script:buttonServerFileDelete.Text = 'Remove File from List and Server'
        $Script:buttonServerFileDelete.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileDelete.UseVisualStyleBackColor = $True
        $Script:buttonServerFileDelete.add_Click({ServerFileDeleteButton_Click})
    
        #
        # buttonServerFileDisplay
        #
        $Script:buttonServerFileDisplay.DialogResult = 'None' #'Retry'
        $Script:buttonServerFileDisplay.Location = New-Object System.Drawing.Point(($Script:buttonServerFileDelete.Right+100),
                                                                                   ($Script:buttonServerFileDelete.Top))
        $Script:buttonServerFileDisplay.Name = 'DisplayServerFileImage'
        $Script:buttonServerFileDisplay.Size = New-Object System.Drawing.Size(350,$buttonHeight)
        $Script:buttonServerFileDisplay.TabIndex = 3
        $Script:buttonServerFileDisplay.Text = 'Display File'
        $Script:buttonServerFileDisplay.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileDisplay.UseVisualStyleBackColor = $True
        $Script:buttonServerFileDisplay.add_Click({DisplayServerFileImageButton_Click})
    
        #
        # buttonServerFileUpload
        #
        $Script:buttonServerFileUpload.DialogResult = 'None' #'Retry'
        $Script:buttonServerFileUpload.Location = New-Object System.Drawing.Point(($Script:buttonServerFileDisplay.Right+100),
                                                                                  ($Script:buttonServerFileDisplay.Top))
        $Script:buttonServerFileUpload.Name = 'ServerFileUpload'
        $Script:buttonServerFileUpload.Size = New-Object System.Drawing.Size(375,$buttonHeight)
        $Script:buttonServerFileUpload.TabIndex = 4
        $Script:buttonServerFileUpload.Text = 'Send All Files to Server'
        $Script:buttonServerFileUpload.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileUpload.UseVisualStyleBackColor = $True
        $Script:buttonServerFileUpload.add_Click({ServerFileUploadButton_Click})
    
        #
        # buttonServerFileDownload
        #
        $Script:buttonServerFileDownload.DialogResult = 'None' #'Retry'
        $Script:buttonServerFileDownload.Location = New-Object System.Drawing.Point(($Script:buttonServerFileUpload.Right+20),
                                                                                    ($Script:buttonServerFileUpload.Top))
        $Script:buttonServerFileDownload.Name = 'ServerFileDownload'
        $Script:buttonServerFileDownload.Size = New-Object System.Drawing.Size(375,$buttonHeight)
        $Script:buttonServerFileDownload.TabIndex = 5
        $Script:buttonServerFileDownload.Text = 'List Files on Server'
        $Script:buttonServerFileDownload.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileDownload.UseVisualStyleBackColor = $True
        $Script:buttonServerFileDownload.add_Click({ServerFileDownloadButton_Click})
       

        #
        # 
        #
        $Script:buttonServerFileSave.DialogResult = 'None'
        $Script:buttonServerFileSave.Location = New-Object System.Drawing.Point(($Script:buttonServerFileDownLoad.Right+100),
                                                                                ($Script:buttonServerFileDownLoad.Top))
        $Script:buttonServerFileSave.Name = 'buttonServerFileSave'
        $Script:buttonServerFileSave.Size = New-Object System.Drawing.Size(350,$buttonHeight)
        $Script:buttonServerFileSave.TabIndex = 6
        $Script:buttonServerFileSave.Text = 'Save Names of Files Not On Server'
        $Script:buttonServerFileSave.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileSave.UseVisualStyleBackColor = $True
        $Script:buttonServerFileSave.add_Click({formFiles_Save_Button_Click})


        #
        # 
        #
        $Script:buttonServerFileLoad.DialogResult = 'None'
        $Script:buttonServerFileLoad.Location = New-Object System.Drawing.Point(($Script:buttonServerFileSave.Right+25),
                                                                                ($Script:buttonServerFileSave.Top))
        $Script:buttonServerFileLoad.Name = 'buttonServerFileLoad'
        $Script:buttonServerFileLoad.Size = New-Object System.Drawing.Size(350,$buttonHeight)
        $Script:buttonServerFileLoad.TabIndex = 7
        $Script:buttonServerFileLoad.Text = 'Load Local Files Per Saved List'
        $Script:buttonServerFileLoad.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileLoad.UseVisualStyleBackColor = $True
        $Script:buttonServerFileLoad.add_Click({formFiles_Load_Button_Click})


        #
        # buttonServerFileDOne
        #
        $Script:buttonServerFileDone.DialogResult = 'OK'
        $Script:buttonServerFileDone.Location = New-Object System.Drawing.Point(($Script:buttonServerFileLoad.Right+100),
                                                                                ($Script:buttonServerFileLoad.Top))
        $Script:buttonServerFileDone.Name = 'buttonServerFileDone'
        $Script:buttonServerFileDone.Size = New-Object System.Drawing.Size(250,$buttonHeight)
        $Script:buttonServerFileDone.TabIndex = 8
        $Script:buttonServerFileDone.Text = 'Leave'
        $Script:buttonServerFileDone.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:buttonServerFileDone.UseVisualStyleBackColor = $True
        $Script:buttonServerFileDone.add_Click({formFiles_Done_Button_Click})



        #
        #
        #
        $Script:labelFileList.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:labelFileList.ForeColor = [Drawing.Color]::Black
        $Script:labelFileList.Location = New-Object System.Drawing.Point(($Script:buttonServerFileAdd.Left),
                                                                          ($Script:buttonServerFileAdd.Bottom+50))
        $Script:labelFileList.Name = 'fileCount'
        $Script:labelFileList.Size = New-Object System.Drawing.Size(600,50)
        $Script:labelFileList.Text = 'File Count: '
        $Script:labelFileList.Visible = $True


        #
        # $Script:labelFileCount = New-Object 'System.Windows.Forms.Label'
        #
        $Script:labelFileCount.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
        $Script:labelFileCount.ForeColor = [Drawing.Color]::Black
        $Script:labelFileCount.Location = New-Object System.Drawing.Point(($Script:labelFileList.Right+10),
                                                                          ($Script:labelFileList.Top))
        $Script:labelFileCount.Name = 'fileCount'
        $Script:labelFileCount.Size = New-Object System.Drawing.Size(200,50)
        $Script:labelFileCount.Text = ' '
        $Script:labelFileCount.Visible = $True
    
        #
        # Data Grid View
        #
        $Script:dgvFiles.Location = New-Object System.Drawing.Point(($Script:labelFileList.Left),
                                                                    ($Script:labelFileCount.Bottom+30))
        $Script:dgvFiles.Size = New-Object System.Drawing.Size(2750,1200)  
        $Script:dgvFiles.ScrollBars = 'Both'
        $Script:dgvFiles.ColumnCount = 8
        $Script:dgvFiles.Visible = $True
        $Script:dgvFiles.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
        $Script:dgvFiles.SelectionMode = 'FullRowSelect'
        $Script:dgvFiles.ColumnHeadersHeightSizeMode = 'AutoSize'
        $Script:dgvFiles.AutoSizeRowsMode = "DisplayedCells" #"None" #AllCells, None, AllHeaders, DisplayedHeaders, DisplayedCells
        $Script:dgvFiles.TabIndex = 9

        $Script:dgvFiles.Add_CellMouseDoubleClick({DisplayServerFileImageButton_Click})
                                               
        $Script:dgvFiles.Columns[0].Name = "File Name"
        $Script:dgvFiles.Columns[1].Name = "Type"
        $Script:dgvFiles.Columns[2].Name = "On Server"
        $Script:dgvFiles.Columns[3].Name = "Path"
        $Script:dgvFiles.Columns[4].Name = "Creation Date"   
        $Script:dgvFiles.Columns[5].Name = "ID"
        $Script:dgvFiles.Columns[6].Name = "Gallery Count"
        $Script:dgvFiles.Columns[7].Name = "Galleries"
    
        $Script:dgvFiles.Columns[0].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[1].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[2].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[3].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[4].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[5].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[6].SortMode = 'Automatic'
        $Script:dgvFiles.Columns[7].SortMode = 'Automatic'
    
    }
    
    catch [Exception] {
    
        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }
    
    finally {
    
        $Script:formGalleryFiles.ResumeLayout() | Out-Null
    
    }
    
    
    
    
}
    

#========================================================
#========================================================
#
# UNUSED ????
#
Function Form_StateCorrection_Load
{
	#Correct the initial state of the form to prevent the .Net maximized form issue
    $Script:formGalleryFiles.WindowState = $Script:InitialFormWindowState
    
    try {

    }

    catch [Exception] {

        Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
        Write-Host $Error.Message
    }

    finally {

    }

}


#
# MAIN START
#
#
#if ("7" -gt ($PSVersionTable.PSVersion.Major)) {
    if (($PSVersionTable.PSVersion.Major) -lt "7") {    #PS proper would be to put known value on left for comparison (v on right for assignment), but this is a bit more 'human' readable
    Write-host "FrameIt requires PowerShell v7 or higher. The version you are running is not currently supported:" $PSVersionTable.PSVersion
    break
}
MaxDialogSizeTweak

try {

    Build_Work_With_Gallery_Dialog | Out-Null
        
    Build_Define_Galleries_Dialog | Out-Null

    Build_Create_Gallery_Dialog | Out-Null

    Build_Server_Files_Dialog | Out-Null

    Build_Login_Dialog | Out-Null

    #
    # Display the message box to initialize internal Windows settings 
    # that control the GUI look and feel
    #

    #[System.Windows.MessageBox]::Show('Come on in, the gate is open!','Swinging Gate','OK',0) | Out-Null 

    Do {

        $Script:formLogin.ShowDialog() | Out-Null

        if ($Script:formLogin.DialogResult -eq 'OK') {

            $authenticationToken = authenticateMe
            if ($authenticationToken -eq "") {

                $Script:formLogin.DialogResult = 'Retry'        
                $Msg = 'Netgear authentication failed. Check ID and Password.'
                [System.Windows.MessageBox]::Show($Msg,'Login', 0, 16) | Out-Null

            }
        }
    }
    Until ($Script:formLogin.DialogResult -ne 'Retry')

   if ($Script:formLogin.DialogResult -eq 'OK') {

        $authenticationToken = authenticateMe

        $Script:meuralID = APIGetDeviceID $authenticationToken

        $Script:formGalleriesTitle = $Script:formGalleriesTitle + " $Script:emailID"

        $Script:formGalleries.Text = $Script:formGalleriesTitle

        Do {

            $Script:formGalleries.ShowDialog() | Out-Null
        
        }
        Until ($Script:formGalleries.DialogResult -ne "Retry")
    }

}

catch [Exception] {

    Write-Host ("ERROR in: {0} " -f $MyInvocation.MyCommand)
    Write-Host $Error.Message

}

finally {

    #
    # Clean out the folder in which the icon files are stored
    #
    $targetName = $Script:iconFolder+"*"
    Get-ChildItem $targetName | ForEach-Object { Remove-Item -Path $_.FullName }

}    


<#
#
# Garbage collector
#
if (($i % 200) -eq 0)
{
[System.GC]::Collect()
}

#>

