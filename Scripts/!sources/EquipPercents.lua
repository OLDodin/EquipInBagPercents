local m_createdTxtWdg = {}
local m_createdOverflowTxtWdg = {}
local m_wasShowed = false
local m_wasOverflowShowed = false

local function CreatePercentTxtWdg(anItemID, aCnt, aBagWdg, aWdgName1, aWdgName2)
	if anItemID then
		local itemBudgets = itemLib.GetBudgets(anItemID)
		if itemBudgets then
			local equipPercent = itemBudgets[ENUM_FloatingBudgetType_OffenceBudget]
			local parentWdg = aBagWdg:GetChildChecked(aWdgName1, false):GetChildChecked(aWdgName2 .. toString(common.FormatInt(math.floor(aCnt/6) + 1, "%02d")), false):GetChildChecked("Item0" .. aCnt % 6 + 1, false)
			local percentTxtWdg = createWidget(mainForm, "percentTxt", "TextView", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 40, 20, 5, 0)
			parentWdg:AddChild(percentTxtWdg)
			setText(percentTxtWdg, tostring(equipPercent).."%", "ColorWhite", 16)
			return percentTxtWdg
		end
	end
end

function ShowPercent()
	HidePercent()

	local bagWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
	if not bagWdg:IsVisibleEx() or bagWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() ~= 1 then
		return
	end
	
	for i = 0, avatar.InventoryGetBaseBagSlotCount() - 1 do
		local itemID = avatar.GetInventoryItemId(i)
		local percentTxtWdg = CreatePercentTxtWdg(itemID, i, bagWdg, "Area", "SlotLine")
		if percentTxtWdg then
			m_createdTxtWdg[i] = percentTxtWdg
		end
	end
	
	m_wasShowed = true
end

function ShowOverflowPercent()
	HideOverflowPercent()

	local bagWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
	if not bagWdg:IsVisibleEx() or bagWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() ~= 1 then
		return
	end
	
	local buttonOverScrollLeft = bagWdg:GetChildChecked("Overflow", false):GetChildChecked("OverflowHead", false):GetChildChecked("ButtonScrollLeft", false)
	local btnEnabled = buttonOverScrollLeft:IsEnabled()
	-- показываем только для 1й страницы переполненной сумки
	if btnEnabled then
		return
	end
	
	local bagOverflowIDs = avatar.GetInventoryOverflowItemIds()
	local overflowSize = math.min(avatar.GetInventoryOverflowSize(), 12)
	for i = 0, overflowSize - 1 do
		local itemID = bagOverflowIDs[i]
		local percentTxtWdg = CreatePercentTxtWdg(itemID, i, bagWdg, "Overflow", "OverflowLine")
		if percentTxtWdg then
			m_createdOverflowTxtWdg[i] = percentTxtWdg
		end
	end
	
	m_wasOverflowShowed = true
end

function HideOverflowPercent()
	for i, wdg in pairs(m_createdOverflowTxtWdg) do
		destroy(wdg)
	end
	m_createdOverflowTxtWdg = {}

	m_wasOverflowShowed = false
end

function HidePercent()
	for i, wdg in pairs(m_createdTxtWdg) do
		destroy(wdg)
	end
	m_createdTxtWdg = {}

	m_wasShowed = false
end

function OnChangeInventorySlot(aParam)
	local itemBudgets = itemLib.GetBudgets(aParam.itemId)
	if itemBudgets then
		ShowPercent()
	end
end

function OnChangeInventorySlotOverflow(aParam)
	ShowOverflowPercent()
end

function OnEventContainerItemRemoved(aParam)
	if aParam.isRemovedItem and aParam.slotType == ITEM_CONT_INVENTORY then
		if m_createdTxtWdg[aParam.slot] then
			destroy(m_createdTxtWdg[aParam.slot])
			m_createdTxtWdg[aParam.slot] = nil
		end
	end
end

function Update()
	local bagWdg = common.GetAddonMainForm("ContextBag"):GetChildChecked("Bag", false)
	
	local buttonOverScrollLeft = bagWdg:GetChildChecked("Overflow", false):GetChildChecked("OverflowHead", false):GetChildChecked("ButtonScrollLeft", false)
	local btnEnabled = buttonOverScrollLeft:IsEnabled()
	
	if bagWdg:IsVisibleEx() and bagWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() == 1 then
		if not m_wasShowed then
			ShowPercent()
		end
		if not btnEnabled then 
			if not m_wasOverflowShowed then
				ShowOverflowPercent()
			end
		else
			HideOverflowPercent()
		end
	else
		HidePercent()
		HideOverflowPercent()
	end
end

function Init()
	common.RegisterEventHandler(OnChangeInventorySlot, "EVENT_INVENTORY_SLOT_CHANGED")
	common.RegisterEventHandler(OnEventContainerItemRemoved, "EVENT_CONTAINER_ITEM_REMOVED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_SLOT_ADDED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_SLOT_REMOVED")
	common.RegisterEventHandler(OnChangeInventorySlotOverflow, "EVENT_INVENTORY_OVERFLOW_CHANGED")

	startTimer("updateTimer", Update, 0.2)
end

if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end