/*
	Create a delegation request.
	 Parameters:
		- Town
		- Side
		- Groups
		- Spawn positions
		- Teams
*/
params ["_town", "_side", "_groups", "_positions", ["_camp", objNull]];
["INFORMATION", Format["fn_DelegateTownAI.sqf: Received a town delegation request from the server for [%1] [%2].", _side, _town]] Call WFCO_FNC_LogContent;

[_town, _side, _groups, _positions, _camp] spawn WFHC_FNC_CreateTownUnits;
