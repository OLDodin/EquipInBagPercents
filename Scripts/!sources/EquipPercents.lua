local m_createdTxtWdg = { [ITEM_CONT_DEPOSITE] = {}, [ITEM_CONT_INVENTORY] = {}, [ITEM_CONT_INVENTORY_OVERFLOW] = {} }
local m_wasShowed = { [ITEM_CONT_DEPOSITE] = false, [ITEM_CONT_INVENTORY] = false, [ITEM_CONT_INVENTORY_OVERFLOW] = false }


setTemplateWidget("common")

local function GetBagSlotWdg(aBagWdg, aCnt)
	return aBagWdg:GetChildChecked("Area", false):GetChildChecked("SlotLine" .. toString(common.FormatInt(math.floor(aCnt/6) + 1, "%02d")), false):GetChildChecked("Item0" .. aCnt % 6 + 1, false)
end

local function GetOverflowBagSlotWdg(aBagWdg, aCnt)
	return aBagWdg:GetChildChecked("Overflow", false):GetChildChecked("OverflowLine" .. toString(common.FormatInt(math.floor(aCnt/6) + 1, "%02d")), false):GetChildChecked("Item0" .. aCnt % 6 + 1, false)
end

local function GetDepositeSlotWdg(aDepositeWdg, aCnt)
	local depostiteScroller = aDepositeWdg:GetChildChecked("DepositeBoxContainer", false)
	local scrollerItem = depostiteScroller:At(0)
	local slotPlate = scrollerItem:GetChildChecked("SlotsPlate" .. toString(common.FormatInt(math.floor(aCnt/12) + 1, "%02d")), false)
	return slotPlate:GetChildChecked("Slot" .. toString(common.FormatInt(aCnt % 12 + 1, "%02d")), false)
end

local function CreatePercentTxtWdg(anItemID, aCnt, aWdg, aType)
	if not anItemID then
		return
	end
	local itemBudgets = itemLib.GetBudgets(anItemID)
	if not itemBudgets then
		return
	end

	local equipPercent = itemBudgets[ENUM_FloatingBudgetType_OffenceBudget]

	local parentWdg = nil
	if aType == ITEM_CONT_DEPOSITE then
		parentWdg = GetDepositeSlotWdg(aWdg, aCnt)
	elseif aType == ITEM_CONT_INVENTORY then
		parentWdg = GetBagSlotWdg(aWdg, aCnt)
	elseif aType == ITEM_CONT_INVENTORY_OVERFLOW then
		parentWdg = GetOverflowBagSlotWdg(aWdg, aCnt)
	end
	
	local percentTxtWdg = createWidget(mainForm, "percentTxt", "TextView", WIDGET_ALIGN_LOW, WIDGET_ALIGN_HIGH, 40, 20, 1, 0)
	parentWdg:AddChild(percentTxtWdg)
	--percentTxtWdg:SetPriority(parentWdg:GetChildChecked("StatIcon", false):GetPriority() + 2)
	setText(percentTxtWdg, tostring(equipPercent).."%", "ColorWhite", "right", 14)
	return percentTxtWdg
end

function CheckBagCondition(aWdg)
	if not aWdg:IsVisibleEx() or aWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() ~= 1 then
		return false
	end
	return true
end

function CheckOverflowCondition(aWdg)
	if not CheckBagCondition(aWdg) then
		return false
	end
	local buttonOverScrollLeft = aWdg:GetChildChecked("Overflow", false):GetChildChecked("OverflowHead", false):GetChildChecked("ButtonScrollLeft", false)
	local btnEnabled = buttonOverScrollLeft:IsEnabled()
	-- показываем только для 1й страницы переполненной сумки
	if btnEnabled then
		return false
	end
	return true
end

function CheckDepositeCondition(aWdg)
	if aWdg:IsVisibleEx() then
		return true
	end
	return false
end

function ShowPercent(aType)
	HidePercent(aType)
	
	local needCreate = false
	local baseWdg = nil
	if aType == ITEM_CONT_DEPOSITE then
		baseWdg = common.GetAddonMainForm("ContextDepositeBox"):GetChildChecked("MainPanel", false)
		needCreate = CheckDepositeCondition(baseWdg)
	elseif aType == ITEM_CONT_INVENTORY then
		baseWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
		needCreate = CheckBagCondition(baseWdg)
	elseif aType == ITEM_CONT_INVENTORY_OVERFLOW then
		baseWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
		needCreate = CheckOverflowCondition(baseWdg)
	end

	if not needCreate then
		return
	end
	
	local maxItemCnt = 0
	if aType == ITEM_CONT_DEPOSITE then
		maxItemCnt = containerLib.GetSize(aType)
	elseif aType == ITEM_CONT_INVENTORY then
		maxItemCnt = avatar.InventoryGetBaseBagSlotCount()
	elseif aType == ITEM_CONT_INVENTORY_OVERFLOW then
		maxItemCnt = math.min(containerLib.GetSize(aType), 12)
	end
	
	
	local items = containerLib.GetItems(aType)
	for i = 0, maxItemCnt - 1 do
		local itemID = items[i]
		local percentTxtWdg = CreatePercentTxtWdg(items[i], i, baseWdg, aType)
		if percentTxtWdg then
			m_createdTxtWdg[aType][i] = percentTxtWdg
		end
	end
	
	m_wasShowed[aType] = true
end

function HidePercent(aType)
	for i, wdg in pairs(m_createdTxtWdg[aType]) do
		destroy(wdg)
	end
	m_createdTxtWdg[aType] = {}

	m_wasShowed[aType] = false
end

function OnChangeInventorySlot(aParam)
	local itemBudgets = itemLib.GetBudgets(aParam.itemId)
	if itemBudgets then
		ShowPercent(ITEM_CONT_INVENTORY)
	end
end

function OnChangeInventorySlotOverflow(aParam)
	ShowPercent(ITEM_CONT_INVENTORY_OVERFLOW)
end

function OnEventDepositeBoxChanged()
	ShowPercent(ITEM_CONT_DEPOSITE)
end

function OnEventContainerItemRemoved(aParam)
	if aParam.isRemovedItem and aParam.slotType == ITEM_CONT_INVENTORY then
		if m_createdTxtWdg[aParam.slotType][aParam.slot] then
			destroy(m_createdTxtWdg[aParam.slotType][aParam.slot])
			m_createdTxtWdg[aParam.slotType][aParam.slot] = nil
		end
	end
end

function Update()
	local bagWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
	
	if CheckBagCondition(bagWdg) then
		if not m_wasShowed[ITEM_CONT_INVENTORY] then
			ShowPercent(ITEM_CONT_INVENTORY)
		end
	else
		HidePercent(ITEM_CONT_INVENTORY)
	end
	
	if CheckOverflowCondition(bagWdg) then
		if not m_wasShowed[ITEM_CONT_INVENTORY_OVERFLOW] then
			ShowPercent(ITEM_CONT_INVENTORY_OVERFLOW)
		end
	else
		HidePercent(ITEM_CONT_INVENTORY_OVERFLOW)
	end
	
	local depositeWdg = common.GetAddonMainForm("ContextDepositeBox"):GetChildChecked("MainPanel", false)
	if CheckDepositeCondition(depositeWdg) then
		if not m_wasShowed[ITEM_CONT_DEPOSITE] then
			ShowPercent(ITEM_CONT_DEPOSITE)
		end
	else
		HidePercent(ITEM_CONT_DEPOSITE)
	end
end

function Init()
	common.RegisterEventHandler(OnChangeInventorySlot, "EVENT_INVENTORY_SLOT_CHANGED")
	common.RegisterEventHandler(OnEventContainerItemRemoved, "EVENT_CONTAINER_ITEM_REMOVED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_SLOT_ADDED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_SLOT_REMOVED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_CHANGED")
	common.RegisterEventHandler(OnEventDepositeBoxChanged, "EVENT_DEPOSITE_BOX_CHANGED")

	startTimer("updateTimer", Update, 0.2)
end

if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end