# MeuralUI
Working prototype Windows UI for Meural Canvas

Depends on the unofficial Meural Canvas API.  
    Not a supported interface soooooo .... user beware!

Based on Powershell 7.0.2

Near the top of the FrameIt.ps1 file are 2 variables for the ID and password
used to access the target Netgear Meural user account.  Set these to the 
prefered values.  

    OR
    
Leave them asis and enter the correct ID and password values at the 
prompt that will happen.


Installation:

    Place in the folder of your choice:
        FrameIt.ps1             PowerShell script
        FrameIt                 Shortcut
        Default_IconPhoto.JPG   
        Help folder
        Icon folder
        
    Modify the Shortcut to point to this folder.
    
    Copy the Shortcut to the desktop or where ever you like



To execute:

    Run the PowerShell script which should happen by clicking the shortcut.

    The very first dialog that pops up is a hack.  Without this the other dialogs 
    will not show correctly unless running under ISE. Must bring in/set some attribute 
    that I have yet to figure out.



FUTURE todos for some day in the future, not in any particular order:

    Make User ID and password handling more secure.
    Break FrameIt.ps1 into smaller parts.
    Improve look of dialogs.
    Remove need for that very first poppup message: figure out what underlying
        .NET assembly or whatever is brought in by the poppup and include that
        in the Powershell source part.
    Optimize performance.
        Upload of photos could possibly be threaded.
        Dialog management could possibly be improved to reduce flicker.
    Consider a different technology for UI ... web browser based perhaps.
    Consider a technology other than Powershell script ... 
        Might be faster
        What about portability
    
    Create background task (batch job for us oldsters) that monitors a
    container (folder, other ideas?). When photo is placed in container
    that photo is automagically sent to Canvas.
        Some, but not all, details to consider
            Gallery management
            
            
            
            
 Notes:
 
 Function Resize-Image was created by   Author: Patrick Lambert - http://dendory.net
