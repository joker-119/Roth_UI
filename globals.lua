
local LSM = LibStub("LibSharedMedia-3.0")


roth_config = {}
roth_config.mediapath = "Interface\\AddOns\\Roth_UI\\media\\"

LSM:Register("font", "Cracked", roth_config.mediapath.."fonts\\Cracked-Narrow.ttf")
LSM:Register("font", "Exocet", roth_config.mediapath.."fonts\\Exocet-Light.ttf")

-- global font config
roth_config.font = {}
roth_config.font.base = LSM:Fetch("font", "Cracked")
roth_config.font.chat = LSM:Fetch("font", "Cracked")
roth_config.font.infostrings = LSM:Fetch("font", "Cracked")
roth_config.font.nameplates = LSM:Fetch("font", "Cracked")
roth_config.font.tooltips = LSM:Fetch("font", "Cracked")
