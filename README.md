# CuberitePlugin-BungeeButtons
Button-based Bungeecord Teleportation for the Cuberite MC Server.

## Commands

`/bungeebutton`    
Begins the creation of a BungeeButton    
Permission: bungeebutton.create.button    
Parameters: <Name> <Server> <Permission>    
After running this command, the first button you click that is not already a BungeeButton will become a BungeeButton that teleports the player to <Server> so long as they have <Permission>

`/bungeebuttondel`    
Begins the deletion of a BungeeButton    
Permission: bungeebutton.delete.button    
Parameters: [Name]    
If a name is specified, it will delete the BungeeButton with that name (as defined in the original use of `/bungeebutton`). This name can be found in buttons.ini. If you do not include a name, the next BungeeButton you click will be deleted. You will keep this "Ready To Delete" status until you delete a button, disconnect, or use `/bungeebuttondel` again.

`/bungeebuttonsave`    
Saves button configuration in memory to file. Ran automatically on unload of plugin and shutdown of server.    
Permission: bungeebutton.save    
Parameters: none

`/bungeebuttonload`    
Loads button configuration from file. Ran automatically on load of plugin. THIS WILL DELETE ANY BUNGEEBUTTONS THAT WERE MADE BETWEEN THE LAST USE OF BUNGEEBUTTONSAVE AND NOW!!!    
Permission: bungeebutton.load    
Parameters: none
