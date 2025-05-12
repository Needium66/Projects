#Spin up a File Server Manaully
#Deploy a Windows Server
#Promote it to a File Server via Role or Feature
#Steps:
#Go to "File Server"
#Go to the "Manage" tab at the top right hand side
#Select "Add Roles and Features"
#Select "Next" from the bottom
#Check the option for "Role-based or faeture-based installation and select "Next"
#Select the server or virtual disk to install the roles and features on
#Select "Next"
#Leave as is(default) for selecting "select one or more role to install on the server"- File & Storage services and Web server (IIS)"
#Expand the "File Server & Storage Services by clicking on it"
#Expand the "iSCSI"
#Select "File Storage"
#Select "File Server Resource Manager"
#Select "Add Features" button at the bottom
#Select "Next"
#Leave as is (default)
#Select "Next"
#Select "Install" button fro the bottom and allow to restart
#Validate the installation from the status symbol at the top
#Select "Close" button at the bottom
#Go to "Tools" button at the top to validate and open up the installations e.g "File Server Resource Manager"
#Go back to "File & Storage Services" from the navigation pane on the left- see the new features added (Shares, iSCSI, Work Folder)
#Select "Shares" to create a share for data to be managed.
#Use File Server Resource Manager to manage the file server
#Next Step:
#Spin up a FIle Server leveraging Terraform