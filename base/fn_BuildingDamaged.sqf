params ["_unit"];
private ["_side"];

if(!(_unit getVariable ["wf_hitnoticing", false]) && alive _unit) then {
	_unit setVariable ["wf_hitnoticing", true];

	if(time - (_unit getVariable ["wf_lastnotice", 0]) > 15) then {
	    _side = _unit getVariable ["wf_side", sideUnknown];
		[_side, "IsUnderAttack", ["Base", _unit]] remoteExecCall ["WFSE_FNC_SideMessage", 2];

        [format [":sos: Structure %1**%2** is **UNDER ATTACK** :sos:", _side call WFCO_FNC_GetSideFLAG,
            _unit getVariable "wf_structure_type"]] call WFDC_FNC_LogContent;

		_unit setVariable ["wf_lastnotice", time];
	};

	_unit setVariable ["wf_hitnoticing", false];
};