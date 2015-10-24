PLUGIN = nil;
BUTTONS = {};
PREPAREDPLAYER = {};
local LIP = require 'LIP';
PLUGINDIR = nil;
debug = false;
 
function Initialize(Plugin)
	Plugin:SetName("BungeecordTeleButton")
	Plugin:SetVersion(1)
 
	-- Hooks
  cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_USED_BLOCK, OnPlayerUsedBlock)
  cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnLogin)
 
 
	PLUGIN = Plugin
  PLUGINDIR = cPluginManager:GetPluginsPath()
  --if(debug) then LOG(PLUGINDIR) end
  BUTTONS = LIP.load(PLUGINDIR .. "/BungeeButtons/buttons.ini")
	-- Command Bindings
  -- Use the InfoReg shared library to process the Info.lua file:
  dofile(PLUGINDIR .. "/InfoReg.lua")
  RegisterPluginInfoCommands()
  --RegisterPluginInfoConsoleCommands()
 
  LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
  local online = cRoot:Get():GetServer():GetNumPlayers();
  if(online ~= 0) then
    cRoot:Get():ForEachPlayer(ReadyPlayer)
  end
  return true
end

function StringLenToASCII(Player,a_String)
  --if(debug) then LOG("Converting String to ASCII") end
  local StringLen = tostring(string.len(a_String));
  local t = {
    ["1"] = "\0\1",
    ["2"] = "\0\2",
    ["3"] = "\0\3",
    ["4"] = "\0\4",
    ["5"] = "\0\5",
    ["6"] = "\0\6",
    ["7"] = "\0\7",
    ["8"] = "\0\8",
    ["9"] = "\0\9",
    ["10"] = "\0\10",
    ["11"] = "\0\11",
    ["12"] = "\0\12",
    ["13"] = "\0\13",
    ["14"] = "\0\14",
    ["15"] = "\0\15",
    ["16"] = "\0\16",
    ["17"] = "\0\17",
    ["18"] = "\0\18",
    ["19"] = "\0\19",
    ["20"] = "\0\20",
    ["21"] = "\0\21",
    ["22"] = "\0\22",
    ["23"] = "\0\23",
    ["24"] = "\0\24",
    ["25"] = "\0\25",
    ["26"] = "\0\26",
    ["27"] = "\0\27",
    ["28"] = "\0\28",
    ["29"] = "\0\29",
    ["30"] = "\0\30",
  }
  if(t[StringLen] == Nil) then
    LOG("The server name is incompatible with this plugin! Please make sure it is 30 characters or less!");
    Player:SendMessageFailure("The server name is incompatible with this plugin! Please make sure it is 30 characters or less!");
    return false
  else
    return t[StringLen]
  end
end

function ReadyPlayer(Player)
  if(Player == Nil) then
    return true
  end
  local PlayerName = Player:GetName();
  PREPAREDPLAYER[PlayerName]={};
  PREPAREDPLAYER[PlayerName].Ready = false;
  PREPAREDPLAYER[PlayerName].ReadyDelete = false;
end

function OnLogin(Player)
  --if(debug) then LOG(Player:GetName() .. "Logged In!") end
  ReadyPlayer(Player);
end
 
function FindServer(BlockX,BlockY,BlockZ)
  --if(debug) then LOG("Searching for Server!") end
  local ButtonNumber = #BUTTONS;
  --if(debug) then LOG(ButtonNumber) end
  local ServerName = "";
  for Key, Value in pairs(BUTTONS) do
    if(Value.X == BlockX and Value.Y == BlockY and Value.Z == BlockZ) then
      --if(debug) then LOG("Server Found!") end
      return {["ButtonName"] = Value.Name, ["ServerName"] = Value.Server, ["Permission"] = Value.Permission, ["Found"] = true,}
    end
  end
  --if(debug) then LOG("Server not found :(") end
  return {["Found"] = false,}
end
 
function CheckIfButtonNameTaken(ButtonName)
  --if(debug) then LOG("Checking button names...") end
  local ButtonNumber = #BUTTONS;
  --if(debug) then LOG(ButtonNumber) end
  for Key,Value in pairs(BUTTONS) do
    --if(debug) then LOG(Key, Value) end
    if(tostring(ButtonName) == Value.Name) then
      --if(debug) then LOG("Uh oh I found one!") end
      return true
    end
  end
  --if(debug) then LOG("None found!") end
  return false
end
 
function OnPlayerUsedBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType, BlockMeta)
  local PlayerName = Player:GetName();
  --if(debug) then LOG(type(BlockX)) end
  --if(debug) then LOG(PlayerName .. " used block" .. BlockType .. "!") end
  if(BlockType == 77 or BlockType == 143) then
    --if(debug) then LOG(PlayerName .. "used a button!") end
    if(PREPAREDPLAYER[PlayerName].Ready) then
      if(CheckIfButtonNameTaken(PREPAREDPLAYER[PlayerName].ButtonName)) then
        --if(debug) then LOG(PlayerName .. ", how did you fuck this one up?") end
        Player:SendMessageFailure("Button name in use!");
      else
        --if(debug) then LOG("Making new button entry..") end
        BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName] = {
          ["Name"] = PREPAREDPLAYER[PlayerName].ButtonName,
          ["X"] = BlockX,
          ["Y"] = BlockY,
          ["Z"] = BlockZ,
          ["Server"] = PREPAREDPLAYER[PlayerName].Server,
          ["Permission"] = PREPAREDPLAYER[PlayerName].Permission,
        }
        --if(debug) then LOG(BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].Name .. " " .. BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].X .. " " .. BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].Y .. " " .. BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].Z .. " " .. BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].Server .. " " .. BUTTONS[PREPAREDPLAYER[PlayerName].ButtonName].Permission) end
        PREPAREDPLAYER[PlayerName].Ready = false
      end
    elseif(PREPAREDPLAYER[PlayerName].ReadyDelete) then
      local ServerInfo = FindServer(BlockX,BlockY,BlockZ);
      if(Player:HasPermission("bungeebutton.delete.button")) then
        if(ServerInfo.Found) then
          BUTTONS[ServerInfo.ButtonName] = nil;
          PREPAREDPLAYER[PlayerName].ReadyDelete = false;
        else
          Player:SendMessageInfo("The clicked button is not a Bungee Button! Use /bungeebuttondel again to stop trying to remove a BungeeButton. Otherwise, use a BungeeButton to remove.");
        end
      end
    else
      --if(debug) then LOG("Checking if button is a server porter") end
      local ServerInfo = FindServer(BlockX,BlockY,BlockZ);
      if(ServerInfo.Found) then
        if(Player:HasPermission(ServerInfo.Permission)) then
          --Bungeecord Teleport Thingy Here, ServerInfo.ServerName, PlayerName
          Player:GetClientHandle():SendPluginMessage("BungeeCord", "\0\7Connect" .. StringLenToASCII(Player,ServerInfo.ServerName) .. ServerInfo.ServerName);
        else
          Player:SendMessageFailure("You do not have permission to use this button!");
        end
      else
        return false
      end
    end
  end
  --if(debug) then LOG("Different Block") end
end
 
function BungeeButton(a_Split,a_Player)
  --if(debug) then LOG("Command started with " .. a_Split[2] .. " " .. a_Split[3] .. " " .. a_Split[4]) end
  local PlayerName = a_Player:GetName();
  if(#a_Split == 4) then
    if(CheckIfButtonNameTaken(a_Split[2])) then
      a_Player:SendMessageFailure("Button name in use!");
      return true
    else
      PREPAREDPLAYER[PlayerName].ButtonName = a_Split[2];
      PREPAREDPLAYER[PlayerName].Server = a_Split[3];
      PREPAREDPLAYER[PlayerName].Permission = a_Split[4];
      PREPAREDPLAYER[PlayerName].Ready = true;
      --if(debug) then LOG(tostring(PREPAREDPLAYER[PlayerName].ButtonName) .. " " .. tostring(PREPAREDPLAYER[PlayerName].Server) .. " " .. tostring(PREPAREDPLAYER[PlayerName].Permission) .. " " .. tostring(PREPAREDPLAYER[PlayerName].Ready)) end
    end
  else
    a_Player:SendMessageFailure("Use the command like this: /bungeebutton {Name} {Server} {Permission}");
  end
  return true
end

function BungeeButtonDel(a_Split,Player)
  local PlayerName = Player:GetName();
  if(#a_Split == 1) then
    PREPAREDPLAYER[PlayerName].ReadyDelete = true;
  elseif(#a_Split == 2) then
    BUTTONS[a_Split[2]] = nil;
  else
    a_Player:SendMessageFailure("Use the command like this: /bungeebuttondel OR /bungeebuttondel {Name}");
  end
  return true
end

function BungeeButtonReload(Split,Player)
  BUTTONS = {};
  BUTTONS = LIP.load(PLUGINDIR .. "/BungeeButtons/buttons.ini");
  Player:SendMessageSuccess("Config loaded!");
  return true
end

function BungeeButtonSave(Split,Player)
  BUTTONS = {};
  LIP.save(PLUGINDIR .. "/BungeeButtons/buttons.ini",BUTTONS);
  Player:SendMessageSuccess("Buttons saved!");
  return true
end
 
function OnDisable()
  LOG(PLUGIN:GetName() .. " is saving buttons...")
--[[
  local IniFile = cIniFile();
  IniFile:Clear();
  for Key, Value in pairs(BUTTONS) do
    IniFile:AddKeyName(Value.Name);
    IniFile:AddValue(Key.Name,"Name",Value.Name);
    IniFile:AddValueF(Key.X,"X",Value.X);
    IniFile:AddValueF(Key.Y,"Y",Value.Y);
    IniFile:AddValueF(Key.Z,"Z",Value.Z);
    IniFile:AddValue(Key.Server,"Server",Value.Server);
    IniFile:AddValue(Key.Permission,"Permission",Value.Permission);
  end
  IniFile:WriteFile(PLUGIN:GetLocalFolder() .. "/buttons.ini");
--]]
  LIP.save(PLUGINDIR .. "/BungeeButtons/buttons.ini",BUTTONS)
  LOG(PLUGIN:GetName() .. " has finished saving!")
	LOG(PLUGIN:GetName() .. " is shutting down...")
end
