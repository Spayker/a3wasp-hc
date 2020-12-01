params ["_town", ["_groupsToSave", []], ["_groupsVehToSave", []]];

["INFORMATION", format ["fn_saveTownSurvivedGroups.sqf: Groups to save in town [%1]: %2", _town, _groupsToSave]] call WFCO_FNC_LogContent;
["INFORMATION", format ["fn_saveTownSurvivedGroups.sqf: Vehicles to save in town [%1]: %2", _town, _groupsVehToSave]] call WFCO_FNC_LogContent;

_town setVariable ['wf_saved_inf_town_teams', _groupsToSave];
_town setVariable ['wf_saved_veh_town_teams', _groupsVehToSave];