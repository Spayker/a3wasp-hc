Private ["_created","_current","_dir","_i","_object","_origin","_relDir","_relPos","_skip","_template","_toplace","_toWorld"];
_origin = _this select 0;
_template = _this select 1;
_existingTemplate = if (count _this > 2) then {_this select 2} else {[]};

_dir = getDir _origin;
_created = [];
_toplace = objNull;

if(!(isNil '_template'))then{
    for '_i' from 0 to count(_template)-1 do {
    	_current = _template select _i;
    	_object = _current select 0;
    	_relPos = _current select 1;
    	_relDir = _current select 2;

    	_skip = false;
    	if (_i < count(_existingTemplate)) then {
    		if (alive(_existingTemplate select _i)) then {_skip = true;};
    	};

    	if !(_skip) then {
    		_toWorld = _origin modelToWorld _relPos;
    		_toWorld set [2,0];

    		_toplace = createVehicle [_object, _toWorld, [], 0, "NONE"];
    		_toplace setVariable ["wf_defense", true]; //--- This is one of our defenses.
    		_toplace setDir (_dir - _relDir);
    	} else {
    		_toplace = _existingTemplate select _i;
    	};

    	_created pushBack _toplace;
    };
};


_created