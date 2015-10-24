g_PluginInfo =
{
	Name = "Bungeecord Button Teleportation",
	Date = "2015-10-20",
	Description = "This plugin allows you to make buttons that move players between servers on a Bungeecord network",
	AdditionalInfo = {
    Title = "Command",
    Contents = "Usage",
  },
	Commands = {
    ["/bungeebutton"] = {
      HelpString = "Begins the creation of a Bungeecord Button",
      Permission = "bungeebutton.create.button",
      Handler = BungeeButton,
      Aliases = "/bb",
      ParameterCombinations = {
        {
          Params = "Name Server Permission",
          Help = "Create a new Bungee Button with {Name} that moves player to {Server} requiring {Permission}"
        },
      },
    },
    ["/bungeebuttondel"] = {
      HelpString = "Begins the deletion of a Bungeecord Button",
      Permission = "bungeebutton.delete.button",
      Handler = BungeeButtonDel,
      Aliases = "/bbdel",
      ParameterCombinations = {
        {
          Params = "",
          Help = "After running this command, click on a button to remove it's teleport! Run this command again to turn this functionallity off."
        },
        {
          Params = "Name",
          Help = "Delete the BungeeButton with {Name}"
        },
      },
    },
    ["/bungeebuttonreload"] = {
      HelpString = "Reloads memory with buttons.ini settings",
      Permission = "bungeebutton.reload",
      Handler = BungeeButtonReload,
      Aliases = "/bbreload",
      ParameterCombinations = {},
    },
    ["/bungeebuttonsave"] = {
      HelpString = "Saves memory to buttons.ini (will save changes in the case of a server crash)",
      Permission = "bungeebutton.save",
      Handler = BungeeButtonSave,
      Aliases = "/bbsave",
      ParameterCombinations = {},
    },
  },
  ConsoleCommands = {},
	Permissions = {
    ["bungeebutton.create.button"] = {
      Description = "Lets player make a Bungee Button with the /bungeebutton command!",
      RecommendedGroups = "admins",
    },
  },
}
