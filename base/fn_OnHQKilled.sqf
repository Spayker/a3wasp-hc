/*
	Triggered whenever the HQ is killed.
	 Parameters:
		- HQ
		- Shooter
*/
params ["_mhq", "_killer"];
private ["_side", "_hqs", "_teamkill", "_killer_uid", "_logik"];

_side = _mhq getVariable ["wf_side", side _mhq];
//--- Spawn a radio message.
[_side,"Destroyed", ["Base", _mhq]] remoteExecCall ["WFSE_FNC_SideMessage", 2];

_logik = _side call WFCO_FNC_GetSideLogic;
_hqs = _logik getVariable ["wf_hq", []];
_hqs = _hqs - [_mhq];
_hqs = _hqs - [objNull];
_logik setVariable ["wf_hq", _hqs, true];

_teamkill = if (side _killer == _side) then {true} else {false};
_killer_uid = getPlayerUID _killer;

if ((!isNull _killer) && (isPlayer _killer)) then {
    if (_teamkill) then {
    	["BuildingTeamkill", name _killer, _killer_uid, 0] remoteExecCall ["WFCL_FNC_LocalizeMessage", _side];
    	[_killer, score _killer - 300] call WFSE_FNC_RequestChangeScore;
    } else {
        ["HeadHunterReceiveBounty", (name _killer), 15000, 0, _side] remoteExecCall ["WFCL_FNC_LocalizeMessage"];
        [_killer, score _killer + 150] call WFSE_FNC_RequestChangeScore;
    };
};

["INFORMATION", Format["Server_OnHQKilled.sqf : [%1] HQ [%2] has been destroyed by [%3], Teamkill? [%4], Side Teamkill? [%5]",
    _side, typeof _mhq, name _killer, _teamkill, side _killer]] Call WFCO_FNC_LogContent;

//--Insert data to DB--
if (isPlayer _killer) then {
    [_mhq getVariable "wf_structure_type", _side call WFCO_FNC_GetSideID, _killer_uid, name _killer, time] spawn WFSE_FNC_InsertStructureKilled;
};

[_killer, _side] spawn {
	_killer = _this # 0;
	_side = _this # 1;
	if(!isNull _killer) then {
		if(isPlayer _killer) then {
            [format [":fire::fire::fire: %1 :regional_indicator_h::regional_indicator_q: has been destroyed by %2 **%3** :fire::fire::fire:",
                         _side Call WFCO_FNC_GetSideFLAG,
                         (side _killer) Call WFCO_FNC_GetSideFLAG,
                          name _killer
                    ]
            ] Call WFDC_FNC_LogContent;
        };
	};
};