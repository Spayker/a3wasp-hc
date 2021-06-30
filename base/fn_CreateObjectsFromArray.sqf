/*
	Author: Joris-Jan van 't Land

	Description:
	Takes an array of data about a dynamic object template and creates the objects.

	Parameter(s):
	_this select 0: position of the template - Array [X, Y, Z]
	_this select 1: azimuth of the template in degrees - Number 
	_this select 2: objects for the template - Array / composition class - String / tag list - Array
	_this select 3: (optional) randomizer value (how much chance each object has of being created. 0.0 is 100% chance) - Number

	Returns:
	Created objects (Array)
*/

//Validate parameter count
if ((count _this) < 3) exitWith {debugLog "Log: [objectMapper] Function requires at least 3 parameters!"; []};

params ["_pos", "_azi", "_objs", ["_rdm", 0]];

//Validate parameters
if !(_pos isEqualType []) exitWith {debugLog "Log: [objectMapper] Template position (0) must be an Array!"; []};
if !(_azi isEqualType 0) exitWith {debugLog "Log: [objectMapper] Template azimuth (1) must be a Number!"; []};
if !(_objs isEqualType "" || _objs isEqualType []) exitWith {debugLog "Log: [objectMapper] Template objects (2) must be a String or Array!"; []};
if !(_rdm isEqualType 0) exitWith {debugLog "Log: [objectMapper] Randomizer value (3) must be a Number!"; []};
if ((_rdm < 0.0) || (_rdm > 1.0)) exitWith {debugLog "Log: [objectMapper] Randomizer value (3) must be a Number between 0.0 and 1.0!"; []};

private ["_newObjs"];

//See if an object array, specific composition class or tag array was given.
private ["_cfgObjectComps", "_script"];
_cfgObjectComps = configFile >> "CfgObjectCompositions";

if (_objs isEqualType "") then {
	//Composition class was given.
	_script = getText(_cfgObjectComps >> _objs >> "objectScript");
	_objs = [];
} 
else {
	private ["_testSample"];
	_testSample = _objs # 0;
	if !(_testSample isEqualType []) then {
		//Tag list was given.
		private ["_queryTags"];
		_queryTags = +_objs;
		_objs = [];
		
		//Make a list of candidates which match all given tags.
		private ["_candidates"];
		_candidates = [];
		
		for "_i" from 0 to ((count _cfgObjectComps) - 1) do 
		{
			private ["_candidate", "_candidateTags"];
			_candidate = _cfgObjectComps # _i;
			_candidateTags = getArray(_candidate >> "tags");
			
			//Are all tags in this candidate?
			if (({_x in _candidateTags} count _queryTags) == (count _queryTags)) then 
			{
				_candidates pushBack (getText(_candidate >> "objectScript"));
			};
		};
		
		//Select a random candidate.
		_script = _candidates # (floor (random (count _candidates)));
	};
};

//If the object array is in a script, call it.
if (!isNil "_script") then 
{
	_objs = call (compile (preprocessFileLineNumbers _script));
};

//Make sure there are definitions in the final object array.
if ((count _objs) == 0) exitWith {debugLog "Log: [objectMapper] No elements in the object composition array!"; []};

_newObjs = [];

private ["_posX", "_posY"];
_posX = _pos # 0;
_posY = _pos # 1;

//Function to multiply a [2, 2] matrix by a [2, 1] matrix.
private ["_multiplyMatrixFunc"];
_multiplyMatrixFunc =
{
	private ["_array1", "_array2", "_result"];
	_array1 = _this # 0;
	_array2 = _this # 1;

	_result =
	[
		(((_array1 # 0) # 0) * (_array2 # 0)) + (((_array1 # 0) # 1) * (_array2 # 1)),
		(((_array1 # 1) # 0) * (_array2 # 0)) + (((_array1 # 1) # 1) * (_array2 # 1))
	];

	_result
};

for "_i" from 0 to ((count _objs) - 1) do
{
	//Check randomizer for each object.
	if ((random 1) > _rdm) then 
	{
		private ["_obj", "_type", "_relPos", "_azimuth", "_fuel", "_damage", "_newObj"];
		_obj = _objs # _i;
		_type = _obj # 0;
		_relPos = _obj # 1;
		_azimuth = _obj # 2;
		
		//Optionally map fuel and damage for backwards compatibility.
		if ((count _obj) > 3) then {_fuel = _obj # 3};
		if ((count _obj) > 4) then {_damage = _obj # 4};
	
		//Rotate the relative position using a rotation matrix.
		private ["_rotMatrix", "_newRelPos", "_newPos"];
		_rotMatrix =
		[
			[cos _azi, sin _azi],
			[-(sin _azi), cos _azi]
		];
		_newRelPos = [_rotMatrix, _relPos] call _multiplyMatrixFunc;
	
		//Backwards compatability causes for height to be optional.
		private ["_z"];
		if ((count _relPos) > 2) then {_z = _relPos # 2} else {_z = 0};
	
		_newPos = [_posX + (_newRelPos # 0), _posY + (_newRelPos # 1), _z];
	
		//Create the object and make sure it's in the correct location.
		_newObj = _type createVehicle _newPos;
		_newObj setDir (_azi + _azimuth);
		
		//If fuel and damage were grabbed, map them.
		if (!isNil "_fuel") then {_newObj setFuel _fuel};
		if (!isNil "_damage") then {_newObj setDamage _damage};
	
		_newObjs pushBack _newObj;
	};
};

_newObjs