local PLUGIN = nil;
local BUTTONS = {};
local PREPAREDPLAYER = {};
local PLUGINDIR = nil;
local debug = false;

LIP = require 'LIP'
PMLib = require 'PMLib'
ZLib = require 'ZLib'
 
function Initialize(Plugin)
	Plugin:SetName("BungeecordTeleButton")
	Plugin:SetVersion(1)
 
	-- Hooks
  cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_USED_BLOCK, OnPlayerUsedBlock)
  cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnLogin)
  
 
	PLUGIN = Plugin
  PLUGINDIR = Plugin:GetFolderName()
  --if(debug) then LOG(PLUGINDIR) end
  if(cFile:IsFile("Plugins\\" .. PLUGINDIR .. "\\buttons.ini")) then
    BUTTONS = LIP.load("Plugins\\" .. PLUGINDIR .. "\\buttons.ini")
  else
    cFile:Copy("Plugins\\" .. PLUGINDIR .. "/BUTTONS.ini.default","Plugins\\" .. PLUGINDIR .. "/BUTTONS.ini")
  end
	-- Command Bindings
  -- Use the InfoReg shared library to process the Info.lua file:
  dofile("Plugins\\" .. PLUGINDIR .. "\\InfoReg.lua")
  RegisterPluginInfoCommands()
  --RegisterPluginInfoConsoleCommands()
 
  LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
  local online = cRoot:Get():GetServer():GetNumPlayers();
  if(online ~= 0) then
    cRoot:Get():ForEachPlayer(ReadyPlayer)
  end
  return true
end

function ReadyPlayer(Player)
  if not Player then
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
        PREPAREDPLAYER[PlayerName].Ready = false
        Player:SendMessageFailure("Button name in use! You are no longer creating a BungeeButton!");
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
        Player:SendMessageSuccess("Button successfully created!")
        LOG("BungeeButton "..PREPAREDPLAYER[PlayerName].ButtonName.." created at ("..BlockX ..",".. BlockY..","..BlockZ..")")
      end
    elseif(PREPAREDPLAYER[PlayerName].ReadyDelete) then
      local ServerInfo = FindServer(BlockX,BlockY,BlockZ)
      if(Player:HasPermission("bungeebutton.delete.button")) then
        if(ServerInfo.Found) then
          BUTTONS[ServerInfo.ButtonName] = nil
          PREPAREDPLAYER[PlayerName].ReadyDelete = false
          Player:sendMessageInfo("Button " .. ServerInfo.ButtonName .. " has been removed!")
        else
          Player:SendMessageInfo("The clicked button is not a Bungee Button! Use /bungeebuttondel again to stop trying to remove a BungeeButton. Otherwise, use a BungeeButton to remove.");
        end
      end
    else
      --if(debug) then LOG("Checking if button is a server porter") end
      local ServerInfo = FindServer(BlockX,BlockY,BlockZ);
      if ServerInfo.Found then
        if Player:HasPermission(ServerInfo.Permission) then
          Player:GetClientHandle():SendPluginMessage(PMLib:new("BungeeCord"):writeUTF("Connect"):writeUTF(ServerInfo.ServerName):GetOut())
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
      a_Player:SendMessageSuccess("Creation started! Use a button to create!")
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
    Player:SendMessageSuccess("Button " .. a_Split[2] .. " deleted successfully!")
  else
    Player:SendMessageFailure("Use the command like this: /bungeebuttondel OR /bungeebuttondel {Name}");
  end
  return true
end

function BungeeButtonReload(Split,Player)
  BUTTONS = {};
  BUTTONS = LIP.load("Plugins\\" .. PLUGINDIR .. "\\buttons.ini");
  Player:SendMessageSuccess("Config loaded!");
  return true
end

function BungeeButtonSave(Split,Player)
  LIP.save("Plugins\\" .. PLUGINDIR .. "\\buttons.ini",BUTTONS);
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
  LIP.save("Plugins\\" .. PLUGINDIR .. "\\buttons.ini",BUTTONS)
  LOG(PLUGIN:GetName() .. " has finished saving!")
	LOG(PLUGIN:GetName() .. " is shutting down...")
end
