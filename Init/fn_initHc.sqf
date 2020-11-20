//--- Headless Client initialization...
["INITIALIZATION", "Init_HC.sqf: Running the headless client initialization."] Call WFCO_FNC_LogContent;

sideID = WF_Client_SideJoined Call WFCO_FNC_GetSideID;
WF_Client_SideID = sideID;

Headless_Client_ID  = clientOwner;
Headless_Client_UID = getPlayerUID player;

WF_HC_BasePatrolTeams = [];
WF_HC_DEFENCE_GROUP_EAST = nil;
WF_HC_DEFENCE_GROUP_WEST = nil;

//--- We wait for the server full init (just in case!).
sleep 3;

//--- Notify the server that our headless client is here.
[player] remoteExecCall ["WFSE_FNC_addHeadlessClient",2];

0 = [] spawn WFHC_FNC_startGarbageCollector;
0 = [] spawn WFHC_FNC_broadCastFPS;