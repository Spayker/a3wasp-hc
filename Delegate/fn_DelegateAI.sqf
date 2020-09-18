/*
	Create a delegation request.
	 Parameters:
		- Side
		- Groups
		- Spawn positions
		- Teams
*/
params ["_side", "_unitType", "_position", "_team", "_dir", ["_special", "FORM"]];
Private ["_groups", "_positions", "_side", "_teams", "_town_vehicles"];

["INFORMATION", Format["Client_DelegateAI.sqf: Received a delegation request from the server for [%1].", _side]] Call WFCO_FNC_LogContent;


[_side, _unitType, _position, _team, _dir, _special] call WFCO_FNC_CreateUnitsForResBases
