params ["_site", "_units", "_position", "_side", "_WF_Logic"];
private ["_group", "_sideID", "_created"];

_created 	= 0;

_group = createGroup [_side, true];
WF_HC_BasePatrolTeams pushBack _group;

{
	if (alive _site) then {
		if (_x isKindOf 'Man') then {
			_sideID = (_side) Call WFCO_FNC_GetSideID;
			_soldier = [_x,_group,_position,_sideID] Call WFCO_FNC_CreateUnit;
			_created = _created + 1;
		};
	};
} forEach _units;

if (_created > 0) then {
	_built = _WF_Logic getVariable Format ["%1UnitsCreated",str _side];
	_built = _built + 1;
	_WF_Logic setVariable [Format["%1UnitsCreated",str _side],_built,true];
	[str _side,'UnitsCreated',_built] Call WFCO_FNC_UpdateStatistics;
	[_group,_site,missionNamespace getVariable "WF_C_AI_PATROL_RANGE"] Spawn WFSE_FNC_AIPatrol;
};