ffxiv_combat_marauder = inheritsFrom(ml_task)

function ffxiv_combat_marauder:Create()
    local newinst = inheritsFrom(ffxiv_combat_marauder)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_marauder members
    newinst.name = "ARCANIST"
    newinst.targetid = 0
    
    return newinst
end

function ffxiv_combat_marauder:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_marauder:OnSleep()

end

function ffxiv_combat_marauder:OnTerminate()

end

function ffxiv_combat_marauder:IsGoodToAbort()

end
