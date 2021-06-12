["TASK DIRECTOR", "TaskDirector.sqf: begin work."] Call WFCO_FNC_LogContent;

//--Task Object: integer InUse flag; array TaskData; array task for a Side: [WEST, EAST, RESISTANCE]; integer max total launches count for all sides--
//--Task data: string Name, boolean playerOnAllSides (west and east must include online players), array Timings [min, mid, max] (time range for mission start) --
WF_TD_TASKS = [
    [scriptNull, ["saveTourists", false, [5400, 7200, 8200]], [west, east], 1],
    [scriptNull,["interceptScud", false, [8200, 8800, 9400]], [west, east, resistance], 1]
			];

_directorDoWork = true;
_existsTask = 0;
_lastSide = sideEmpty;

while { _directorDoWork } do {
	{	
		_task = _x;
		_taskData = _task # 1;
		_taskSides = _task # 2;
		_taskAvailableLaunches = _task # 3;
		
		//--Do work with task if it dont started--		
		if(!(missionNameSpace getVariable [format["taskIsRun%1", _taskData # 0], false]) && _taskAvailableLaunches > 0) then {
			_existsTask = _existsTask + 1;
			if(time > random (_taskData # 2)) then {
				_taskSide = selectRandom _taskSides;		
				
				//--Exclude side repeation--		
				while { _taskSide == _lastSide } do {
					_taskSide = selectRandom _taskSides;			
				};				
				
				_lastSide = _taskSide;
				_task set [3, (_task # 3) - 1];
				["TASK DIRECTOR", format["TaskDirector.sqf: task %1 has begun at %2 for side %3", _taskData # 0, time, _taskSide]] Call WFCO_FNC_LogContent;
				if(_taskAvailableLaunches <= 0) then {
					_existsTask = _existsTask - 1;
				};
				_handle = [_taskSide, _taskData # 0] execVM format['wasphc\Task\tasks\%1\initTask.sqf', _taskData # 0];
				missionNameSpace setVariable [format["taskIsRun%1", _taskData # 0], true];
				_task set [0, _handle];
			};
		};
	} forEach WF_TD_TASKS;
	
	if(_existsTask > 0) then { _directorDoWork = true; } else { _directorDoWork = false; };
	
	sleep 10;
};

["TASK DIRECTOR", format["TaskDirector.sqf: No tasks in schedule. TaskDirector has ended work at %1", time]] Call WFCO_FNC_LogContent;