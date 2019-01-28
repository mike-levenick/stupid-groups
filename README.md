# Stupid Groups
### What it is: 
A learning project by Mike Levenick that can convert Smart Groups in Jamf Pro to either Advanced Searches or Static Groups.
### Why it exists:
Smart Groups are a powerful tool in Jamf Pro, which are designed to be used for active scoping to groups of users or devices whose membership are changing frequently. However, often times customers will have things like compliance reports set up as Smart Groups with nothing scoped to them. These do not need to recalculate constantly, and can be calculated upon view for compliance. Sometimes, smart groups were also set up for things such as iPad carts, whose membership rarely (if ever) change. 

This large number of unnecessary smart groups can have a significant performance impact on a Jamf Pro server, but cleanup and remediation is often frustrating. Stupid Groups is an app designed to "make your apps less smart", by converting them automatically to either a Static Group (if they are used for scoping) or an Advanced Search (if they are used for compliance reporting or similar).
### How to use it:
Launch the app and enter either your Jamf Pro URL if you host your own server, or your Jamf Cloud instance name if you have a Jamf Cloud hosted instance. Then enter a username and password. Stupid Groups will authenticate to your Jamf Pro server and attempt to pull the activation code to verify your credentials.

Once it has successfully authenticated, simply select the record type (Computer, Mobile Device, or User) and select whether you'd like to convert the Smart Group to an Advanced Search or Static Group. Then enter the ID of the Smart Group to convert, and run a Pre-Flight Check. 

The Pre-Flight Check will let you know what is about to happen, and open up the option to convert the group if everything looks good. 
