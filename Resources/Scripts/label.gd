extends Label

func _ready():
	if Global.is_melee == true:
		self.text = var_to_str(Global.melee_dmg)
	elif Global.arsenal[Global.weapon_index] == "schabowy":
		self.text = var_to_str(Global.schab_dmg)
	elif Global.arsenal[Global.weapon_index] == "chrupiaca":
		self.text = var_to_str(Global.chrupiaca_dmg)
