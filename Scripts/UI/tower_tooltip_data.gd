class_name TowerTooltipData
extends RefCounted

const TOWER_DETAILS := {
	&"guardian": {
		"name": "Cyber Guardian",
		"summary": "Mode-based guardian with defender, signal boost, and firewall roles.",
		"upgrade": "Switches guardian mode as knowledge unlocks passive boost and firewall utility.",
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
		"summary": "Global hunter that can target cloaked threats anywhere.",
		"upgrade": "Strengthens a global anti-virus shot that can see cloaked enemies.",
		"tooltip": "EDR Hunter\nTargets viruses globally, including cloaked threats. Best for catching leaks across the whole map."
	},
	&"siem": {
		"name": "SIEM Hawk",
		"summary": "Intel tower that can dispatch, freeze mode, and bank knowledge.",
		"upgrade": "Improves hawk combat stats and knowledge pressure.",
		"tooltip": "SIEM Hawk\nAttacks threats and can dispatch into Frozen Mode. Land it at HQ to bank extracted knowledge."
	},
	&"ips": {
		"name": "IPS Intrusion",
		"summary": "Path-control tower that manufactures damaging intrusion spikes.",
		"upgrade": "Improves spike factory pressure and path denial.",
		"tooltip": "IPS Intrusion\nPlaces spikes on the virus path. Spikes damage the next virus that crosses them."
	},
	&"honeypot": {
		"name": "Honeypot Production",
		"summary": "Economy support tower that generates Cyber Bucks near viruses.",
		"upgrade": "Improves production support while keeping overload pressure manageable.",
		"tooltip": "Honeypot Production\nGenerates Cyber Bucks while viruses are nearby. Collect when the pot fills, but avoid overloads."
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
	&"signal_boost": "Signal Boost Guardian\nPassive support mode. Boosts tower range, tower cooldown, and SIEM Hawk speed from Knowledge LV3 upward.",
	&"firewall": "Firewall Guardian\nPlaces a red firewall on the nearest path point. Viruses that cross it take hit damage and burn damage over time.",
	&"mode_three": "Future Guardian Mode\nReserved for an additional specialization."
}

const SIEM_DISPATCH_TOOLTIP := "Dispatch Hawk\nSends the SIEM Hawk into Frozen Mode so it can extract and bank knowledge."
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
