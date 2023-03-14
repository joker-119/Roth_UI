local SB = CreateFrame("Frame")
local numBuffsSkinned = 0
local numDebuffsSkinned = 0
local LSM = LibStub("LibSharedMedia-3.0")
local fonts = AceGUIWidgetLSMlists.font
local sbars = AceGUIWidgetLSMlists.statusbar
local bgs = AceGUIWidgetLSMlists.background
local borders = AceGUIWidgetLSMlists.border
local fontFlags = {"None", "Outline", "Monochrome Outline", "Monochrome"}
local _, class = UnitClass("player")
local classColor, SBmover, moverShown, db
local BuffFrame = BuffFrame
local addon, ns = ...
local cfg = ns.cfg

if not cfg.embeds.Roth_ShinyBuffs then return end

local defaults = {
	font = "Cracked",
	fstyle = "Outline",
	allWhiteText = false,
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
	bg = "Solid",
	bgColor = {r = .32, g = .32, b = .32},
	classbg = false,
	border = "RB border",
	borColor = {r = .5, g = .5, b = .5},
	classbor = false,
	debuffTypeBor = false,
	borderWidth = 16,
	debuffOverlayAlpha = .4,
	sbar = "Roth_Statusbar3",
	sbarColor = {r = 0, g = 1, b = 0},
	classbar = false,
	posX = -205,
	posY = -13,
	anchor1 = "TOPRIGHT",
	anchor2 = "TOPRIGHT",
	bprow = 8,
}


local function SkinningMachine(svtable, btn, dur, c, icon, bor, firstTime)
	btn:SetSize(db[svtable].size, db[svtable].size)
	icon:SetSize(db[svtable].size-8, db[svtable].size-8)
	if firstTime then
		btn.bg = CreateFrame("Frame", nil, btn, BackdropTemplateMixin and "BackdropTemplate")
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
			bor:SetDrawLayer("OVERLAY", 1)
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
		bor:SetAlpha(db.debuffOverlayAlpha)
		bor:ClearAllPoints()
		if db.debuffTypeBor then
			bor:SetAllPoints(btn.bg)
			bor:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
			bor:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
			bor:SetAlpha(1)
		else
			bor:SetAllPoints(icon)
			bor:SetColorTexture(1,1,1,1)
		end	
	end
	dur:SetFont(LSM:Fetch("font", db.font), db[svtable].dfsize, db.fstyle)
	c:SetFont(LSM:Fetch("font", db.font), db[svtable].cfsize, db.fstyle)
	btn.bg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -max(db[svtable].size*.2, 5))
	btn.bg:SetBackdrop({	bgFile = LSM:Fetch("background", db.bg),
						edgeFile = LSM:Fetch("border", db.border),
						edgeSize = db.borderWidth,
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
					_,_,_,_,dur,exps = UnitBuff("player",i)
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
	
	SkinningMachine("debuffs", d, dur, c, icon, bor, firstTime)
	
	--only setscript and increment count if we're skinning for the first time
	if firstTime then
		local timer = 0
		local dur, exps, _, val
		d.bar:SetScript("OnUpdate", function(self, elapsed)
				timer = timer + elapsed
				if timer >= .1 then
					_,_,_,_,dur,exps = UnitDebuff("player",i)
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

local OLD_SetUnitAura, NEW_SetUnitAura, caster, casterName = GameTooltip.SetUnitAura
local function WhoCast()
	if db.whoCast then
		if not NEW_SetUnitAura then
			NEW_SetUnitAura = function(self, unit, id, filter)
				OLD_SetUnitAura(self, unit, id, filter)
				if filter == "HELPFUL" then
					_,_,_,_,_,_,caster = UnitAura("player", id)	--7th return
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
	BuffFrame:NewSetPoint(db.anchor1, UIParent, db.anchor2, db.posX, db.posY)
end

local function ShowMover()
	if not SBmover then
		SBmover = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		SBmover:SetBackdrop({bgFile = "Interface\\AddOns\\Roth_UI\\media\\mover.blp"})
		SBmover:SetBackdropColor(1,1,1,.5)
		SBmover:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", 5, 5)
		SBmover:SetSize(200, 150)
		SBmover:SetFrameStrata("TOOLTIP")
		SBmover:EnableMouse(true)
		BuffFrame:SetMovable(true)
		BuffFrame:SetClampedToScreen(true)
		SBmover:SetScript("OnMouseDown", function(self) 
				BuffFrame:StartMoving()
			end)
		SBmover:SetScript("OnMouseUp", function(self)
				BuffFrame:StopMovingOrSizing()
				db.anchor1, _, db.anchor2, db.posX, db.posY = BuffFrame:GetPoint()
				--Position()
				if SB.optionsFrame:IsShown() then
					InterfaceOptionsFrame_OpenToCategory("ShinyBuffs")
				end
			end)
	end
	SBmover:SetAlpha(moverShown and 1 or 0)
	SBmover:EnableMouse(moverShown)
end

local function SkinAuras()
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
end

local options = {
	name = "ShinyBuffs Options",
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
			order = 4,
		},
		buffFonts = {
			name = "Buff Font Sizes",
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
					get = function() return db.buffs.dfsize end,
					set = function(_,size) 
							db.buffs.dfsize = size
							for i=1,numBuffsSkinned do
								SkinBuffs(i,false)
							end
							SkinTench(false)
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
						end,
					order = 2,
				},
				whoCast = {
					name = "Who Cast?",
					desc = "Shows who your buff is from in its tooltip.",
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
			order = 6,
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
							end,
					order = 1,
				},
				borderWidth = {
					name = "Border Width",
					desc = "Width of the border.",
					type = "range",
					min = 1,
					max = 24,
					step = .5,
					get = function() return db.borderWidth end,
					set = function(_,size)
							db.borderWidth = size
							for i=1,numBuffsSkinned do
								SkinBuffs(i,false)
							end
							for i=1,numDebuffsSkinned do
								SkinDebuffs(i,false)
							end
							SkinTench(false)
						end,
					order = 2,
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
							end,
					order = 3,
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
							end,
					order = 4,
				},
				debuffTypeBor = {
					name = "By Debuff Type",
					desc = "Display debuff dispel type as border instead of icon overlay.",
					type = "toggle",
					get = function() return db.debuffTypeBor end,
					set = function()
								db.debuffTypeBor = not db.debuffTypeBor
								for i=1,numDebuffsSkinned do
									SkinDebuffs(i,false)
								end
							end,
					order = 5,
				},
				debuffOverlayAlpha = {
					name = "Debuff Overlay Alpha",
					desc = "Transparency of the debuffs' dispel type overlay.",
					type = "range",
					disabled = function() return db.debuffTypeBor end,
					min = .25,
					max = 1,
					step = .05,
					get = function() return db.debuffOverlayAlpha end,
					set = function(_,alpha)
							db.debuffOverlayAlpha = alpha
							for i=1,numDebuffsSkinned do
								SkinDebuffs(i,false)
							end
						end,
					order = 6,
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
			get = function() return ShinyBuffsDB.charSpec end,
			set = function()
						ShinyBuffsPCDB.charSpec = not ShinyBuffsPCDB.charSpec
						ReloadUI()
					end,
			order = 20,
		},
		copyProfile = {
			name = "Copy from Default",
			desc = "Copy all settings from the default, global profile to this character's profile.  This will not effect other characters' specific profiles.\n\n|c00E30016WARNING:|r Your UI will be reloaded in the process!",
			type = "execute",
			confirm = true,
			disabled = function() return not ShinyBuffsPCDB.charSpec end,
			func = function()
						ShinyBuffsPCDB = ShinyBuffsDB
						ShinyBuffsPCDB.charSpec = true
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
						if ShinyBuffsPCDB.charSpec then
							ShinyBuffsPCDB = {charSpec = true}
						else
							ShinyBuffsDB = {}
						end
						ReloadUI()
					end,
			order = 22,
		},
	},
}


local function SetUpDB()
	if ShinyBuffsPCDB.charSpec then
		--set defaults if new charSpec DB
		for k,v in pairs(defaults) do
			if type(ShinyBuffsPCDB[k]) == "nil" then
				ShinyBuffsPCDB[k] = v
			end
		end
		db = ShinyBuffsPCDB
	else
		db = ShinyBuffsDB
	end
end

local function PEW()
	ShinyBuffsDB = ShinyBuffsDB or {}
	ShinyBuffsPCDB = ShinyBuffsPCDB or {}
		if ShinyBuffsPCDB.charSpec == nil then
			ShinyBuffsPCDB.charSpec = false
		end
	for k,v in pairs(defaults) do
	    if type(ShinyBuffsDB[k]) == "nil" then
	        ShinyBuffsDB[k] = v
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
				end
			end)
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ShinyBuffs", options)
	SB.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ShinyBuffs", "ShinyBuffs")
	SlashCmdList["SHINYBUFFS"] = function()
			InterfaceOptionsFrame_OpenToCategory("ShinyBuffs")
			InterfaceOptionsFrame_OpenToCategory("ShinyBuffs")
		end
	SLASH_SHINYBUFFS1 = "/shinybuffs"
	SLASH_SHINYBUFFS2 = "/sb"

	if db.allWhiteText then
		BUFF_DURATION_WARNING_TIME = 7200
	end
	BUFF_ROW_SPACING = 15
	BUFFS_PER_ROW = db.bprow
	
	C_Timer.After(.25, SkinAuras)
	SkinTench(true)

	--keep other stuff (like ticket frame) from moving buffs
	BuffFrame.NewSetPoint = BuffFrame.SetPoint
	BuffFrame.SetPoint = Position	
	Position()

	WhoCast()
	
	SB:UnregisterEvent("PLAYER_ENTERING_WORLD")
	SB:RegisterUnitEvent("UNIT_AURA", "player") 
	SB:SetScript("OnEvent", function(s,e,unit)
			SkinAuras()
			--don't bother checking if they're all skinned
			if numBuffsSkinned == BUFF_MAX_DISPLAY and numDebuffsSkinned == DEBUFF_MAX_DISPLAY then
				SB:UnregisterEvent("UNIT_AURA")
				SB:SetScript("OnEvent", nil)
			end
		end)
	PEW = nil
end

LSM:Register("border", "SB border", "Interface\\AddOns\\Roth_UI\\media\\5.tga")
LSM:Register("statusbar", "Solid", "Interface\\AddOns\\Roth_UI\\media\\Solid.tga")
LSM:Register("background", "Solid", "Interface\\AddOns\\Roth_UI\\media\\Solid.tga")

SB:SetScript("OnEvent", PEW)

SB:RegisterEvent("PLAYER_ENTERING_WORLD")
