﻿-- Map & Meshmanager
mm = { }
mm.navmeshfilepath = GetStartupPath() .. [[\Navigation\]];
mm.mainwindow = { name = strings[gCurrentLanguage].meshManager, x = 350, y = 100, w = 280, h = 250}
mm.meshfiles = {}
mm.currentmapdata = {} 
mm.visible = false
mm.lasttick = 0 
mm.MarkerList = 
{
    ["grindSpot"] = {},
    ["fishingSpot"] = {},
    ["miningSpot"] = {},
    ["botanySpot"] = {},
    ["navSpot"] = {}
}
mm.MarkerRenderList = {}
mm.reloadMeshPensing = false
mm.reloadMeshTmr = 0
mm.reloadMeshName = ""

function mm.ModuleInit() 	
		
	if (Settings.FFXIVMINION.gMeshMGR == nil) then
		Settings.FFXIVMINION.gMeshMGR = "1"
	end
        
	local wnd = GUI_GetWindowInfo("FFXIVMinion")
	GUI_NewWindow(mm.mainwindow.name,wnd.x+wnd.width,wnd.y,mm.mainwindow.w,mm.mainwindow.h)
	GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].activated,"gMeshMGR",strings[gCurrentLanguage].generalSettings)
	GUI_NewComboBox(mm.mainwindow.name,strings[gCurrentLanguage].navmesh ,"gmeshname",strings[gCurrentLanguage].generalSettings,"")
	GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showrealMesh,"gShowRealMesh",strings[gCurrentLanguage].generalSettings)
	GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showPath,"gShowPath",strings[gCurrentLanguage].generalSettings)
	--Grab all meshfiles in our Navigation directory
	local count = 0
	local meshlist = "none"
	local meshfilelist = dirlist(mm.navmeshfilepath,".*obj")
	if ( TableSize(meshfilelist) > 0) then
		local i,meshname = next ( meshfilelist)
		while i and meshname do
			meshname = string.gsub(meshname, ".obj", "")
			table.insert(mm.meshfiles, meshname)
			meshlist = meshlist..","..meshname
			i,meshname = next ( meshfilelist,i)
		end
	end
			
	gShowMesh = "0"
	gShowRealMesh = "0"
	gShowPath = "0"
	gMeshrec = "0"
	if (Settings.FFXIVMINION.gnewmeshname == nil) then
		Settings.FFXIVMINION.gnewmeshname = ""
	end
	GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showMesh,"gShowMesh",strings[gCurrentLanguage].editor)	
	GUI_NewField(mm.mainwindow.name,strings[gCurrentLanguage].newMeshName,"gnewmeshname",strings[gCurrentLanguage].editor)
	GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].newMesh,"newMeshEvent",strings[gCurrentLanguage].editor)
	GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].recmesh,"gMeshrec",strings[gCurrentLanguage].editor)
	GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].saveMesh,"saveMeshEvent",strings[gCurrentLanguage].editor)
	GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].buildNAVMesh,"buildMeshEvent",strings[gCurrentLanguage].editor)
	
	
	RegisterEventHandler("newMeshEvent",mm.CreateNewMesh)	
	RegisterEventHandler("saveMeshEvent",mm.SaveMesh)
	RegisterEventHandler("buildMeshEvent",mm.BuildMesh)


	gmeshname_listitems = meshlist
	gnewmeshname = ""
	gMeshMGR = Settings.FFXIVMINION.gMeshMGR 
    
    
    GUI_NewComboBox(mm.mainwindow.name,strings[gCurrentLanguage].selectedMarker,"gSelectedMarker",strings[gCurrentLanguage].markers,"None")
    GUI_NewField(mm.mainwindow.name,strings[gCurrentLanguage].markerName,"gMarkerName",strings[gCurrentLanguage].markers)
    GUI_NewNumeric(mm.mainwindow.name,strings[gCurrentLanguage].markerLevel,"gMarkerLevel",strings[gCurrentLanguage].markers,"1","50")
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].selectClosestMarker,"selectClosestMarkerEvent",strings[gCurrentLanguage].markers)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].moveToMarker,"moveToMarkerEvent",strings[gCurrentLanguage].markers)
    RegisterEventHandler("selectClosestMarkerEvent", mm.SelectClosestMarker)
    RegisterEventHandler("moveToMarkerEvent", mm.MoveToMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addGrindSpot,"addGrindSpotEvent",strings[gCurrentLanguage].markers)
	RegisterEventHandler("addGrindSpotEvent", mm.AddMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addFishingSpot,"addFishingSpotEvent",strings[gCurrentLanguage].markers)
	RegisterEventHandler("addFishingSpotEvent", mm.AddMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addMiningSpot,"addMiningSpotEvent",strings[gCurrentLanguage].markers)
	RegisterEventHandler("addMiningSpotEvent", mm.AddMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addBotanySpot,"addBotanySpotEvent",strings[gCurrentLanguage].markers)
	RegisterEventHandler("addBotanySpotEvent", mm.AddMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addNavSpot,"addNavSpotEvent",strings[gCurrentLanguage].markers)
	RegisterEventHandler("addNavSpotEvent", mm.AddMarker)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].deleteMarker,"deleteSpotEvent",strings[gCurrentLanguage].markers)
    RegisterEventHandler("deleteSpotEvent", mm.DeleteMarker)
	
	GUI_SizeWindow(mm.mainwindow.name,mm.mainwindow.w,mm.mainwindow.h)
	GUI_WindowVisible(mm.mainwindow.name,false)
end

-------------------------------------------
--Marker Stuff
-------------------------------------------

function mm.UpdateMarkerList()
    -- setup markers
	local markers = "None"
    for tag, posList in pairs(mm.MarkerList) do
        for key, pos in pairs(posList) do
            markers = markers..","..key
        end
	end

	gSelectedMarker_listitems = markers
    
    -- call gathermanager update also
    GatherMgr.UpdateMarkerLists()
end

function mm.GetMarkerInfo(markerName)
    for tag, list in pairs(mm.MarkerList) do
        for key, info in pairs(list) do
            if (key == markerName) then
                return info
            end
        end
	end
    
    return nil
end

function mm.SetMarkerData(markerName, data)
    for tag, list in pairs(mm.MarkerList) do
        for key, info in pairs(list) do
            if (key == markerName) then
                info.data = data
                mm.WriteMarkerList(gmeshname)
                return true
            end
        end
	end
    
    return false
end

function mm.SetMarkerTime(markerName, time)
    for tag, list in pairs(mm.MarkerList) do
        for key, info in pairs(list) do
            if (key == markerName) then
                info.time = time
                mm.WriteMarkerList(gmeshname)
                return true
            end
        end
	end
    
    return false
end

function mm.SelectClosestMarker()
    local closestDistance = 999999999
    local closestMarker = nil
    local closestTag = nil
    for tag, posList in pairs(mm.MarkerList) do
        for key, pos in pairs(posList) do
            local myPos = Player.pos
            local distance = Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
            if (closestMarker == nil or distance < closestDistance) then
                closestMarker = key
                closestDistance = distance
                closestTag = tag
            end
        end
	end
    
    if (closestMarker ~= nil) then
        mm.SelectMarker(closestMarker)
    end
    
    return false
end

function mm.SelectMarker(markerName)
    if (markerName ~= nil and markerName ~= "") then
        gSelectedMarker = markerName
        gMarkerName = markerName
        local info = mm.GetMarkerInfo(markerName)
        gMarkerLevel = tostring(info.level)
        return true
    end
    
    if (markerName == "None") then
        gMarkerName = ""
        gMarkerLevel = ""
    end
    return false
end

function mm.MoveToMarker()
    local info = mm.GetMarkerInfo(gMarkerName)
    if (info ~= nil and info ~= {}) then
        local pos = {x = info.x, y = info.y, z = info.z}
        if (NavigationManager:IsOnMesh(pos.x,pos.y,pos.z)) then
            Player:MoveTo(pos.x,pos.y,pos.z)
        else
            ml_debug("Currently selected marker is not on the currently loaded NavMesh or no mesh is loaded")
        end
    end
end

function mm.AddMarker(arg)
    local markerType = ""
    if (arg == "addGrindSpotEvent") then
        markerType = "grindSpot"
    elseif (arg == "addFishingSpotEvent") then
        markerType = "fishingSpot"
    elseif (arg == "addMiningSpotEvent") then
        markerType = "miningSpot"
    elseif (arg == "addBotanySpotEvent") then
        markerType = "botanySpot"
    elseif (arg == "addNavSpotEvent") then
        markerType = "navSpot"
    end
    
    if(Player.onmesh) then
        if (gMarkerName ~= "") then
            local p = Player.pos
            local newInfo = { x=string.format("%.2f", p.x), y=string.format("%.2f", p.y), z=string.format("%.2f", p.z), h=string.format("%.3f", p.h), level=tostring(gMarkerLevel), data="", time="0" }
            local key = gMarkerName
            local found = false
            
            -- enforce unique marker names
            for tag, list in pairs(mm.MarkerList) do
                for name, info in pairs(list) do
                    if (key == name) then
                        found = true
                        if (tag == markerType) then
                            info = newInfo
                            if (mm.MarkerRenderList[key]) then
                                RenderManager:RemoveObject(mm.MarkerRenderList[key])
                            end
                            mm.MarkerRenderList[key] = mm.DrawMarker( p, markerType )
						else
                            ml_debug("This marker name cannot be used as it conflicts with another marker of a different type")
                        end
                    end
                end
            end
            
            if (not found) then
                local list = mm.MarkerList[markerType]
                
                -- First time we are creating this marker, so we create a new object to be drawn here
                if ( list[key] == nil )	then
                    d(key)
                    mm.MarkerRenderList[key] = mm.DrawMarker( p, markerType )
                end
                list[key] = newInfo
            end
        else
            ml_debug("Must provide a name for marker")
        end
	else
        ml_debug("Current player position is not on NavMesh...cannot create marker")
    end
    	
	
    mm.WriteMarkerList(gmeshname)
    mm.UpdateMarkerList()
end

function mm.DeleteMarker()
    -- since marker names are unique we can simply delete this marker wherever it exists
    for tag, posList in pairs(mm.MarkerList) do
        if (postList[gMarkerName] ~= nil) then
            posList[gMarkerName] = nil
            mm.WriteMarkerList(gmeshname)
            mm.UpdateMarkerList()
            return true
        end
	end
   
    return false
end

function mm.ReadMarkerList(meshname)
    -- clear old lists for previous mesh
    for tag, list in pairs(mm.MarkerList) do
        mm.MarkerList[tag] = {}
    end
    
    -- helper functions located in ml_utility.lua
    local lines = fileread(mm.navmeshfilepath..gmeshname..".info")
    if ( TableSize(lines) > 0) then
        for i, line in pairs(lines) do
            local mark = string.find(line, "=")
            if (mark ~= nil) then
                local tag = line:sub(0,mark-1)
                local keyStart = mark+1
                mark = string.find(line, ":")
                if (mark ~= nil) then
                    local key = line:sub(keyStart,mark-1)
                    local infoTable = {}
                    for info in StringSplit(line:sub(mark+1),",") do
                        table.insert(infoTable, info)
                    end
                    if (infoTable ~= {}) then
                        if ( tag == "MapID" ) then
                            mm.MarkerList["MapID"] = tonumber(infoTable[1])
                        else
                            local list = mm.MarkerList[tag]
                            -- Remove old Marker
                            if (mm.MarkerRenderList[key]) then
                                RenderManager:RemoveObject(mm.MarkerRenderList[key])
                            end
                            -- Draw this Marker
                            mm.MarkerRenderList[key] = mm.DrawMarker( {x=tonumber(infoTable[1]),y=tonumber(infoTable[2]),z=tonumber(infoTable[3])}, tag )
                            
                            list[key] = {x=tonumber(infoTable[1]),y=tonumber(infoTable[2]),z=tonumber(infoTable[3]),h=tonumber(infoTable[4]),level=tonumber(infoTable[5]),data=tostring(infoTable[6]),time=tonumber(infoTable[7])}						
                        end
                    end
                end
            end
        end
    else
        ml_debug("NO INFO FILE FOR THAT MESH EXISTS")
    end
	
	-- Update the markerlist regardless so we clear the gather marker info in the gathermanager
	mm.UpdateMarkerList()
end

function mm.WriteMarkerList(meshname)
    
	if ( meshname ~= "" and meshname ~= nil ) then
        ml_debug("Generating .info file..")
        local string2write = ""
		-- Save the mapID first
		string2write = string2write.."MapID="..Player.localmapid.."\n"	
		for tag, posList in pairs(mm.MarkerList) do  
			if ( tag ~= "MapID") then
				for key, pos in pairs(posList) do
					--d(tag)
					string2write = string2write..tag.."="..key..":"..pos.x..","..pos.y..","..pos.z..","..pos.h..","..pos.level..","..pos.data..","..pos.time.."\n"				
				end
			end
        end
        filewrite(mm.navmeshfilepath..meshname..".info",string2write)
    else
		d("ERROR: No Meshname!")
	end
end

function mm.GetClosestMarkerPos(startPos, tag)
    destPos = nil
    destDistance = 9999999
    if (TableSize(mm.MarkerList[tostring(tag)]) > 0) then
        for i, pos in pairs(mm.MarkerList[tostring(tag)]) do
            local distance = Distance3D(startPos.x, startPos.y, startPos.z, pos.x, pos.y, pos.z)
            if ( distance < destDistance and distance > 2) then
                destPos = pos
                destDistance = distance
            end
        end
    end    
    return destPos
end

---------
--Mesh
---------


function mm.CreateNewMesh()
	d("Creating NEW MESH")
	-- Unload old Mesh
	if (NavigationManager:GetNavMeshName() ~= "") then
		d("Unloading ".. NavigationManager:GetNavMeshName() .." NavMesh.")
		d("Result: "..tostring(NavigationManager:UnloadNavMesh()))		
	end
	
	if ( gnewmeshname ~= nil and gnewmeshname ~= "" ) then
		-- Make sure file doesnt exist
		local found = false		
		local meshfilelist = dirlist(mm.navmeshfilepath,".*obj")
		if ( TableSize(meshfilelist) > 0) then
			local i,meshname = next ( meshfilelist)
			while i and meshname do
				meshname = string.gsub(meshname, ".obj", "")
				if (meshname == gnewmeshname) then
					d("Mesh with that Name exists already...")
					found = true
					break
				end
				i,meshname = next ( meshfilelist,i)
			end
		end
		if (not found) then
			-- Setup everything for new mesh
			gmeshname_listitems = gmeshname_listitems..","..gnewmeshname
			gmeshname = gnewmeshname
			mm.SaveMesh()
			mm.ChangeNavMesh(gmeshname)
		end
	else
		d("Enter a new MeshName first!")
	end
end

function mm.SaveMesh()
	d("Saving NavMesh...")
	if (gmeshname ~= nil and gmeshname ~= "" and gmeshname ~= "none") then
		d("Result: "..tostring(NavigationManager:SaveNavMesh(gmeshname)))
		mm.reloadMeshPensing = true
		mm.reloadMeshTmr = mm.lasttick
		mm.reloadMeshName = gmeshname
	else
		d("gmeshname is empty!?")
	end	
end

function mm.BuildMesh()
	d("Building NAV-Meshfile...")
	if (gmeshname ~= nil and gmeshname ~= "" and gmeshname ~= "none") then
		mm.reloadMeshPensing = true
		mm.reloadMeshTmr = mm.lasttick
		mm.reloadMeshName = gmeshname
	else
		d("gmeshname is empty!?")
	end
end

function mm.ChangeNavMesh(newmesh)			
	-- Set the new mesh for the local map	
	if ( NavigationManager:GetNavMeshName() ~= newmesh and NavigationManager:GetNavMeshName() ~= "") then
		d("Unloading current Navmesh: "..tostring(NavigationManager:UnloadNavMesh()))		
		for key,e in pairs(mm.MarkerRenderList) do	
			if ( key ~= nil ) then
				RenderManager:RemoveObject(mm.MarkerRenderList[key])
				mm.MarkerRenderList[key] = nil
			end
		end
		mm.reloadMeshPensing = true
		mm.reloadMeshTmr = mm.lasttick
		mm.reloadMeshName = newmesh
		return
	else
		-- Load the mesh for our Map
		if (gmeshname ~= nil and gmeshname ~= "" and gmeshname ~= "none") then				
			d("Loading Navmesh " ..gmeshname)
			if (not NavigationManager:LoadNavMesh(mm.navmeshfilepath..gmeshname)) then
				d("Error loading Navmesh: "..path)
            else
                mm.ReadMarkerList(gmeshname)
				mm.reloadMeshPensing = false
            end
		end
	end
	gmeshname = newmesh	
	gMeshMGR = "1"
end


function mm.ToggleMenu()
	if (mm.visible) then
		GUI_WindowVisible(mm.mainwindow.name,false)	
		mm.visible = false
	else
		local wnd = GUI_GetWindowInfo("FFXIVMinion")	
		GUI_MoveWindow( mm.mainwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(mm.mainwindow.name,true)	
		mm.visible = true
	end
end


function mm.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do		
		if ( k == "gmeshname") then
			mm.ChangeNavMesh(v)
            mm.ReadMarkerList(v)
		elseif( k == "gShowRealMesh") then
			if (v == "1") then
				NavigationManager:ShowNavMesh(true)
			else
				NavigationManager:ShowNavMesh(false)
			end
		elseif( k == "gShowPath") then
			if (v == "1") then
				NavigationManager:ShowNavPath(true)
			else
				NavigationManager:ShowNavPath(false)
			end			
		elseif( k == "gShowMesh") then
			if (v == "1") then
				MeshManager:ShowTriMesh(true)
			else
				MeshManager:ShowTriMesh(false)
			end				
		elseif( k == "gMeshrec") then
			if (v == "1") then
				MeshManager:Record(true)
			else
				MeshManager:Record(false)
			end
        elseif( k == "gSelectedMarker") then
            mm.SelectMarker(v)
		elseif( k == "gMeshMGR" or k == "gnewmeshname" ) then
			Settings.FFXIVMINION[tostring(k)] = v    
        end
	end
	GUI_RefreshWindow(mm.mainwindow.name)
end

function mm.OnUpdate( event, tickcount )
	if ( tickcount - mm.lasttick > 500 ) then
		mm.lasttick = tickcount
				
		-- 162 = Left CTRL
		if ( MeshManager:IsKeyPressed(162) ) then
			MeshManager:RecForce(true)
		else
			MeshManager:RecForce(false)
		end
		-- 160 = Left Shift
		if ( MeshManager:IsKeyPressed(160) ) then
			MeshManager:RecSize(14)
		else
			MeshManager:RecSize(8)
		end
		
		-- (re-)Loading Navmesh
		if (mm.reloadMeshPensing and mm.lasttick - mm.reloadMeshTmr > 2000 and mm.reloadMeshName ~= "") then
			mm.reloadMeshTmr = mm.lasttick
			mm.ChangeNavMesh(mm.reloadMeshName)
		end		
	end
end


function mm.DrawMarker( pos, markertype )
	local color = 0
	local s = 1 -- size
	local h = 5 -- height
	if ( markertype == "grindSpot" ) then
		color = 1 -- red
	elseif ( markertype == "fishingSpot" ) then
		color = 4 --blue
	elseif ( markertype == "miningSpot" ) then
		color = 7 -- yellow	
	elseif ( markertype == "botanySpot" ) then
		color = 8 -- orange
	elseif ( markertype == "navSpot" ) then
		color = 6 -- green
	end
	--Building the vertices for the object
	local t = { 
		[1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
		[2] = { pos.x+s, pos.y+s+h, pos.z-s, color  },	
		[3] = { pos.x,   pos.y-s+h,   pos.z, color  },
		
		[4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
		[5] = { pos.x+s, pos.y+s+h, pos.z+s, color  },	
		[6] = { pos.x,   pos.y-s+h,   pos.z, color  },
		
		[7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
		[8] = { pos.x-s, pos.y+s+h, pos.z+s, color  },	
		[9] = { pos.x,   pos.y-s+h,   pos.z, color  },
		
		[10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
		[11] = { pos.x-s, pos.y+s+h, pos.z-s, color  },	
		[12] = { pos.x,   pos.y-s+h,   pos.z, color  },
	}
	
	return RenderManager:AddObject(t)
end

RegisterEventHandler("ToggleMeshmgr", mm.ToggleMenu)
RegisterEventHandler("GUI.Update",mm.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",mm.ModuleInit)
RegisterEventHandler("Gameloop.Update",mm.OnUpdate)

