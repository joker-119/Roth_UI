local RB = CreateFrame("Frame")
local numBuffsSkinned = 0
local numDebuffsSkinned = 0
local LSM = LibStub("LibSharedMedia-3.0")
local fonts = AceGUIWidgetLSMlists.font
local sbars = AceGUIWidgetLSMlists.statusbar
local bgs = AceGUIWidgetLSMlists.background
local borders = AceGUIWidgetLSMlists.border
local fontFlags = {"None", "Outline", "Monochrome Outline"}	--, "Monochrome"}
local _, class = UnitClass("player")
local classColor, RBmover, moverShown, db
local BuffFrame = BuffFrame

local defaults = {
	font = "Friz Quadrata TT",
	fstyle = "Outline",
	allWhiteText = true,
	whoCast = true,
	buffs = {
		dfsize = 10,
		cfsize = 14,
		size = 40,
	},
	debuffs = {	
		dfsize = 12,
		cfsize = 14,
		size = 45,
	},
	borAlpha = .4,	--not added in options (yet)
	bg = "Solid",
	bgColor = {r = .32, g = .32, b = .32},
	classbg = false,
	border = "RB border",
	borColor = {r = .5, g = .5, b = .5},
	classbor = false,
	sbar = "Roth_Statusbar3",
	sbarColor = {r = 0, g = 1, b = 0},
	classbar = false,
	posX = -205,
	posY = -13,
	bprow = 8,
}


local function SkinningMachine(svtable, btn, dur, c, icon, bor, firstTime)
	btn:SetSize(db[svtable].size, db[svtable].size)
	icon:SetSize(db[svtable].size-8, db[svtable].size-8)
	if firstTime then
		btn.bg = CreateFrame("Frame", nil, btn)
		btn.bg:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
		dur:SetJustifyH("RIGHT")
		dur:ClearAllPoints()
		dur:SetPoint("BOTTOMRIGHT", 1, 1)
		c:SetJustifyH("LEFT")
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", 2, -2)
		icon:ClearAllPoints()
		icon:SetPoint("CENTER", btn, "CENTER")
		icon:SetTexCoord(.07, .93, .07, .93)
		if bor then
			bor:SetParent(btn.bg)
			bor:SetDrawLayer("BACKGROUND", -7)
			bor:ClearAllPoints()
			bor:SetPoint("TOP",0,0)
			bor:SetPoint("LEFT",0,0)
			bor:SetPoint("RIGHT",0,0)
			bor:SetPoint("BOTTOM",0,0)
			bor:SetColorTexture(1,1,1,1)
		end
		--
		btn.bar = CreateFrame("StatusBar", nil, btn.bg)
		btn.bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -1.5)
		btn.bar:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 0, -1.5)
		btn.bar:SetPoint("BOTTOM", btn.bg, "BOTTOM", 0, 5.5)
		btn.bar:SetMinMaxValues(0, 1)	-- 0%-100%
		--keep these on top ><
		icon:SetParent(btn.bg)
		icon:SetDrawLayer("OVERLAY", 0)
		dur:SetParent(btn.bar)
		dur:SetDrawLayer("OVERLAY", 3)
		c:SetParent(btn.bg)
		c:SetDrawLayer("OVERLAY", 3)
	end
	if bor then
		bor:SetAlpha(1)
	end
	dur:SetFont(LSM:Fetch("font", db.font), db[svtable].dfsize, db.fstyle)
	c:SetFont(LSM:Fetch("font", db.font), db[svtable].cfsize, db.fstyle)
	btn.bg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -max(db[svtable].size*.2, 5))
	btn.bg:SetBackdrop({	bgFile = LSM:Fetch("background", db.bg),
						edgeFile = LSM:Fetch("border", db.border),
						edgeSize = 16,
						insets = {left=3,right=3,top=3,bottom=3}
					})
	btn.bar:SetStatusBarTexture(LSM:Fetch("statusbar", db.sbar))
	if db.classbg then
		btn.bg:SetBackdropColor(classColor.r, classColor.g, classColor.b)
	else
		btn.bg:SetBackdropColor(db.bgColor.r, db.bgColor.g, db.bgColor.b)
	end
	if db.classbor then
		btn.bg:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b)
	else
		btn.bg:SetBackdropBorderColor(db.borColor.r, db.borColor.g, db.borColor.b)
	end
	if db.classbar then
		btn.bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
	else
		btn.bar:SetStatusBarColor(db.sbarColor.r, db.sbarColor.g, db.sbarColor.b)
	end
end

local function SkinBuffs(i, firstTime)
	local b = _G["BuffButton"..i]
	local dur = b.duration
	local c = b.count
	local icon = _G["BuffButton"..i.."Icon"]
	
	SkinningMachine("buffs", b, dur, c, icon, nil, firstTime)
	
	--only setscript and increment count if we're skinning for the first time
	if firstTime then
		local timer = 0
		local dur, exps, _, val
		b.bar:SetScript("OnUpdate", function(self, elapsed)
				timer = timer + elapsed
				if timer >= .1 then
					_,_,_,_,_,dur,exps = UnitBuff("player",i)
					if dur == 0 then
						self:SetValue(1)
					else
						if exps then
							val = exps-GetTime()
							self:SetValue(val/dur)
						end
					end
					timer = 0
				end
			end)
			
		numBuffsSkinned = i
	end
end

local function SkinDebuffs(i, firstTime)
	local d = _G["DebuffButton"..i]
	local dur = d.duration
	local c = d.count
	local icon = _G["DebuffButton"..i.."Icon"]
	local bor = _G["DebuffButton"..i.."Border"]
	local _, _, _, _, debuffType = UnitAura("player", i)
	
	SkinningMachine("debuffs", d, dur, c, icon, bor, firstTime)
	
	--only setscript and increment count if we're skinning for the first time
	if firstTime then
		local timer = 0
		local dur, exps, _, val
		d.bar:SetScript("OnUpdate", function(self, elapsed)
				timer = timer + elapsed
				if timer >= .1 then
					_,_,_,_,_,dur,exps = UnitDebuff("player",i)
					if dur == 0 then
						self:SetValue(1)
					else
						if exps then
							val = exps-GetTime()
							self:SetValue(val/dur)
						end
					end
					timer = 0
				end
			end)
			
		numDebuffsSkinned = i
	end
end

local function SkinTench(firstTime)
	for i = 1, NUM_TEMP_ENCHANT_FRAMES do
		local t = _G["TempEnchant"..i]
		local dur = t.duration
		local c = t.count
		local icon = _G["TempEnchant"..i.."Icon"]
		local bor = _G["TempEnchant"..i.."Border"]
		
		SkinningMachine("buffs", t, dur, c, icon, bor, firstTime)
		
		if firstTime then
			bor:SetVertexColor(.9, 0, .9)
			t.bar:SetValue(1)
			--keep the buffs spaced correctly from Tench
			local TenchWidth = TemporaryEnchantFrame.SetWidth
			local tench1, tench2, tench3, num
			hooksecurefunc(TemporaryEnchantFrame, "SetWidth", function(self,width)
					tench1,_,_,tench2,_,_,tench3 = GetWeaponEnchantInfo()
					num = (tench3 and 3) or (tench2 and 2) or 1
					TenchWidth(self, (num * db.buffs.size) + ((num-1) * 5))
				end)
		end
	end
end

--[[local function SkinConsolidated(firstTime)
	local cb = ConsolidatedBuffs
	local dur = cb.duration
	local c = cb.count
	local icon = ConsolidatedBuffsIcon
	
	SkinningMachine("buffs", cb, dur, c, icon, nil, firstTime)

	CONSOLIDATED_BUFF_ROW_HEIGHT = db.buffs.size*.8
	
	if firstTime then
		icon:SetTexture("Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_QUICK AND DEAD")
		c:ClearAllPoints()
		c:SetPoint("CENTER")
		cb.bar:SetValue(1)
		--fix the tooltip width
		local CBTipWidth = ConsolidatedBuffsTooltip.SetWidth
		hooksecurefunc(ConsolidatedBuffsTooltip, "SetWidth", function(self)
			CBTipWidth(self, max(BuffFrame.numConsolidated*db.buffs.size, 100))
		end)
	end
end]]

local OLD_SetUnitAura, NEW_SetUnitAura, caster, casterName = GameTooltip.SetUnitAura
local function WhoCast()
	if db.whoCast then
		if not NEW_SetUnitAura then
			NEW_SetUnitAura = function(self, unit, id, filter)
				OLD_SetUnitAura(self, unit, id, filter)
				if filter == "HELPFUL" then
					caster = select(8,UnitAura("player", id))
					casterName = caster==nil and "unknown" or caster=="player" and "you" or caster=="pet" and "your pet" or UnitName(caster)
					GameTooltip:AddLine("Provided by "..casterName, .5, .9, 1)
					GameTooltip:Show()
				end
			end
		end
		GameTooltip.SetUnitAura = NEW_SetUnitAura
	else
		GameTooltip.SetUnitAura = OLD_SetUnitAura
	end
end

local function Position()
	BuffFrame:ClearAllPoints()
	BuffFrame:NewSetPoint("TOPRIGHT", db.posX, db.posY)
end
--keep other stuff (like ticket frame) from moving buffs
--BuffFrame.NewSetPoint = BuffFrame.SetPoint
--BuffFrame.SetPoint = Position

local function ShowMover()
	if not RBmover then
		RBmover = CreateFrame("Frame", nil, UIParent)
		RBmover:SetBackdrop({bgFile = "Interface\\BUTTONS\\WHITE8X8.blp"})
		RBmover:SetBackdropColor(.2,.2,.9,.5)
		RBmover:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", 5, 5)
		RBmover:SetSize(200, 150)
		RBmover:SetFrameStrata("TOOLTIP")
		RBmover:EnableMouse(1)
		RBmover:SetMovable(1)
		RBmover:SetScript("OnMouseDown", function(self) self:StartMoving() end)
		RBmover:SetScript("OnMouseUp", function(self)
				self:StopMovingOrSizing()
				_, _, _, db.posX, db.posY = self:GetPoint()
				Position()
				--manually refresh the options display (x,y weren't updating...)
				if RB.optionsFrame:IsShown() then
					InterfaceOptionsFrame_OpenToCategory("RothBuffs")
				end
			end)
	end
	RBmover:SetAlpha(moverShown and 1 or 0)
	RBmover:EnableMouse(moverShown and 1 or 0)
end

local options = {
	name = "RothBuffs Options",
	type = "group",
	args = {
		header1 = {
			name = "Text Options",
			type = "header",
			order = 1,
		},
		font = {
			name = "Font",
			type = "select",
			desc = "Select the font used.",
			dialogControl = "LSM30_Font",
			values = fonts,
			get = function() return db.font end,
			set = function(_,font)
						db.font = font
						for i=1,numBuffsSkinned do
							SkinBuffs(i,false)
						end
						for i=1,numDebuffsSkinned do
							SkinDebuffs(i,false)
						end
						SkinTench(false)
						--SkinConsolidated(false)
					end,
			order = 2,
		},
		fontFlag = {
			name = "Font Flag",
			desc = "Set how to alter the displayed font.",
			type = "select",
			values = fontFlags,
			get = function()
						for k, v in pairs(fontFlags) do
							if db.fstyle == v then
								return k
							end
						end
					end,
			set = function(_,key)
						db.fstyle = fontFlags[key]
						for i=1,numBuffsSkinned do
							SkinBuffs(i,false)
						end
						for i=1,numDebuffsSkinned do
							SkinDebuffs(i,false)
						end
						SkinTench(false)
						--SkinConsolidated(false)
					end,
			order = 3,
		},
		allwhite = {
			name = "White Duration Text",
			desc = "Show durations in white always. (The default UI colors them yellow until they fall below the 30 sec warning threshold. This raises the threshold, so that they are always white.)",
			type = "toggle",
			get = function() return db.allWhiteText end,
			set = function()
					db.allWhiteText = not db.allWhiteText
					if db.allWhiteText then
						BUFF_DURATION_WARNING_TIME = 7200
					else
						BUFF_DURATION_WARNING_TIME = 60
					end
				end,
			order = 3.5,
		},
		buffFonts = {
			name = "Buff Font Sizes",
			type = "group",
			inline = true,
			order = 4,
			args = {
				durSize = {
					name = "Duration",
					type = "range",
					min = 6,
					max = 24,
					step = 1,
					get = function() return db.buffs.dfsize end,
					set = function(_,size) 
							db.buffs.dfsize = size
							for i=1,numBuffsSkinned do
								SkinBuffs(i,false)
							end
							SkinTench(false)
							--SkinConsolidated(false)
						end,
					order = 1,
				},
				countSize = {
					name = "Count",
					type = "range",
					min = 6,
					max = 24,
					step = 1,
					get = function() return db.buffs.cfsize end,
					set = function(_,size) 
							db.buffs.cfsize = size
							for i=1,numBuffsSkinned do
								SkinBuffs(i,false)
							end
							SkinTench(false)
							--SkinConsolidated(false)
						end,
					order = 2,
				},
				whoCast = {
					name = "Who Cast?",
					desc = "Shows who your buff is from in its tooltip.\n\nNOTE: A reload of your UI is required for changes of this setting to take effect. This may be done with /reload",
					type = "toggle",
					get = function() return db.whoCast end,
					set = function() db.whoCast = not db.whoCast WhoCast() end,
					order = 3,
				},
			},
		},
		debuffFonts = {
			name = "Debuff Font Sizes",
			type = "group",
			inline = true,
			order = 5,
			args = {
				durSize = {
					name = "Duration",
					type = "range",
					min = 6,
					max = 24,
					step = 1,
					get = function() return db.debuffs.dfsize end,
					set = function(_,size) 
							db.debuffs.dfsize = size
							for i=1,numDebuffsSkinned do
								SkinDebuffs(i,false)
							end
						end,
					order = 1,
				},
				countSize = {
					name = "Count",
					type = "range",
					min = 6,
					max = 24,
					step = 1,
					get = function() return db.debuffs.cfsize end,
					set = function(_,size) 
							db.debuffs.cfsize = size
							for i=1,numDebuffsSkinned do
								SkinDebuffs(i,false)
							end
						end,
					order = 2,
				},
			},
		},
		spacer1 = {
			name = " ",
			type = "description",
			width = "full",
			order = 7,
		},
		header2 = {
			name = "Skin Options",
			type = "header",
			order = 8,
		},
		border = {
			name = "Border",
			type = "group",
			inline = true,
			order = 9,
			args = {
				texture = {
					name = "Texture",
					type = "select",
					desc = "Select the texture used for the border.",
					dialogControl = "LSM30_Border",
					values = borders,
					get = function() return db.border end,
					set = function(_,border)
								db.border = border
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 1,
				},
				borColor = {
					name = "Color",
					desc = "Select a color for the border texture.",
					type = "color",
					width = "half",
					disabled = function() return db.classbor end,
					get = function() return db.borColor.r, db.borColor.g, db.borColor.b end,
					set = function(_,r,g,b)
								db.borColor.r,db.borColor.g,db.borColor.b = r,g,b
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 2,
				},
				classbor = {
					name = "By Class",
					type = "toggle",
					width = "half",
					get = function() return db.classbor end,
					set = function()
								db.classbor = not db.classbor
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 3,
				},
			},
		},
		sbar = {
			name = "Statusbar",
			type = "group",
			inline = true,
			order = 10,
			args = {
				texture = {
					name = "Texture",
					type = "select",
					desc = "Select the texture used for the timer bars.",
					dialogControl = "LSM30_Statusbar",
					values = sbars,
					get = function() return db.sbar end,
					set = function(_,sbar)
								db.sbar = sbar
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 1,
				},
				sbarColor = {
					name = "Color",
					desc = "Select a color for the timer bar texture.",
					type = "color",
					width = "half",
					disabled = function() return db.classbar end,
					get = function() return db.sbarColor.r, db.sbarColor.g, db.sbarColor.b end,
					set = function(_,r,g,b)
								db.sbarColor.r,db.sbarColor.g,db.sbarColor.b = r,g,b
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 2,
				},
				classbar = {
					name = "By Class",
					type = "toggle",
					width = "half",
					get = function() return db.classbar end,
					set = function()
								db.classbar = not db.classbar
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 3,
				},
			},
		},
		bg = {
			name = "Background",
			type = "group",
			inline = true,
			order = 11,
			args = {
				texture = {
					name = "Texture",
					type = "select",
					desc = "Select the texture used for the background.",
					dialogControl = "LSM30_Background",
					values = bgs,
					get = function() return db.bg end,
					set = function(_,bg)
								db.bg = bg
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 1,
				},
				bgColor = {
					name = "Color",
					desc = "Select a color for the background texture.",
					type = "color",
					width = "half",
					disabled = function() return db.classbg end,
					get = function() return db.bgColor.r, db.bgColor.g, db.bgColor.b end,
					set = function(_,r,g,b)
								db.bgColor.r,db.bgColor.g,db.bgColor.b = r,g,b
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 2,
				},
				classbg = {
					name = "By Class",
					type = "toggle",
					width = "half",
					get = function() return db.classbg end,
					set = function()
								db.classbg = not db.classbg
								for i=1,numBuffsSkinned do
									SkinBuffs(i,false)
								end
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
								SkinTench(false)
								--SkinConsolidated(false)
							end,
					order = 3,
				},
			},
		},
		spacer2 = {
			name = " ",
			type = "description",
			width = "full",
			order = 12,
		},
		header3 = {
			name = "Layout Options",
			type = "header",
			order = 13,
		},
		posX = {
			name = "X-Offset",
			desc = "The horizontal offset from the top-right corner of your screen. This should be a negative number.",
			type = "input",
			width = "half",
			get = function() return tostring(db.posX) end,
			set = function(_,x)
					db.posX = tonumber(x)
					Position()
				end,
			order = 14,
		},
		posY = {
			name = "Y-Offset",
			desc = "The vertical offset from the top-right corner of your screen. This should be a negative number.",
			type = "input",
			width = "half",
			get = function() return tostring(db.posY) end,
			set = function(_,y)
					db.posY = tonumber(y)
					Position()
				end,
			order = 15,
		},
		mover = {
			name = "Show Anchor",
			type = "toggle",
			get = function() return moverShown end,
			set = function()
					moverShown = not moverShown
					ShowMover()
				end,
			order = 16,
		},
		bprow = {
			name = "Buffs per Row",
			desc = "Number of buffs/debuffs before starting a new row.",
			type = "range",
			min = 2,
			max = BUFF_MAX_DISPLAY,
			step = 1,
			get = function() return db.bprow end,
			set = function(_,bprow)
					db.bprow = bprow
					BUFFS_PER_ROW = bprow
				end,
			order = 17,
		},
		sizes = {
			name = "Frame Sizes",
			type = "group",
			inline = true,
			order = 17.5,
			args = {
				buffSize = {
					name = "Buffs",
					desc = "The size of the buff frames.",
					type = "range",
					min = 20,
					max = 60,
					step = 1,
					get = function() return db.buffs.size end,
					set = function(_,size)
							db.buffs.size = size
							for i=1,numBuffsSkinned do
								SkinBuffs(i,false)
							end
							SkinTench(false)
							SkinConsolidated(false)
						end,
					order = 1,
				},
				debuffSize = {
					name = "Debuffs",
					desc = "The size of the debuff frames.",
					type = "range",
					min = 20,
					max = 60,
					step = 1,
					get = function() return db.debuffs.size end,
					set = function(_,size)
							db.debuffs.size = size
							for i=1,numDebuffsSkinned do
								SkinDebuffs(i,false)
							end
						end,
					order = 2,
				},
			},
		},
		spacer3 = {
			name = " ",
			type = "description",
			width = "full",
			order = 18,
		},
		header4 = {
			name = "Profile",
			type = "header",
			order = 19,
		},
		charSpec = {
			name = "Character specific settings",
			desc = "Have this character use their own profile.  If checked, any changes made will not affect other characters.\n\n|c00E30016WARNING:|r Your UI will be reloaded in the process!",
			type = "toggle",
			width = "full",
			confirm = true,
			get = function() return RothBuffsDB.charSpec end,
			set = function()
						RothBuffsPCDB.charSpec = not RothBuffsPCDB.charSpec
						ReloadUI()
					end,
			order = 20,
		},
		copyProfile = {
			name = "Copy from Default",
			desc = "Copy all settings from the default, global profile to this character's profile.  This will not effect other characters' specific profiles.\n\n|c00E30016WARNING:|r Your UI will be reloaded in the process!",
			type = "execute",
			confirm = true,
			disabled = function() return not RothBuffsPCDB.charSpec end,
			func = function()
						RothBuffsPCDB = RothBuffsDB
						RothBuffsPCDB.charSpec = true
						ReloadUI()
					end,
			order = 21,
		},
		resetProfile = {
			name = "Profile Reset",
			desc = "Reset this profile back to the out-of-the-box settings.  If you reset the character specific profile, the global profile will be untouched, and vice versa.  This will not effect other character specific profiles.\n\n|c00E30016WARNING:|r Your UI will be reloaded in the process!",
			type = "execute",
			confirm = true,
			func = function()
						if RothBuffsPCDB.charSpec then
							RothBuffsPCDB = {charSpec = true}
						else
							RothBuffsDB = {}
						end
						ReloadUI()
					end,
			order = 22,
		},
	},
}


local function SetUpDB()
	if RothBuffsPCDB.charSpec then
		--set defaults if new charSpec DB
		for k,v in pairs(defaults) do
			if type(RothBuffsPCDB[k]) == "nil" then
				RothBuffsPCDB[k] = v
			end
		end
		db = RothBuffsPCDB
	else
		db = RothBuffsDB
	end
end

local function PEW()
	RothBuffsDB = RothBuffsDB or {}
	RothBuffsPCDB = RothBuffsPCDB or {}
		if RothBuffsPCDB.charSpec == nil then
			RothBuffsPCDB.charSpec = false
		end
	for k,v in pairs(defaults) do
	    if type(RothBuffsDB[k]) == "nil" then
	        RothBuffsDB[k] = v
	    end
	end
	SetUpDB()
	
	classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
	
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback(function()
				if db.classbor or db.classbg or db.classbar then
					for i=1,numBuffsSkinned do
						SkinBuffs(i,false)
					end
					for i=1,numDebuffsSkinned do
						SkinDebuffs(i,false)
					end
					SkinTench(false)
					--SkinConsolidated(false)
				end
			end)
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("RothBuffs", options)
	RB.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RothBuffs", "RothBuffs")
	SlashCmdList["ROTHBUFFS"] = function() InterfaceOptionsFrame_OpenToCategory("RothBuffs") end
	SLASH_ROTHBUFFS1 = "/rothbuffs"
	SLASH_ROTHBUFFS2 = "/rb"

	if db.allWhiteText then
		BUFF_DURATION_WARNING_TIME = 7200
	end
	BUFF_ROW_SPACING = 15
	BUFFS_PER_ROW = db.bprow
	
	for i = 1, BUFF_ACTUAL_DISPLAY do
		SkinBuffs(i, true)
	end
	for i = 1, DEBUFF_ACTUAL_DISPLAY do
		SkinDebuffs(i, true)
	end
	SkinTench(true)
	--SkinConsolidated(true)

	--keep other stuff (like ticket frame) from moving buffs
	BuffFrame.NewSetPoint = BuffFrame.SetPoint
	BuffFrame.SetPoint = Position	
	Position()

	WhoCast()
	
	RB:UnregisterEvent("PLAYER_ENTERING_WORLD")
	RB:RegisterEvent("UNIT_AURA")
	RB:SetScript("OnEvent", function(s,e,unit)
			if unit == "player" then
				if BUFF_ACTUAL_DISPLAY > numBuffsSkinned then
					for i = numBuffsSkinned+1, BUFF_ACTUAL_DISPLAY do
						SkinBuffs(i, true)
					end
				end
				if DEBUFF_ACTUAL_DISPLAY > numDebuffsSkinned then
					for i = numDebuffsSkinned+1, DEBUFF_ACTUAL_DISPLAY do
						SkinDebuffs(i, true)
					end
				end
				--don't bother checking if they're all skinned
				if numBuffsSkinned == BUFF_MAX_DISPLAY and numDebuffsSkinned == DEBUFF_MAX_DISPLAY then
					RB:UnregisterEvent("UNIT_AURA")
					RB:SetScript("OnEvent", nil)
				end
			end
		end)
	PEW = nil
end


LSM:Register("border", "RB border", "Interface\\AddOns\\Roth_UI\\embeds\\RothBuffs\\media\\5.tga")
LSM:Register("statusbar", "Solid", "Interface\\AddOns\\Roth_UI\\embeds\\RothBuffs\\media\\RothBuffs\\Solid.tga")
LSM:Register("statusbar", "Roth_Statusbar1", "Interface\\AddOns\\Roth_UI\\media\\statusbar")
LSM:Register("statusbar", "Roth_Statusbar2", "Interface\\AddOns\\Roth_UI\\media\\statusbar2")
LSM:Register("statusbar", "Roth_Statusbar3", "Interface\\AddOns\\Roth_UI\\media\\statusbar3")
LSM:Register("statusbar", "Roth_Statusbar4", "Interface\\AddOns\\Roth_UI\\media\\statusbar4")
LSM:Register("statusbar", "Roth_Statusbar5", "Interface\\AddOns\\Roth_UI\\media\\statusbar5")
LSM:Register("statusbar", "Roth_Statusbar6", "Interface\\AddOns\\Roth_UI\\media\\statusbar128")
LSM:Register("statusbar", "Roth_Statusbar7", "Interface\\AddOns\\Roth_UI\\media\\statusbar128_3")
LSM:Register("statusbar", "Roth_Statusbar8", "Interface\\AddOns\\Roth_UI\\media\\statusbar256")
LSM:Register("statusbar", "Roth_Statusbar9", "Interface\\AddOns\\Roth_UI\\media\\statusbar256_2")
LSM:Register("statusbar", "Roth_Statusbar10", "Interface\\AddOns\\Roth_UI\\media\\statusbar256_3")
LSM:Register("background", "Solid", "Interface\\AddOns\\Roth_UI\\embeds\\RothBuffs\\media\\RothBuffs\\Solid.tga")

RB:SetScript("OnEvent", PEW)

RB:RegisterEvent("PLAYER_ENTERING_WORLD")