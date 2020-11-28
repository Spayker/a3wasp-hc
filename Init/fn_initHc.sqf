//--- Headless Client initialization...
["INITIALIZATION", "Init_HC.sqf: Running the headless client initialization."] Call WFCO_FNC_LogContent;

//--- We wait for the server full init (just in case!).
while {isNull player} do {
	sleep 5;
	["INITIALIZATION", "Init_HC.sqf: waiting for headclient player is not null"] Call WFCO_FNC_LogContent;
};

sideID = WF_Client_SideJoined Call WFCO_FNC_GetSideID;
WF_Client_SideID = sideID;

Headless_Client_ID  = clientOwner;
Headless_Client_UID = getPlayerUID player;

WF_HC_BasePatrolTeams = [];
WF_HC_DEFENCE_GROUP_EAST = nil;
WF_HC_DEFENCE_GROUP_WEST = nil;


//--- Notify the server that our headless client is here.
[player] remoteExecCall ["WFSE_FNC_addHeadlessClient",2];

0 = [] spawn WFHC_FNC_startGarbageCollector;
0 = [] spawn WFHC_FNC_broadCastFPS;

waitUntil{count towns == totalTowns};

call WFCO_fnc_respawnStartVeh;

0 = [] spawn WFHC_FNC_updateCampsInTown;
["INITIALIZATION", "Init_HC.sqf: camps update script is initialized."] Call WFCO_FNC_LogContent;
0 = [] spawn WFHC_fnc_startTownAiProcessing;
["INITIALIZATION", "Init_HC.sqf: ai town processing script is initialized."] Call WFCO_FNC_LogContent;
