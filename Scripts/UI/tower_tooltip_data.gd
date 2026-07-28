class_name TowerTooltipData
extends RefCounted

const TOWER_DETAILS := {
	&"guardian": {
		"name": "Cyber Guardian",
		"summary": "Mode-based guardian with defender, signal boost, and firewall roles.",
		"upgrade": "All three Guardian modes are available from Knowledge LV1.",
		"tooltip": "Cyber Guardian\nDefender shoots visible viruses. Signal Boost is passive support. Firewall places a damaging burn wall on the path."
	},
	&"laser": {
		"name": "Laser Turret",
		"summary": "Reliable damage tower with scaling range and fire rate.",
		"upgrade": "Boosts laser damage, range, fire rate, and beam size.",
		"tooltip": "Laser Turret\nFires at viruses in range. Higher levels hit harder, reach farther, and shoot faster."
	},
	&"scanner": {
		"name": "IDS Scanner",
		"summary": "Support tower that reveals and disrupts viruses with selectable modes.",
		"upgrade": "Increases scan radius and unlocks additional scanner modes.",
		"tooltip": "IDS Scanner\nReveals cloaked Trojan horses. Upgrades unlock Burner, Bounty, Quarantine, and Nullifier modes."
	},
	&"edr": {
		"name": "EDR Hunter",
		"summary": "Global offense hunter that can engage visible threats anywhere.",
		"upgrade": "Strengthens its global anti-virus shot and unlocks patrol drones.",
		"tooltip": "EDR Hunter\nTargets visible viruses globally. Camouflaged threats must be revealed or nullified before the Hunter and its drones can engage them."
	},
	&"siem": {
		"name": "SIEM Hawk",
		"summary": "Mobile intel tower that travels to selected destinations, freezes, and banks knowledge.",
		"upgrade": "Improves hawk combat stats and knowledge pressure.",
		"tooltip": "SIEM Hawk\nEnter Destination Mode, then select a map location for the Hawk. Freeze it to scan in place or land at HQ to bank knowledge."
	},
	&"xdr": {
		"name": "XDR Mech",
		"summary": "Mobile response mech that walks to player-selected destinations.",
		"upgrade": "Levels 1-4 use the standard chassis; level 5 equips the reinforced head and legs.",
		"tooltip": "XDR Mech\nEnable Destination Mode, then select a map location. The mech turns toward the marker and walks there."
	},
	&"ips": {
		"name": "IPS Intrusion",
		"summary": "Path-control tower that manufactures damaging intrusion spikes.",
		"upgrade": "Each level adds 2 spike slots, 20% base range, and 15% production speed.",
		"tooltip": "IPS Intrusion\nPlaces spikes on the virus path. Spikes damage the next virus that crosses them."
	},
	&"honeypot": {
		"name": "Honeypot Production",
		"summary": "Economy support tower that banks Cyber Bucks and, from LV3, Knowledge Points.",
		"upgrade": "Adds 25% production speed and doubles Cyber Buck storage each level. LV3 unlocks Knowledge production.",
		"tooltip": "Honeypot Production\nGenerates Cyber Bucks while viruses are nearby and overloads immediately at 10 in range. Press it to collect its banks."
	}
}

const SCANNER_MODE_DETAILS := {
	&"camo": "Camo\nReveals cloaked Trojan horses so defenses can target them.",
	&"burner": "Burner\nDeals periodic burn damage to viruses inside the scan radius.",
	&"bounty": "Bounty\nAwards bonus Cyber Bucks when new viruses are scanned.",
	&"quarantine": "Quarantine\nSlows viruses while they remain inside scanner range.",
	&"nullifier": "Nullifier\nSuppresses special virus abilities while they are being scanned."
}

const GUARDIAN_MODE_DETAILS := {
	&"signal_boost": "Signal Boost Guardian\nPassive support mode. Available from Knowledge LV1; boosts tower range, tower cooldown, and SIEM Hawk speed.",
	&"firewall": "Firewall Guardian\nPlaces a red firewall on the nearest path point. Viruses that cross it take hit damage and burn damage over time.",
	&"mode_three": "Future Guardian Mode\nReserved for an additional specialization."
}

const SIEM_DISPATCH_TOOLTIP := "Destination Mode\nSelect a map location for the SIEM Hawk. A blue marker remains until it arrives."
const SIEM_LAND_TOOLTIP := "Land to Headquarters\nReturns the SIEM Hawk to HQ and stores banked knowledge."


static func tower_name(tower_id: StringName) -> String:
	return String(TOWER_DETAILS.get(tower_id, {}).get("name", "Tower"))


static func tower_summary(tower_id: StringName) -> String:
	return String(TOWER_DETAILS.get(tower_id, {}).get("summary", ""))


static func tower_upgrade_tooltip(tower_id: StringName) -> String:
	var details: Dictionary = TOWER_DETAILS.get(tower_id, {})
	return "%s\n%s" % [
		String(details.get("name", "Upgrade")),
		String(details.get("upgrade", "Upgrade this tower."))
	]


static func tower_tooltip(tower_id: StringName) -> String:
	return String(TOWER_DETAILS.get(tower_id, {}).get("tooltip", ""))


static func scanner_mode_tooltip(mode_id: StringName) -> String:
	return String(SCANNER_MODE_DETAILS.get(mode_id, "Scanner Mode\nChanges how the IDS Scanner supports your defense."))
