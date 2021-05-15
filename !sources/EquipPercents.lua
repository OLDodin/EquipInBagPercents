local m_createdTxtWdg = {}
local m_wasShowed = false

function ShowPercent()
	HidePercent()

	local bagWdg = stateMainForm:GetChildChecked("ContextBag", false):GetChildChecked("Bag", false)
	if bagWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() ~= 1 then
		return
	end
	
	for i = 0, avatar.InventoryGetBaseBagSlotCount() - 1 do
		local itemID = avatar.GetInventoryItemId(i)
		if itemID then
			local itemBudgets = itemLib.GetBudgets(itemID)
			if itemBudgets then
				local equipPercent = itemBudgets[ENUM_FloatingBudgetType_OffenceBudget]
				local parentWdg = bagWdg:GetChildChecked("Area", false):GetChildChecked("SlotLine" .. toString(common.FormatInt(math.floor(i/6) + 1, "%02d")), false):GetChildChecked("Item0" .. i % 6 + 1, false)
				local percentTxtWdg = createWidget(parentWdg, "closeButton", "TextView", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 40, 20, 5, 0)
				setText(percentTxtWdg, tostring(equipPercent).."%", "ColorWhite", 16)
				
				m_createdTxtWdg[i] = percentTxtWdg
			end
		end
	end
	
	m_wasShowed = true
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

function OnEventContainerItemRemoved(aParam)
	if aParam.isRemovedItem and aParam.slotType == ITEM_CONT_INVENTORY then
		if m_createdTxtWdg[aParam.slot] then
			destroy(m_createdTxtWdg[aParam.slot])
			m_createdTxtWdg[aParam.slot] = nil
		end
	end
end

function Update()
	local bagWdg = stateMainForm:GetChildChecked("ContextBag", false):GetChildChecked("Bag", false)
	
	if bagWdg:IsVisibleEx() and bagWdg:GetChildChecked("Tabs", false):GetChildChecked("Tab01", false):GetVariant() == 1 then
		if not m_wasShowed then
			ShowPercent()
		end
	else
		HidePercent()
	end
end

function Init()
	local m_template = createWidget(nil, "Template", "Template")
	setTemplateWidget(m_template)

	common.RegisterEventHandler(OnChangeInventorySlot, "EVENT_INVENTORY_SLOT_CHANGED")
	common.RegisterEventHandler(OnEventContainerItemRemoved, "EVENT_CONTAINER_ITEM_REMOVED")
	
	startTimer("updateTimer", Update, 0.2)
end

if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end