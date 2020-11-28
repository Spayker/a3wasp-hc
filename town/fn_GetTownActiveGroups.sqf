//------------------fn_GetTownActiveGroups-------------------------------------------------//
//	Return groups and vehicles of town, which saved in town namespace on server side 	   //
//------------------fn_GetTownActiveGroups-------------------------------------------------//
params ["_scope", "_varName", "_params"];
private ["_town", "_teams", "_vehicles"];

_town = _params # 0;

_teams = _town getVariable ["wf_town_teams", []];
_vehicles = _town getVariable ["wf_active_vehicles", []];
_vehicles = _vehicles - [objNull];
_town setVariable ["wf_active_vehicles", _vehicles];

_scope setVariable [_varName, [_teams, _vehicles], owner _scope];

[_teams, _vehicles]