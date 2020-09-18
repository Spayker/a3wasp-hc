params ["_nearby"];
private ["_group"];

if !(_nearby) then {
	{
		_group = _x;
		{
			deleteVehicle _x;
		} forEach (units _x);

		deleteGroup _group;
		
	} forEach WF_HC_BasePatrolTeams;
};

WF_HC_BasePatrolTeams = WF_HC_BasePatrolTeams - [objNull];