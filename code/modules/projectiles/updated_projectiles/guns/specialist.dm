//-------------------------------------------------------
//SNIPER RIFLES
//Keyword rifles. They are subtype of rifles, but still contained here as a specialist weapon.

//Because this parent type did not exist
//Note that this means that snipers will have a slowdown of 3, due to the scope
/obj/item/weapon/gun/rifle/sniper
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	gun_skill_category = GUN_SKILL_SPEC
	wield_delay = WIELD_DELAY_SLOW

//Pow! Headshot

/obj/item/weapon/gun/rifle/sniper/M42A
	name = "\improper M42A scoped rifle"
	desc = "A heavy sniper rifle manufactured by Armat Systems. It has a scope system and fires armor penetrating rounds out of a 15-round magazine.\n'Peace Through Superior Firepower'"
	icon_state = "m42a"
	item_state = "m42a"
	origin_tech = "combat=6;materials=5"
	fire_sound = 'sound/weapons/gun_sniper.ogg'
	current_mag = /obj/item/ammo_magazine/sniper
	force = 12
	wield_delay = 12 //Ends up being 1.6 seconds due to scope
	zoomdevicename = "scope"
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 12, "rail_y" = 20, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)
	var/targetlaser_on = FALSE
	var/targetlaser_primed = FALSE
	var/mob/living/carbon/laser_target = null
	var/image/LT = null
	attachable_allowed = list(
                        /obj/item/attachable/bipod,
                        /obj/item/attachable/lasersight,
                        )

	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY
	starting_attachment_types = list(/obj/item/attachable/scope/m42a, /obj/item/attachable/sniperbarrel)

/obj/item/weapon/gun/rifle/sniper/M42A/Initialize()
	select_gamemode_skin(type, list(MAP_ICE_COLONY = "s_m42a"))
	. = ..()
	LT = image("icon" = 'icons/obj/items/projectiles.dmi',"icon_state" = "sniper_laser", "layer" =-LASER_LAYER)

/obj/item/weapon/gun/rifle/sniper/M42A/Fire(atom/target, mob/living/user, params, reflex = 0, dual_wield)
	if(!able_to_fire(user))
		return
	if(targetlaser_primed)
		if(!iscarbon(target))
			return
		if(laser_target)
			laser_target.remove_laser()
		laser_target = target
		to_chat(user, "<span class='danger'>You focus your targeting laser on [target]!</span>")
		targetlaser_primed = FALSE
		laser_target.apply_laser()
		STOP_PROCESSING(SSobj, src) //So we don't accumulate additional processing.
		START_PROCESSING(SSobj, src)
		return
	return ..()


/mob/living/carbon/proc/apply_laser()
	return FALSE

/mob/living/carbon/human/apply_laser()
	overlays_standing[LASER_LAYER] = image("icon" = 'icons/obj/items/projectiles.dmi',"icon_state" = "sniper_laser", "layer" =-LASER_LAYER)
	apply_overlay(LASER_LAYER)

/mob/living/carbon/Xenomorph/apply_laser()
	overlays_standing[X_LASER_LAYER] = image("icon" = 'icons/obj/items/projectiles.dmi',"icon_state" = "sniper_laser", "layer" =-X_LASER_LAYER)
	apply_overlay(X_LASER_LAYER)

/mob/living/carbon/monkey/apply_laser()
	overlays_standing[M_LASER_LAYER] = image("icon" = 'icons/obj/items/projectiles.dmi',"icon_state" = "sniper_laser", "layer" =-M_LASER_LAYER)
	apply_overlay(M_LASER_LAYER)


/mob/living/carbon/proc/remove_laser()
	return FALSE

/mob/living/carbon/human/remove_laser()
	remove_overlay(LASER_LAYER)

/mob/living/carbon/Xenomorph/remove_laser()
	remove_overlay(X_LASER_LAYER)

/mob/living/carbon/monkey/remove_laser()
	remove_overlay(M_LASER_LAYER)


/obj/item/weapon/gun/rifle/sniper/M42A/unique_action(mob/user)
	if(!targetlaser_on)
		laser_on(user)

	else if(zoom)
		laser_off(user)

/obj/item/weapon/gun/rifle/sniper/M42A/Destroy()
	laser_off()
	. = ..()

/obj/item/weapon/gun/rifle/sniper/M42A/dropped()
	laser_off()
	. = ..()

/obj/item/weapon/gun/rifle/sniper/M42A/process()
	if(!zoom)
		laser_off()
		return
	var/mob/living/user = loc
	if(!isliving(user) )
		laser_off()
		return
	if(!laser_target)
		laser_off(user, FALSE)
		return
	if(!can_see(user, laser_target, length=23))
		laser_off(user, FALSE)
		to_chat(user, "<span class='danger'>You lose sight of your target!</span>")

/obj/item/weapon/gun/rifle/sniper/M42A/zoom(mob/living/user, tileoffset = 11, viewsize = 12) //tileoffset is client view offset in the direction the user is facing. viewsize is how far out this thing zooms. 7 is normal view
	. = ..()
	if(!zoom && targetlaser_on)
		laser_off(user)

/atom/proc/sniper_target(atom/A)
	return FALSE

/obj/item/weapon/gun/rifle/sniper/M42A/sniper_target(atom/A)
	if(!laser_target)
		return FALSE
	if(A == laser_target)
		return laser_target
	else
		return TRUE

/obj/item/weapon/gun/rifle/sniper/M42A/proc/laser_on(mob/user, silent = FALSE)
	if(!zoom) //Can only use and prime the laser targeter when zoomed.
		if(!silent)
			to_chat(user, "<span class='warning'>You must be zoomed in to use your targeting laser!</span>")
		return
	targetlaser_primed = TRUE //We prime the target laser
	if(!silent && user)
		to_chat(user, "<span class='notice'><b>You activate your targeting laser and take careful aim.</b></span>")
		playsound(user,'sound/machines/click.ogg', 25, 1)
	if(targetlaser_on) //if the laser is already on, we don't double dip.
		return
	targetlaser_on = TRUE
	accuracy_mult += CONFIG_GET(number/combat_define/max_hit_accuracy_mult) //We get a big accuracy bonus vs the lasered target


/obj/item/weapon/gun/rifle/sniper/M42A/proc/laser_off(mob/user, toggle_off = TRUE, silent = FALSE)
	if(laser_target)
		laser_target.remove_laser()
	laser_target = null
	STOP_PROCESSING(SSobj, src)
	if(toggle_off && targetlaser_on) //sanity check
		targetlaser_on = FALSE
		accuracy_mult -= CONFIG_GET(number/combat_define/max_hit_accuracy_mult) //We lose a big accuracy bonus vs the now unlasered target
		if(!silent && user)
			to_chat(user, "<span class='notice'><b>You deactivate your targeting laser.</b></span>")
			playsound(user,'sound/machines/click.ogg', 25, 1)

/obj/item/weapon/gun/rifle/sniper/M42A/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/high_fire_delay) * 5
	burst_amount = CONFIG_GET(number/combat_define/min_burst_value)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) + CONFIG_GET(number/combat_define/max_hit_accuracy_mult)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/min_recoil_value)


/obj/item/weapon/gun/rifle/sniper/M42A/jungle //These really should just be skins.
	name = "\improper M42A marksman rifle"
	icon_state = "m_m42a" //NO BACK STATE
	item_state = "m_m42a"


/obj/item/weapon/gun/rifle/sniper/elite
	name = "\improper M42C anti-tank sniper rifle"
	desc = "A high end mag-rail heavy sniper rifle from Nanotrasen chambered in the heaviest ammo available, 10x99mm Caseless."
	icon_state = "m42c"
	item_state = "m42c" //NEEDS A TWOHANDED STATE
	origin_tech = "combat=7;materials=5"
	fire_sound = 'sound/weapons/sniper_heavy.ogg'
	current_mag = /obj/item/ammo_magazine/sniper/elite
	force = 17
	zoomdevicename = "scope"
	attachable_allowed = list()
	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 18,"rail_x" = 15, "rail_y" = 19, "under_x" = 20, "under_y" = 15, "stock_x" = 20, "stock_y" = 15)
	starting_attachment_types = list(/obj/item/attachable/scope/pmc, /obj/item/attachable/sniperbarrel)

/obj/item/weapon/gun/rifle/sniper/elite/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/high_fire_delay) * 5
	burst_amount = CONFIG_GET(number/combat_define/min_burst_value)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) + CONFIG_GET(number/combat_define/max_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/low_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/max_recoil_value)

/obj/item/weapon/gun/rifle/sniper/elite/simulate_recoil(total_recoil = 0, mob/user, atom/target)
	. = ..()
	if(.)
		var/mob/living/carbon/human/PMC_sniper = user
		if(PMC_sniper.lying == 0 && !istype(PMC_sniper.wear_suit,/obj/item/clothing/suit/storage/marine/smartgunner/veteran/PMC) && !istype(PMC_sniper.wear_suit,/obj/item/clothing/suit/storage/marine/veteran))
			PMC_sniper.visible_message("<span class='warning'>[PMC_sniper] is blown backwards from the recoil of the [src]!</span>","<span class='highdanger'>You are knocked prone by the blowback!</span>")
			step(PMC_sniper,turn(PMC_sniper.dir,180))
			PMC_sniper.KnockDown(5)

//SVD //Based on the actual Dragunov sniper rifle.

/obj/item/weapon/gun/rifle/sniper/svd
	name = "\improper SVD Dragunov-033 sniper rifle"
	desc = "A sniper variant of the MAR-40 rifle, with a new stock, barrel, and scope. It doesn't have the punch of modern sniper rifles, but it's finely crafted in 2133 by someone probably illiterate. Fires 7.62x54mmR rounds."
	icon_state = "svd003"
	item_state = "svd003" //NEEDS A ONE HANDED STATE
	origin_tech = "combat=5;materials=3;syndicate=5"
	fire_sound = 'sound/weapons/gun_kt42.ogg'
	current_mag = /obj/item/ammo_magazine/sniper/svd
	type_of_casings = "cartridge"
	attachable_allowed = list(
						/obj/item/attachable/reddot,
						/obj/item/attachable/verticalgrip,
						/obj/item/attachable/gyro,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/bipod,
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/scope/slavic)

	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 17,"rail_x" = 13, "rail_y" = 19, "under_x" = 24, "under_y" = 13, "stock_x" = 20, "stock_y" = 14)
	starting_attachment_types = list(/obj/item/attachable/scope/slavic, /obj/item/attachable/slavicbarrel, /obj/item/attachable/stock/slavic)

/obj/item/weapon/gun/rifle/sniper/svd/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/mhigh_fire_delay) * 2
	burst_amount = CONFIG_GET(number/combat_define/low_burst_value)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) - CONFIG_GET(number/combat_define/low_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/low_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/min_recoil_value)



//M4RA marksman rifle

/obj/item/weapon/gun/rifle/m4ra
	name = "\improper M4RA battle rifle"
	desc = "The M4RA battle rifle is a designated marksman rifle in service with the TGMC. Only fielded in small numbers, and sporting a bullpup configuration, the M4RA battle rifle is perfect for reconnaissance and fire support teams.\nIt is equipped with rail scope and takes 10x24mm A19 high velocity magazines."
	icon_state = "m41b"
	item_state = "m4ra" //PLACEHOLDER
	origin_tech = "combat=5;materials=4"
	fire_sound = list('sound/weapons/gun_m4ra.ogg')
	current_mag = /obj/item/ammo_magazine/rifle/m4ra
	force = 16
	attachable_allowed = list(
						/obj/item/attachable/suppressor,
						/obj/item/attachable/verticalgrip,
						/obj/item/attachable/angledgrip,
						/obj/item/attachable/bipod,
						/obj/item/attachable/compensator)

	flags_gun_features = GUN_AUTO_EJECTOR|GUN_WIELDED_FIRING_ONLY
	gun_skill_category = GUN_SKILL_SPEC
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 17,"rail_x" = 12, "rail_y" = 23, "under_x" = 23, "under_y" = 13, "stock_x" = 24, "stock_y" = 13)
	starting_attachment_types = list(/obj/item/attachable/scope/m4ra, /obj/item/attachable/stock/rifle/marksman)

/obj/item/weapon/gun/rifle/m4ra/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/high_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/med_burst_value)
	burst_delay = CONFIG_GET(number/combat_define/mlow_fire_delay)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/low_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/min_recoil_value)

//-------------------------------------------------------
//SMARTGUN

//Come get some.
/obj/item/weapon/gun/smartgun
	name = "\improper M56B smartgun"
	desc = "The actual firearm in the 4-piece M56B Smartgun System. Essentially a heavy, mobile machinegun.\nReloading is a cumbersome process requiring a powerpack. Click the powerpack icon in the top left to reload.\nYou may toggle firing restrictions by using a special action."
	icon_state = "m56"
	item_state = "m56"
	origin_tech = "combat=6;materials=5"
	fire_sound = "gun_smartgun"
	current_mag = /obj/item/ammo_magazine/internal/smartgun
	flags_equip_slot = NOFLAGS
	w_class = 5
	force = 20
	wield_delay = 16
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	var/datum/ammo/ammo_secondary = /datum/ammo/bullet/smartgun/lethal//Toggled ammo type
	var/shells_fired_max = 50 //Smartgun only; once you fire # of shells, it will attempt to reload automatically. If you start the reload, the counter resets.
	var/shells_fired_now = 0 //The actual counter used. shells_fired_max is what it is compared to.
	var/restriction_toggled = 1 //Begin with the safety on.
	gun_skill_category = GUN_SKILL_SMARTGUN
	attachable_allowed = list(
						/obj/item/attachable/extended_barrel,
						/obj/item/attachable/heavy_barrel,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/burstfire_assembly,
						/obj/item/attachable/bipod)

	flags_gun_features = GUN_INTERNAL_MAG|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	starting_attachment_types = list(/obj/item/attachable/flashlight)
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 16,"rail_x" = 17, "rail_y" = 17, "under_x" = 22, "under_y" = 14, "stock_x" = 22, "stock_y" = 14)

/obj/item/weapon/gun/smartgun/Initialize()
	. = ..()
	ammo_secondary = GLOB.ammo_list[ammo_secondary]

/obj/item/weapon/gun/smartgun/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/low_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/med_burst_value)
	burst_delay = CONFIG_GET(number/combat_define/min_fire_delay)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) + CONFIG_GET(number/combat_define/min_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	damage_falloff_mult = CONFIG_GET(number/combat_define/med_damage_falloff_mult)

/obj/item/weapon/gun/smartgun/examine(mob/user)
	. = ..()
	to_chat(user, "[current_mag.current_rounds ? "Ammo counter shows [current_mag.current_rounds] round\s remaining." : "It's dry."]")
	to_chat(user, "The restriction system is [restriction_toggled ? "<B>on</b>" : "<B>off</b>"].")

/obj/item/weapon/gun/smartgun/unique_action(mob/user)
	toggle_restriction(user)

/obj/item/weapon/gun/smartgun/able_to_fire(mob/living/user)
	. = ..()
	if(.)
		if(!ishuman(user))
			return FALSE
		var/mob/living/carbon/human/H = user
		if(!istype(H.wear_suit,/obj/item/clothing/suit/storage/marine/smartgunner) || !istype(H.back,/obj/item/smartgun_powerpack))
			click_empty(H)
			return FALSE

/obj/item/weapon/gun/smartgun/load_into_chamber(mob/user)
//	if(active_attachable) active_attachable = null
	return ready_in_chamber()

/obj/item/weapon/gun/smartgun/reload_into_chamber(mob/user)
	var/mob/living/carbon/human/smart_gunner = user
	var/obj/item/smartgun_powerpack/power_pack = smart_gunner.back
	if(istype(power_pack)) //I don't know how it would break, but it is possible.
		if(shells_fired_now >= shells_fired_max && power_pack.rounds_remaining > 0) // If shells fired exceeds shells needed to reload, and we have ammo.
			auto_reload(smart_gunner, power_pack)
		else shells_fired_now++

	return current_mag.current_rounds

/obj/item/weapon/gun/smartgun/delete_bullet(obj/item/projectile/projectile_to_fire, refund = 0)
	qdel(projectile_to_fire)
	if(refund) current_mag.current_rounds++
	return 1

/obj/item/weapon/gun/smartgun/proc/toggle_restriction(mob/user)
	to_chat(user, "[icon2html(src, user)] You [restriction_toggled? "<B>disable</b>" : "<B>enable</b>"] the [src]'s fire restriction. You will [restriction_toggled ? "harm anyone in your way" : "target through IFF"].")
	playsound(loc,'sound/machines/click.ogg', 25, 1)
	var/A = ammo
	ammo = ammo_secondary
	ammo_secondary = A
	restriction_toggled = !restriction_toggled

/obj/item/weapon/gun/smartgun/proc/auto_reload(mob/smart_gunner, obj/item/smartgun_powerpack/power_pack)
	set waitfor = 0
	sleep(5)
	if(power_pack && power_pack.loc)
		power_pack.attack_self(smart_gunner, TRUE)

/obj/item/weapon/gun/smartgun/get_ammo_type()
	if(!ammo)
		return list("unknown", "unknown")
	else
		return list(ammo.hud_state, ammo.hud_state_empty)

/obj/item/weapon/gun/smartgun/get_ammo_count()
	if(!current_mag)
		return 0
	else
		return current_mag.current_rounds


/obj/item/weapon/gun/smartgun/dirty
	name = "\improper M56D 'dirty' smartgun"
	desc = "The actual firearm in the 4-piece M56D Smartgun System. If you have this, you're about to bring some serious pain to anyone in your way.\nYou may toggle firing restrictions by using a special action."
	origin_tech = "combat=7;materials=5"
	current_mag = /obj/item/ammo_magazine/internal/smartgun/dirty
	ammo_secondary = /datum/ammo/bullet/smartgun/dirty/lethal
	attachable_allowed = list() //Cannot be upgraded.
	flags_gun_features = GUN_INTERNAL_MAG|GUN_WIELDED_FIRING_ONLY

/obj/item/weapon/gun/smartgun/dirty/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/low_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/med_burst_value)
	burst_delay = CONFIG_GET(number/combat_define/min_fire_delay)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) + CONFIG_GET(number/combat_define/min_hit_accuracy_mult) + CONFIG_GET(number/combat_define/min_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)


//-------------------------------------------------------
//GRENADE LAUNCHER

/obj/item/weapon/gun/launcher/m92
	name = "\improper M92 grenade launcher"
	desc = "A heavy, 6-shot grenade launcher used by the TerraGov Marine Corps for area denial and big explosions."
	icon_state = "m92"
	item_state = "m92" //NEED TWO HANDED SPRITE
	origin_tech = "combat=5;materials=5"
	matter = list("metal" = 6000)
	w_class = 4.0
	throw_speed = 2
	throw_range = 10
	force = 5.0
	wield_delay = 8
	fire_sound = 'sound/weapons/gun_m92_attachable.ogg'
	cocked_sound = 'sound/weapons/gun_m92_cocked.ogg'
	var/list/grenades = list()
	var/max_grenades = 6
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	attachable_allowed = list(
						/obj/item/attachable/magnetic_harness)

	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	gun_skill_category = GUN_SKILL_SPEC
	var/datum/effect_system/smoke_spread/smoke
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 14, "rail_y" = 22, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)

/obj/item/weapon/gun/launcher/m92/Initialize()
	. = ..()
	for(var/i in 1 to 6)
		grenades += new /obj/item/explosive/grenade/frag(src)

/obj/item/weapon/gun/launcher/m92/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/tacshottie_fire_delay)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	accuracy_mult_unwielded = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	scatter_unwielded = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)


/obj/item/weapon/gun/launcher/m92/examine(mob/user)
	. = ..()
	if(grenades.len)
		if(get_dist(user, src) > 2 && user != loc)
			return
		to_chat(user, "<span class='notice'> It is loaded with <b>[grenades.len] / [max_grenades]</b> grenades.</span>")


/obj/item/weapon/gun/launcher/m92/attackby(obj/item/I, mob/user)
	if((istype(I, /obj/item/explosive/grenade)))
		if(grenades.len < max_grenades)
			if(user.transferItemToLoc(I, src))
				grenades += I
				playsound(user, 'sound/weapons/gun_shotgun_shell_insert.ogg', 25, 1)
				to_chat(user, "<span class='notice'>You put [I] in the grenade launcher.</span>")
				to_chat(user, "<span class='info'>Now storing: [grenades.len] / [max_grenades] grenades.</span>")
		else
			to_chat(user, "<span class='warning'>The grenade launcher cannot hold more grenades!</span>")

	else if(istype(I,/obj/item/attachable))
		if(check_inactive_hand(user))
			attach_to_gun(user,I)


/obj/item/weapon/gun/launcher/m92/afterattack(atom/target, mob/user, flag)
	if(user.mind?.cm_skills && user.mind.cm_skills.spec_weapons < 0)
		if(!do_after(user, 8, TRUE, 5, BUSY_ICON_HOSTILE))
			return
	if(able_to_fire(user))
		if(get_dist(target,user) <= 2)
			to_chat(user, "<span class='warning'>The grenade launcher beeps a warning noise. You are too close!</span>")
			return
		if(grenades.len)
			fire_grenade(target,user)
			var/obj/screen/ammo/A = user.hud_used.ammo
			A.update_hud(user)
		else
			to_chat(user, "<span class='warning'>The grenade launcher is empty.</span>")


//Doesn't use most of any of these. Listed for reference.
/obj/item/weapon/gun/launcher/m92/load_into_chamber()
	return


/obj/item/weapon/gun/launcher/m92/reload_into_chamber()
	return


/obj/item/weapon/gun/launcher/m92/unload(mob/user)
	if(grenades.len)
		var/obj/item/explosive/grenade/nade = grenades[grenades.len] //Grab the last one.
		if(user)
			user.put_in_hands(nade)
			playsound(user, unload_sound, 25, 1)
		else
			nade.loc = get_turf(src)
		grenades -= nade
	else
		to_chat(user, "<span class='warning'>It's empty!</span>")


/obj/item/weapon/gun/launcher/m92/proc/fire_grenade(atom/target, mob/user)
	playsound(user.loc, cocked_sound, 25, 1)
	last_fired = world.time
	for(var/mob/O in viewers(world.view, user))
		O.show_message(text("<span class='danger'>[] fired a grenade!</span>", user), 1)
	to_chat(user, "<span class='warning'>You fire the grenade launcher!</span>")
	var/obj/item/explosive/grenade/F = grenades[1]
	grenades -= F
	F.loc = user.loc
	F.throw_range = 20
	if(F?.loc) //Apparently it can get deleted before the next thing takes place, so it runtimes.
		log_explosion("[key_name(user)] fired a grenade [F] from [src] at [AREACOORD(user.loc)].")
		log_combat(user, name, "fired a grenade [F] from ")
		F.det_time = min(10, F.det_time)
		F.launched = TRUE
		F.throwforce += F.launchforce //Throws with signifcantly more force than a standard marine can.
		F.throw_at(target, 20, 3, user)
		F.activate()
		playsound(F.loc, fire_sound, 50, 1)

/obj/item/weapon/gun/launcher/m92/get_ammo_type()
	if(length(grenades) == 0)
		return list("empty", "empty")
	else
		return list(grenades[1].hud_state, grenades[1].hud_state_empty)

/obj/item/weapon/gun/launcher/m92/get_ammo_count()
	return length(grenades)


/obj/item/weapon/gun/launcher/m81
	name = "\improper M81 grenade launcher"
	desc = "A lightweight, single-shot grenade launcher used by the TerraGov Marine Corps for area denial and big explosions."
	icon_state = "m81"
	item_state = "m81"
	origin_tech = "combat=5;materials=5"
	matter = list("metal" = 7000)
	w_class = 4.0
	throw_speed = 2
	throw_range = 10
	force = 5.0
	wield_delay = WIELD_DELAY_VERY_FAST
	fire_sound = 'sound/weapons/armbomb.ogg'
	cocked_sound = 'sound/weapons/gun_m92_cocked.ogg'
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	gun_skill_category = GUN_SKILL_SPEC
	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_WIELDED_FIRING_ONLY
	attachable_allowed = list()
	var/grenade
	var/grenade_type_allowed = /obj/item/explosive/grenade
	var/riot_version
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 14, "rail_y" = 22, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)

/obj/item/weapon/gun/launcher/m81/Initialize(loc, spawn_empty)
	. = ..()
	if(!spawn_empty)
		if(riot_version)
			grenade = new /obj/item/explosive/grenade/chem_grenade/teargas(src)
		else
			grenade = new /obj/item/explosive/grenade/frag(src)

/obj/item/weapon/gun/launcher/m81/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/max_fire_delay) * 1.5
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)


/obj/item/weapon/gun/launcher/m81/examine(mob/user)
	. = ..()
	if(grenade)
		if(get_dist(user, src) > 2 && user != loc)
			return
		to_chat(user, "<span class='notice'> It is loaded with a grenade.</span>")


/obj/item/weapon/gun/launcher/m81/attackby(obj/item/I, mob/user)
	if((istype(I, /obj/item/explosive/grenade)))
		if((istype(I, grenade_type_allowed)))
			if(!grenade)
				if(user.transferItemToLoc(I, src))
					grenade = I
					to_chat(user, "<span class='notice'>You put [I] in the grenade launcher.</span>")
			else
				to_chat(user, "<span class='warning'>The grenade launcher cannot hold more grenades!</span>")
		else
			to_chat(user, "<span class='warning'>[src] can't use this type of grenade!</span>")

	else if(istype(I,/obj/item/attachable))
		if(check_inactive_hand(user)) attach_to_gun(user,I)


/obj/item/weapon/gun/launcher/m81/afterattack(atom/target, mob/user, flag)
	if(able_to_fire(user))
		if(get_dist(target,user) <= 2)
			to_chat(user, "<span class='warning'>The grenade launcher beeps a warning noise. You are too close!</span>")
			return
		if(grenade)
			fire_grenade(target,user)
			playsound(user.loc, cocked_sound, 25, 1)
		else
			to_chat(user, "<span class='warning'>The grenade launcher is empty.</span>")

//Doesn't use most of any of these. Listed for reference.
/obj/item/weapon/gun/launcher/m81/load_into_chamber()
	return


/obj/item/weapon/gun/launcher/m81/reload_into_chamber()
	return


/obj/item/weapon/gun/launcher/m81/unload(mob/user)
	if(grenade)
		var/obj/item/explosive/grenade/nade = grenade
		if(user)
			user.put_in_hands(nade)
			playsound(user, unload_sound, 25, 1)
		else nade.loc = get_turf(src)
		grenade = null
	else
		to_chat(user, "<span class='warning'>It's empty!</span>")


/obj/item/weapon/gun/launcher/m81/proc/fire_grenade(atom/target, mob/user)
	set waitfor = 0
	last_fired = world.time
	user.visible_message("<span class='danger'>[user] fired a grenade!</span>", \
						 "<span class='warning'>You fire the grenade launcher!</span>")
	var/obj/item/explosive/grenade/F = grenade
	grenade = null
	F.loc = user.loc
	F.throw_range = 20
	F.throw_at(target, 20, 2, user)
	if(F && F.loc) //Apparently it can get deleted before the next thing takes place, so it runtimes.
		log_game("[key_name(user)] fired a grenade [F.name] from \a [name] at [AREACOORD(user.loc)].")
		message_admins("[ADMIN_TPMONTY(user)] fired a grenade [F.name] from \a [name].")
		F.icon_state = initial(F.icon_state) + "_active"
		F.active = 1
		F.updateicon()
		playsound(F.loc, fire_sound, 50, 1)
		sleep(10)
		if(F?.loc)
			F.prime()


/obj/item/weapon/gun/launcher/m81/riot
	name = "\improper M81 riot grenade launcher"
	desc = "A lightweight, single-shot grenade launcher to launch tear gas grenades. Used by the TerraGov Marine Corps Military Police during riots."
	grenade_type_allowed = /obj/item/explosive/grenade/chem_grenade
	riot_version = TRUE
	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_POLICE|GUN_WIELDED_FIRING_ONLY
	req_access = list(ACCESS_MARINE_BRIG)




//-------------------------------------------------------
//M5 RPG

/obj/item/weapon/gun/launcher/rocket
	name = "\improper M5 RPG"
	desc = "The M5 RPG is the primary anti-armor weapon of the TGMC. Used to take out light-tanks and enemy structures, the M5 RPG is a dangerous weapon with a variety of combat uses."
	icon_state = "m5"
	item_state = "m5"
	origin_tech = "combat=6;materials=5"
	matter = list("metal" = 10000)
	current_mag = /obj/item/ammo_magazine/rocket
	flags_equip_slot = NOFLAGS
	w_class = 5
	force = 15
	wield_delay = 12
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	attachable_allowed = list(
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/scope/mini)

	flags_gun_features = GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	gun_skill_category = GUN_SKILL_SPEC
	reload_sound = 'sound/weapons/gun_mortar_reload.ogg'
	var/datum/effect_system/smoke_spread/smoke
	unload_sound = 'sound/weapons/gun_mortar_reload.ogg'
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 6, "rail_y" = 19, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)

/obj/item/weapon/gun/launcher/rocket/Initialize()
	. = ..()
	smoke = new()
	smoke.attach(src)


/obj/item/weapon/gun/launcher/rocket/Fire(atom/target, mob/living/user, params, reflex = 0, dual_wield)
	if(!able_to_fire(user))
		return

	var/delay = 3
	if(has_attachment(/obj/item/attachable/scope/mini))
		delay += 3

	if(user.mind?.cm_skills && user.mind.cm_skills.spec_weapons < 0)
		delay += 6

	if(!do_after(user, delay, TRUE, 3, BUSY_ICON_HOSTILE, null, TRUE)) //slight wind up
		return

	playsound(loc,'sound/weapons/gun_mortar_fire.ogg', 50, 1)
	. = ..()


	//loaded_rocket.current_rounds = max(loaded_rocket.current_rounds - 1, 0)

	if(!current_mag.current_rounds)
		current_mag.loc = get_turf(src)
		current_mag.update_icon()
		current_mag = null

	log_combat(usr, usr, "fired the [src].")
	log_explosion("[usr] fired the [src] at [AREACOORD(loc)].")

/obj/item/weapon/gun/launcher/rocket/wield(mob/living/user)
	. = ..()
	if(user.mind?.cm_skills && user.mind.cm_skills.spec_weapons < 0)
		do_after(user, 15, TRUE, 5, BUSY_ICON_HOSTILE)


/obj/item/weapon/gun/launcher/rocket/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/high_fire_delay) * 2
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/med_recoil_value)


/obj/item/weapon/gun/launcher/rocket/examine(mob/user)
	. = ..()
	if(current_mag.current_rounds)
		to_chat(user, "It's ready to rocket.")
	else
		to_chat(user, "It's empty.")


/obj/item/weapon/gun/launcher/rocket/load_into_chamber(mob/user)
//	if(active_attachable) active_attachable = null
	return ready_in_chamber()


//No such thing
/obj/item/weapon/gun/launcher/rocket/reload_into_chamber(mob/user)
	return TRUE


/obj/item/weapon/gun/launcher/rocket/delete_bullet(obj/item/projectile/projectile_to_fire, refund = FALSE)
	qdel(projectile_to_fire)
	if(refund)
		current_mag.current_rounds++
	return TRUE

/obj/item/weapon/gun/launcher/rocket/unload(mob/user)
	if(!user)
		return
	if(!current_mag || current_mag.loc != src)
		to_chat(user, "<span class='warning'>[src] is already empty!</span>")
		return
	to_chat(user, "<span class='notice'>You begin unloading [src].</span>")
	if(!do_after(user,current_mag.reload_delay * 0.5, TRUE, 5, BUSY_ICON_FRIENDLY))
		to_chat(user, "<span class='warning'>Your unloading was interrupted!</span>")
		return
	if(!user) //If we want to drop it on the ground or there's no user.
		current_mag.loc = get_turf(src) //Drop it on the ground.
	else
		user.put_in_hands(current_mag)

	playsound(user, unload_sound, 25, 1, 5)
	user.visible_message("<span class='notice'>[user] unloads [current_mag] from [src].</span>",
	"<span class='notice'>You unload [current_mag] from [src].</span>", null, 4)
	current_mag.update_icon()
	current_mag = null

//Adding in the rocket backblast. The tile behind the specialist gets blasted hard enough to down and slightly wound anyone
/obj/item/weapon/gun/launcher/rocket/apply_bullet_effects(obj/item/projectile/projectile_to_fire, mob/user, i = 1, reflex = 0)

	var/backblast_loc = get_turf(get_step(user.loc, turn(user.dir, 180)))
	smoke.set_up(1, 0, backblast_loc, turn(user.dir, 180))
	smoke.start()
	for(var/mob/living/carbon/C in backblast_loc)
		if(!C.lying) //Have to be standing up to get the fun stuff
			C.adjustBruteLoss(15) //The shockwave hurts, quite a bit. It can knock unarmored targets unconscious in real life
			C.Stun(4) //For good measure
			C.emote("pain")

		. = ..()

/obj/item/weapon/gun/launcher/rocket/get_ammo_type()
	if(!ammo)
		return list("unknown", "unknown")
	else
		return list(ammo.hud_state, ammo.hud_state_empty)

/obj/item/weapon/gun/launcher/rocket/get_ammo_count()
	if(!current_mag)
		return 0
	else
		return current_mag.current_rounds

//-------------------------------------------------------
//M5 RPG'S MEAN FUCKING COUSIN

/obj/item/weapon/gun/launcher/rocket/m57a4
	name = "\improper M57-A4 'Lightning Bolt' quad thermobaric launcher"
	desc = "The M57-A4 'Lightning Bolt' is posssibly the most destructive man-portable weapon ever made. It is a 4-barreled missile launcher capable of burst-firing 4 thermobaric missiles. Enough said."
	icon_state = "m57a4"
	item_state = "m57a4"
	origin_tech = "combat=7;materials=5"
	current_mag = /obj/item/ammo_magazine/rocket/m57a4
	aim_slowdown = SLOWDOWN_ADS_SUPERWEAPON
	attachable_allowed = list()
	flags_gun_features = GUN_WIELDED_FIRING_ONLY


/obj/item/weapon/gun/launcher/rocket/m57a4/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/mhigh_fire_delay)
	burst_delay = CONFIG_GET(number/combat_define/med_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/high_burst_value)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) - CONFIG_GET(number/combat_define/med_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/med_recoil_value)

//-------------------------------------------------------

//-------------------------------------------------------
//SCOUT SHOTGUN

/obj/item/weapon/gun/shotgun/merc/scout
	name = "\improper ZX-76 assault shotgun"
	desc = "The MIC ZX-76 Assault Shotgun, a dobule barreled semi-automatic combat shotgun with a twin shot mode. Has a 9 round internal magazine."
	icon_state = "zx-76"
	item_state = "zx-76"
	origin_tech = "combat=5;materials=4"
	fire_sound = 'sound/weapons/gun_shotgun_automatic.ogg'
	current_mag = /obj/item/ammo_magazine/internal/shotgun/scout
	gun_skill_category = GUN_SKILL_SPEC
	attachable_allowed = list(
						/obj/item/attachable/bayonet,
						/obj/item/attachable/reddot,
						/obj/item/attachable/verticalgrip,
						/obj/item/attachable/angledgrip,
						/obj/item/attachable/gyro,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/extended_barrel,
						/obj/item/attachable/compensator,
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/lasersight,
						/obj/item/attachable/attached_gun/flamer,
						/obj/item/attachable/attached_gun/shotgun,
						/obj/item/attachable/attached_gun/grenade)
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 17,"rail_x" = 8, "rail_y" = 18, "under_x" = 24, "under_y" = 12, "stock_x" = 13, "stock_y" = 15)
	starting_attachment_types = list(/obj/item/attachable/stock/scout)

/obj/item/weapon/gun/shotgun/merc/scout/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/scoutshottie_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/low_burst_value)
	burst_delay = CONFIG_GET(number/combat_define/no_fire_delay) //basically instantaneous two shots
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	accuracy_mult_unwielded = CONFIG_GET(number/combat_define/base_hit_accuracy_mult) - CONFIG_GET(number/combat_define/max_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	scatter_unwielded = CONFIG_GET(number/combat_define/max_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/low_recoil_value)
	recoil_unwielded = CONFIG_GET(number/combat_define/high_recoil_value)

//-------------------------------------------------------
//This gun is very powerful, but also has a kick.

/obj/item/weapon/gun/minigun
	name = "\improper MIC-A7 Vindicator Minigun"
	desc = "It's a damn minigun! The ultimate in man-portable firepower, spraying countless high velocity armor piercing rounds with a rotary action, this thing will no doubt pack a punch."
	icon_state = "painless"
	item_state = "painless"
	origin_tech = "combat=7;materials=5"
	fire_sound = 'sound/weapons/gun_minigun.ogg'
	cocked_sound = 'sound/weapons/gun_minigun_cocked.ogg'
	current_mag = /obj/item/ammo_magazine/minigun
	type_of_casings = "cartridge"
	w_class = 5
	force = 20
	wield_delay = 15
	gun_skill_category = GUN_SKILL_SPEC
	aim_slowdown = SLOWDOWN_ADS_RIFLE
	flags_gun_features = GUN_AUTO_EJECTOR|GUN_CAN_POINTBLANK|GUN_BURST_ON|GUN_WIELDED_FIRING_ONLY|GUN_LOAD_INTO_CHAMBER|GUN_AMMO_COUNTER
	attachable_allowed = list(
						/obj/item/attachable/flashlight,
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/gyro,
						/obj/item/attachable/bipod)
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 19,"rail_x" = 10, "rail_y" = 21, "under_x" = 24, "under_y" = 14, "stock_x" = 24, "stock_y" = 12)

/obj/item/weapon/gun/minigun/Fire(atom/target, mob/living/user, params, reflex = 0, dual_wield)
	if(user.action_busy)
		return
	playsound(get_turf(src), 'sound/weapons/tank_minigun_start.ogg', 30)
	if(!do_after(user, 5, TRUE, 5, BUSY_ICON_HOSTILE, null, TRUE)) //Half second wind up
		return

	. = ..()


/obj/item/weapon/gun/minigun/set_gun_config_values()
	fire_delay = CONFIG_GET(number/combat_define/low_fire_delay)
	burst_amount = CONFIG_GET(number/combat_define/mhigh_burst_value) + CONFIG_GET(number/combat_define/mhigh_burst_value)
	burst_delay = CONFIG_GET(number/combat_define/min_fire_delay)
	accuracy_mult = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	accuracy_mult_unwielded = CONFIG_GET(number/combat_define/base_hit_accuracy_mult)
	scatter = CONFIG_GET(number/combat_define/med_scatter_value)
	scatter_unwielded = CONFIG_GET(number/combat_define/med_scatter_value)
	damage_mult = CONFIG_GET(number/combat_define/base_hit_damage_mult)
	recoil = CONFIG_GET(number/combat_define/med_recoil_value)
	damage_falloff_mult = CONFIG_GET(number/combat_define/med_damage_falloff_mult)


/obj/item/weapon/gun/minigun/toggle_burst()
	var/obj/item/weapon/gun/G = get_active_firearm(usr)
	if(!G)
		return
	else if(G != src) //sanity
		return ..()
	to_chat(usr, "<span class='warning'>This weapon can only fire in bursts!</span>")

/obj/item/weapon/gun/minigun/get_ammo_type()
	if(!ammo)
		return list("unknown", "unknown")
	else
		return list(ammo.hud_state, ammo.hud_state_empty)

/obj/item/weapon/gun/minigun/get_ammo_count()
	if(!current_mag)
		return in_chamber ? 1 : 0
	else
		return in_chamber ? (current_mag.current_rounds + 1) : current_mag.current_rounds