--[["Welcome, Moon-and-Star ?"
MWSE: legally grab all of Dura Gra-Bol's[1] stuff after she's dead, and take
    possession of her house.
Copyright (C) 2024 Bryce Carson

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.

SPDX license information
========================================
GNU General Public License v3.0 or later
GPL-3.0-or-later
========================================

[1] See https://en.uesp.net/wiki/Morrowind:Dura_gra-Bol
]]
---[[ Borrowed from the MWSE tes3.inventory.items example.
--- This is a generic iterator function that is used
--- to loop over all the items in an inventory
---@param ref tes3reference
---@return fun(): tes3item, integer, tes3itemData|nil
local function iterItems(ref)
    local function iterator()
        for _, stack in pairs(ref.object.inventory) do
            ---@cast stack tes3itemStack
            local item = stack.object

            -- Account for restocking items,
            -- since their count is negative
            local count = math.abs(stack.count)

            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    if data then
                        -- Note that data.count is always 1 for items in inventories.
                        -- That field is only relevant for items in the game world, which
                        -- are stored as references. In that case tes3itemData.count field
                        -- contains the amount of items in the in-game-world stack of items.
                        coroutine.yield(item, data.count, data)
                        count = count - data.count
                    end
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

--[[
for item, count, itemData in iterItems(tes3.player) do
    debug.log(item)
    debug.log(count)
    debug.log(itemData)
end
---]]


local cellIds = {
    ["Balmora -2, -2"] = true,
    ["Balmora -3, -2"] = true,
    ["Balmora -3, -3"] = true,
    ["Balmora -4, -2"] = true,
    ["Balmora, Dura gra-Bol's House"] = true
}

local DuraGrabol = nil

local removeGrabolOwnershipFn = function(e)
    local iterator = e.cell:iterateReferences({ tes3.objectType.container, tes3.objectType.npc })
    for ref in iterator() do
        for item in iterItems(ref) do
            --[[ item.stolenList: a list of actors that the object has been stolen from. ]]
            if tes3.hasOwnershipAccess({ reference = ref, target = DuraGrabol }) then
                tes3.setOwner({ reference = ref, owner = tes3.player })
            end
        end
    end
end

--[[ The function removeGrabolOwnwershipFn should only run in one of the
appropriate cells when Dura Gra-Bol is dead. If she is alive her property must
not be modified. For now, the player must enter Dura Gra-bol's house at least
once to test if she's alive. ]]
local cellChangedFilterFn = function(e)
    if not cellIds[e.cell.id] then
        return false
    else
        local iterator = e.cell:iterateReferences({ tes3.objectType.container, tes3.objectType.npc })
        for ref in iterator() do
            if ref.objectType == tes3.objectType.npc and ref.id == "dura gra-bol" then
                DuraGrabol = ref
            end
        end
        if DuraGrabol then
            return DuraGrabol.isDead
        else
            return false
        end
    end
end

for id in cellIds do
    event.register(
        tes3.event.cellChanged,
        removeGrabolOwnershipFn,
        {
        doOnce = true,
        filter = cellChangedFilterFn
        }
    )
end
