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
-- ver. 1.2.2 fix dedicated server issue

sawdust = {};

sawdust.totalSawdust = 2;
sawdust.woodHarvesterCounter = 0;
sawdust.treeSawCounter = 0;
sawdust.stumpCutterCounter = 0;
sawdust.chainsawCounter = 0;
sawdust.showHelp = false;

AmountTypes = {};
AmountTypes.WOODHARVESTER_CUT = 0;
AmountTypes.TREESAW_CUT = 1;
AmountTypes.STUPCUTTER_CUT = 2;
AmountTypes.CHAINSAW_DELIMB = 3;
AmountTypes.CHAINSAW_CUT = 4;
AmountTypes.CHAINSAW_CUTDOWN = 5;

function sawdust:loadMap(name)
    g_currentMission.sawdustBase = self;
end

function sawdust:deleteMap()
end

function sawdust:mouseEvent(posX, posY, isDown, isUp, button)
end

function sawdust:keyEvent(unicode, sym, modifier, isDown)
end

function sawdust:update(dt)
    if g_currentMission.paused then
        return;
    end
    
    self.showHelp = false;

    if g_currentMission.controlledVehicle ~= nil then
        if g_currentMission.controlledVehicle.cutNode ~= nil then
            self:processWoodHarvester();
        end
        if #g_currentMission.controlledVehicle.attachedImplements > 0 then
            for _, cutimplement in pairs(g_currentMission.controlledVehicle.attachedImplements) do
                if cutimplement.object ~= nil then
                    if cutimplement.object.stumpCutterCutNode ~= nil then
                        self:processStumpCutter(cutimplement.object);
                    elseif cutimplement.object.treeSaw ~= nil then
                        self:processTreeSaw(cutimplement.object);
                    end
                end
            end
        end
    end
    
    if g_currentMission.player and g_currentMission.player.currentTool and g_currentMission.player.usesChainsaw then
        self:processChainsaw();
    end
    
    if self.showHelp then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SWD_LEVEL"), InputBinding.SWD_LEVEL);
        if InputBinding.hasEvent(InputBinding.SWD_LEVEL) then
            if self.totalSawdust == 0 then
                self.totalSawdust = 3;
            elseif self.totalSawdust == 3 then
                self.totalSawdust = 2;
            elseif self.totalSawdust == 2 then
                self.totalSawdust = 1;
            elseif self.totalSawdust == 1 then
                self.totalSawdust = 0;
            end
        end
        g_currentMission:addExtraPrintText(g_i18n:getText("SW_DESCLEVEL") .. " " .. tostring(self.totalSawdust));
    end
end

function sawdust:updateTick(dt)
end

function sawdust:readStream(streamId, connection)
end

function sawdust:writeStream(streamId, connection)
end

function sawdust:readUpdateStream(streamId, timestamp, connection)
end

function sawdust:writeUpdateStream(streamId, connection, dirtyMask)
end

function sawdust:draw()
end

function sawdust:processWoodHarvester()
    self.showHelp = true;
    if g_currentMission.controlledVehicle.hasAttachedSplitShape then
        if g_currentMission.controlledVehicle.cutTimer > 1 then
            self.woodHarvesterCounter = self.woodHarvesterCounter + (1 * self.totalSawdust);
        end
        if g_currentMission.controlledVehicle.isAttachedSplitShapeMoving then
            self.woodHarvesterCounter = self.woodHarvesterCounter + (math.random(2, 4) * self.totalSawdust);
        end
    end
    if self.woodHarvesterCounter > 220 then
        local x, y, z = getWorldTranslation(g_currentMission.controlledVehicle.cutNode);
        self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.WOODHARVESTER_CUT));
        self.woodHarvesterCounter = 0;
    end
end

function sawdust:processTreeSaw(object)
    self.showHelp = true;
    local workingToolNode = object.treeSaw.cutNode;
    if workingToolNode ~= nil then -- workaround per i coglioni che usano i treesaw senza un cutnode
        if object.treeSaw.isCutting then
            self.treeSawCounter = self.treeSawCounter + (1 * self.totalSawdust);
        end
        if self.treeSawCounter > 150 then
            local x, y, z = getWorldTranslation(workingToolNode);
            self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.TREESAW_CUT));
            self.treeSawCounter = 0;
        end
    end
end

function sawdust:processStumpCutter(object)
    self.showHelp = true;
    if object.curSplitShape ~= nil then
        self.stumpCutterCounter = self.stumpCutterCounter + (1 * self.totalSawdust);
    end
    if self.stumpCutterCounter > 200 then
        local x, y, z = getWorldTranslation(object.stumpCutterCutNode);
        self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.STUPCUTTER_CUT));
        self.stumpCutterCounter = 0;
    end
end

function sawdust:processChainsaw()
    self.showHelp = true;
    -- chainsaw delimb
    if g_currentMission.player.currentTool.particleSystems[1].isEmitting and not g_currentMission.player.currentTool.isCutting then
        if math.random(10) > (8 - self.totalSawdust) then
            self.chainsawCounter = self.chainsawCounter + (1 * self.totalSawdust);
        end
        if self.chainsawCounter > 100 then
            local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode);
            self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.CHAINSAW_DELIMB));
            self.chainsawCounter = 0;
        end
    end
    -- chainsaw cut
    if g_currentMission.player.currentTool.isCutting then
        self.chainsawCounter = self.chainsawCounter + (1 * self.totalSawdust);
        if g_currentMission.player.currentTool.waitingForResetAfterCut then
            if g_currentMission.player.currentTool.isHorizontalCut and self.chainsawCounter > 220 then
                local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode);
                self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.CHAINSAW_CUTDOWN));
                self.chainsawCounter = 0;
            end
            if not g_currentMission.player.currentTool.isHorizontalCut and self.chainsawCounter > 220 then
                local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode);
                self:addChipToGround(x, y, z, self:calcDelta(AmountTypes.CHAINSAW_CUT));
                self.chainsawCounter = 0;
            end
        end
    end
end

function sawdust:calcDelta(type)
    local amount = 0;
    if type == AmountTypes.CHAINSAW_DELIMB then
        amount = math.random(40, 50);
    elseif type == AmountTypes.CHAINSAW_CUTDOWN then
        amount = math.random(60, 70);
    elseif type == AmountTypes.CHAINSAW_CUT then
        amount = math.random(50, 60);
    elseif type == AmountTypes.WOODHARVESTER_CUT then
        amount = math.random(50, 70);
    elseif type == AmountTypes.STUPCUTTER_CUT then
        amount = math.random(45, 60);
    elseif type == AmountTypes.TREESAW_CUT then
        amount = math.random(45, 65);
    end
    return math.max(TipUtil.getMinValidLiterValue(FillUtil.FILLTYPE_WOODCHIPS), amount * self.totalSawdust);
end

function sawdust:addChipToGround(x, y, z, amount)
    if self.totalSawdust > 0 then
        if g_currentMission:getIsServer() then
            local xzRndm = ((math.random(1, 20)) - 10) / 10;
            local xOffset = math.max(math.min(xzRndm, 0.3), -0.3);
            local zOffset = math.max(math.min(xzRndm, 0.8), -0.1);
            local ex = x + xOffset;
            local ey = y - 0.1;
            local ez = z + zOffset;
            local outerRadius = TipUtil.getDefaultMaxRadius(FillUtil.FILLTYPE_WOODCHIPS);
            TipUtil.tipToGroundAroundLine(nil, amount, FillUtil.FILLTYPE_WOODCHIPS, x, y, z, ex, ey, ez, 0, outerRadius, 1, false, nil, false);
        else
            g_client:getServerConnection():sendEvent(sawdustEvent:new(x, y, z, amount));
        end
    end
end

addModEventListener(sawdust);
