//--- Headless Client initialization...
["INITIALIZATION", "Init_HC.sqf: Running the headless client initialization."] Call WFCO_FNC_LogContent;

sideID = WF_Client_SideJoined Call WFCO_FNC_GetSideID;
WF_Client_SideID = sideID;

Headless_Client_ID  = clientOwner;
Headless_Client_UID = getPlayerUID player;

WF_HC_BasePatrolTeams = [];
WF_HC_DEFENCE_GROUP_EAST = nil;
WF_HC_DEFENCE_GROUP_WEST = nil;

call WFCO_fnc_respawnStartVeh;
["INITIALIZATION", Format ["Init_HC.sqf: HC respawning start vehicles [%1]", time]] Call WFCO_FNC_LogContent;

//--- Notify the server that our headless client is here.
[player] remoteExecCall ["WFSE_FNC_addHeadlessClient",2];
["INITIALIZATION", "Init_HC.sqf: registering headless client on server."] Call WFCO_FNC_LogContent;

0 = [] spawn WFHC_FNC_startGarbageCollector;
["INITIALIZATION", "Init_HC.sqf: starting garbage collector."] Call WFCO_FNC_LogContent;

0 = [] spawn WFHC_FNC_broadCastFPS;
["INITIALIZATION", "Init_HC.sqf: broadcasting HC fps."] Call WFCO_FNC_LogContent;

//--- We wait for the server full init (just in case!).
sleep 20;

0 = [] spawn WFHC_FNC_updateCampsInTown;
["INITIALIZATION", "Init_HC.sqf: camps update script is initialized."] Call WFCO_FNC_LogContent;

waitUntil {townInit};

0 = [] spawn WFHC_fnc_startTownProcessing;
["INITIALIZATION", "Init_HC.sqf: general town processing script is initialized."] Call WFCO_FNC_LogContent;

0 = [] spawn WFHC_fnc_startTownAiProcessing;
["INITIALIZATION", "Init_HC.sqf: ai town processing script is initialized."] Call WFCO_FNC_LogContent;

//--WASP MODULES: start TaskDirector--
0 = [] spawn WFHC_fnc_initTaskDirector;
["INITIALIZATION", Format ["Init_HC.sqf: HC start TaskDirector at [%1]", time]] Call WFCO_FNC_LogContent;

//--- Stationary defense init
WF_static_defenses = [];
[] spawn WFHC_FNC_startStaticDefenseProcessing;
["INITIALIZATION", Format ["Init_HC.sqf: HC start static defense processing at [%1]", time]] Call WFCO_FNC_LogContent;