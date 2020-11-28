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

        class DelegateAi {
            file = "wasphc\Delegate";
            class delegateAI {};
            class DelegateHighCommandGroup {};
            class delegateAIStaticDefence {};
            class delegateBasePatrolAI {};
            class delegateTownAI {};
        };
		
        class TownCamps {
            file = "\wasphc\Town";
            class updateCampsInTown {};
            class startTownAiProcessing {};
            class getTownGroups {};
            class getVehicleTownGroups {};
            class getTownActiveGroups {};
            class spawnTownGroups {};
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
	};
};