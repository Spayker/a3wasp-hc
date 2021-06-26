class DefaultEventhandlers;
class CfgPatches {
    class waspHC {
        units[] = {};
        weapons[] = {};
        requiredAddons[] = {"A3_Data_F","A3_Soft_F","A3_Soft_F_Offroad_01","A3_Characters_F"};
        fileName = "waspHC.pbo";
        author = "WASP CTI Community";
    };
};

class CfgFunctions {
    class WF_Headless_Client {
        tag = "WFHC";

        class HcMain {
            file = "wasphc\Init";
            class initHc {};
            class broadCastFPS {};
        };

        class HcBase {
            file = "wasphc\base";
            class startStaticDefenseProcessing {};
            class stationaryDefense {};
            class BuildingDamaged {};
            class buildingKilled {};
            class createDefenseTemplate {};
            class createObjectsFromArray {};
            class CreateStartupBase {};
            class OnHQKilled {};
            class createBasePatrol {};
            class performStructureSell {};
            class buildingHandleDamage {};
            class startBaseAreaProcessing {};
        };

        class HcBaseAi {
            file = "wasphc\base\ai";
            class aiCommander {};
            class aiComSetWaypoint {};
            class aiBuildHcGroups {};
            class aiCleanUpHcGroups {};
            class aiBaseBuildStructures {};
            class aiRunTacticalFeatures {};
        };

        class HcBaseConstruction {
            file = "wasphc\base\Construction";
            class hQSite {};
            class smallSite {};
            class mediumSite {};
            class mediumSiteObjects {};
            class smallSiteObjects {};
        };

        class DelegateAi {
            file = "wasphc\Delegate";
            class delegateAI {};
            class DelegateHighCommandGroup {};
            class delegateAIStaticDefence {};
            class delegateBasePatrolAI {};
            class delegateTownAI {};
            class createHighCommandGroup {};
		class createTownUnits {};
		class createTeam {};
        };
		
        class Towns {
            file = "\wasphc\Town";
            class startTownProcessing {};
            class startTownAiProcessing {};
            class getTownGroups {};
            class getVehicleTownGroups {};
            class getTownActiveGroups {};
            class spawnTownGroups {};
            class manageTownDefenses {};
            class operateTownDefensesUnits {};
            class spawnTownDefense {};
            class saveTownSurvivedGroups {};
        };

        class DelegateAiEnvironment {
            file = "\wasphc\Environment";
            class startGarbageCollector {};
        };
		
		class OperateTownDefenses {
			file = "wasphc\OperateTownDefenses";
			class RemoveGroup {};
			class RemoveTownAI {};
		};

		class UnitArty {
            file = "wasphc\Unit";
            class fireRemoteArtillery {};
        };

        class ServerTaskDirector {
            file = "wasphc\Task";
            class initTaskDirector {};
        };
		
		class ServerModuleCram {
            file = "wasphc\Cram";
            class initCram {};
        };
	};
};