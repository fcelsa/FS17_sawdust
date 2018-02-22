--
-- sawdust
--
-- by fcelsa (Team FSI Modding)
--
-- With this script my goal is to emulate the sawdust, leaves and other residues
-- generated from forestry working; the game way is to generate some quantity
-- of woodchips, depending from type of cut and equipment.
-- Works with chainsaw and all woodharvester, obvious only in the area is ok for
-- heap on the ground; the player can change a bit the amount
-- of woodchips from 1 to 3, also can set the amount to 0.
-- Default multiplier is set to 2 (totalSawdust variable in the code)
-- inputbindings to Z (see moddesc) active when player using chainsaw or
-- when woodhaverster has grabbed a tree after cut.
-- from version 1.1.0 sawdust from stumpCutter e treeSaw
-- ver. 1.1.1 fix error with some treesaw no cutnode vehicle type
-- ver. 1.2.0 fix issue with Seasons Wopstr instrument, code refacotring
-- ver. 1.2.1 fix issue in multiplayer
sawdustEvent = {};
sawdustEvent_mt = Class(sawdustEvent, Event);

InitEventClass(sawdustEvent, "sawdustEvent");

function sawdustEvent:emptyNew()
    local self = Event:new(sawdustEvent_mt);
    return self;
end

function sawdustEvent:new(x, y, z, amountDelta)
    local self = sawdustEvent:emptyNew()
    self.x, self.y, self.z = x, y, z;
    self.amountDelta = amountDelta;
    return self;
end

function sawdustEvent:readStream(streamId, connection)
    self.x = streamReadFloat32(streamId);
    self.y = streamReadFloat32(streamId);
    self.z = streamReadFloat32(streamId);
    self.amountDelta = streamReadFloat32(streamId);
    self:run(connection);
end

function sawdustEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.x);
    streamWriteFloat32(streamId, self.y);
    streamWriteFloat32(streamId, self.z);
    streamWriteFloat32(streamId, self.amountDelta);
end

function sawdustEvent:run(connection)
    if not connection:getIsServer() then
        g_currentMission.sawdustBase:addChipToGround(self.x, self.y, self.z, self.amountDelta);
    end
end
