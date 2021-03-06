ml_global_information = {}
--ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.lastrun = 0
ml_global_information.MainWindow = { Name = "FFXIVMinion", x=50, y=50 , width=400, height=600 }
ml_global_information.BtnStart = { Name=strings[gCurrentLanguage].startStop,Event = "GUI_REQUEST_RUN_TOGGLE" }
ml_global_information.BtnPulse = { Name=strings[gCurrentLanguage].doPulse,Event = "Debug.Pulse" }
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 4
ml_global_information.TaskUIInit = false
FFXIVMINION = {}
FFXIVMINION.SKILLS = {}

function ml_global_information.OnUpdate( event, tickcount )
	ml_global_information.Now = tickcount
		
	gFFXIVMiniondeltaT = tostring(tickcount - ml_global_information.lastrun)
	if (tickcount - ml_global_information.lastrun > tonumber(gFFXIVMINIONPulseTime)) then
		if (not ml_global_information.TaskUIInit) then
			-- load task UIs
			for i, task in pairs(ffxivminion.modes) do
				task.UIInit()
			end
			ml_global_information.TaskUIInit = true
		end
		ml_global_information.lastrun = tickcount
		if( ml_task_hub.CurrentTask() ~= nil) then
			gFFXIVMINIONTask = ml_task_hub:CurrentTask().name
		end
		if(ml_task_hub.shouldRun) then
			ffxivminion.CheckMode()
			ffxivminion.CheckClass()
		end
		
		if (not ml_task_hub:Update() and ml_task_hub.shouldRun) then
			ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
		end
	end
end

ffxivminion = {}

ffxivminion.modes = 
{
	["Grind"] 	= ffxiv_task_grind, 
	["Fish"] 	= ffxiv_task_fish,
	["Gather"] 	= ffxiv_task_gather,
	["Assist"]	= ffxiv_task_assist
}

-- Module Event Handler
function ffxivminion.HandleInit()	
	GUI_SetStatusBar("Initalizing ffxiv Module...")
	
	if (Settings.FFXIVMINION.version == nil ) then
		Settings.FFXIVMINION.version = 1.0
		Settings.FFXIVMINION.gEnableLog = "0"
	end
	if ( Settings.FFXIVMINION.gFFXIVMINIONPulseTime == nil ) then
		Settings.FFXIVMINION.gFFXIVMINIONPulseTime = "150"
	end
	if ( Settings.FFXIVMINION.gEnableLog == nil ) then
		Settings.FFXIVMINION.gEnableLog = "0"
	end
	if ( Settings.FFXIVMINION.gBotMode == nil ) then
		Settings.FFXIVMINION.gBotMode = "None"
	end
	
	GUI_NewWindow(ml_global_information.MainWindow.Name,ml_global_information.MainWindow.x,ml_global_information.MainWindow.y,ml_global_information.MainWindow.width,ml_global_information.MainWindow.height)
	GUI_NewButton(ml_global_information.MainWindow.Name, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botMode,"gBotMode",strings[gCurrentLanguage].settings,"None")
	GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pulseTime,"gFFXIVMINIONPulseTime",strings[gCurrentLanguage].botStatus );	
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].enableLog,"gEnableLog",strings[gCurrentLanguage].botStatus );
	GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].task,"gFFXIVMINIONTask",strings[gCurrentLanguage].botStatus );	
	GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].skillManager, "SkillManager.toggle")
	GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].meshManager, "ToggleMeshmgr")
	
	
	GUI_SizeWindow(ml_global_information.MainWindow.Name,250,300)
	
	gFFXIVMINIONTask = ""
	
	GUI_FoldGroup(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botStatus );
	
	gEnableLog = Settings.FFXIVMINION.gEnableLog
	gFFXIVMINIONPulseTime = Settings.FFXIVMINION.gFFXIVMINIONPulseTime
	
	-- setup bot mode
	local botModes = "None"
	if ( TableSize(ffxivminion.modes) > 0) then
		local i,entry = next ( ffxivminion.modes)
		while i and entry do
			botModes = botModes..","..i
			i,entry = next ( ffxivminion.modes,i)
		end
	end

	gBotMode_listitems = botModes
	gBotMode = Settings.FFXIVMINION.gBotMode
	ffxivminion.SetMode(gBotMode)
	
	ml_debug("GUI Setup done")
	GUI_SetStatusBar("Ready...")
end

function ffxivminion.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( 	k == "gEnableLog" or 
				k == "gFFXIVMINIONPulseTime" or
				k == "gBotMode" )
		then
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxivminion.SetMode(mode)
	ml_global_information.Reset()

	local task = ffxivminion.modes[mode]
	if (task ~= nil) then
		ml_task_hub:Add(task:Create(), LONG_TERM_GOAL, TP_ASAP)
	end
end

function ffxivminion.CheckClass()
	local classes = 
	{
		[FFXIV.JOBS.ARCANIST] 		= ffxiv_combat_arcanist,
		[FFXIV.JOBS.ARCHER]			= ffxiv_combat_archer,
		[FFXIV.JOBS.CONJURER]		= ffxiv_combat_conjurer,
		[FFXIV.JOBS.GLADIATOR] 		= ffxiv_combat_gladiator,
		[FFXIV.JOBS.LANCER]			= ffxiv_combat_lancer,
		[FFXIV.JOBS.MARAUDER] 		= ffxiv_combat_marauder,
		[FFXIV.JOBS.PUGILIST] 		= ffxiv_combat_pugilist,
		[FFXIV.JOBS.THAUMATURGE] 	= ffxiv_combat_thaumaturge,
		[FFXIV.JOBS.BOTANIST] 		= ffxiv_gather_botanist,
		[FFXIV.JOBS.FISHER] 		= ffxiv_gather_fisher,
		[FFXIV.JOBS.MINER] 			= ffxiv_gather_miner
	}
	
	--TODO check which class we are currently using and modify globals appropriately
	if (ml_global_information.CurrentClass == nil or ml_global_information.CurrentClassID ~= Player.job) then
		ml_global_information.CurrentClass = classes[Player.job]
		ml_global_information.CurrentClassID = Player.job
		ml_global_information.AttackRange = ml_global_information.CurrentClass.range
	end
end

function ffxivminion.CheckMode()
	local task = ffxivminion.modes[gBotMode]
	if (task ~= nil) then
		if (not ml_task_hub:CheckForTask(task)) then
			ffxivminion.SetMode(gBotMode)
		end
	elseif (gBotMode == "None") then
		ml_task_hub:ClearQueues()
	end
end

function ml_global_information.Reset()
    --TODO: Figure out what state needs to be reset and add calls here
    
	ml_task_hub:ClearQueues()
	
	--wt_core_state_combat.StopCM()
	--wt_core_taskmanager.ClearTasks()
	--ml_global_information.CurrentMarkerList = nil
	--ml_global_information.SelectedMarker = nil
	--ml_global_information.AttackRange = 1200
	--ml_global_information.MaxLootDistance = 4000
	--ml_global_information.lastrun = 0
	--ml_global_information.InventoryFull = 0
	--wt_core_state_combat.target = 0
	--ml_global_information.FocusTarget = nil
	--gMapswitch = 0	
	
	--NavigationManager:SetTargetMapID(0)
	--wt_core_controller.requestStateChange(wt_core_state_idle)
end

function ml_global_information.Stop()
    --TODO: Do anything here for bot stopping
    
	if (Player:IsMoving()) then
		Player:Stop()
	end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("GUI.Update",ffxivminion.GUIVarUpdate)
