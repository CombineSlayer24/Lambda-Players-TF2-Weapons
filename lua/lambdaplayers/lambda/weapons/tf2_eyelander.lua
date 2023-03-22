local min = math.min
local ceil = math.ceil
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_eyelander = {
        model = "models/lambdaplayers/weapons/tf2/w_eyelander.mdl",
        origin = "Team Fortress 2",
        prettyname = "Eyelander",
        holdtype = "melee2",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_eyelander",
        keepdistance = 10,
        attackrange = 80,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.875,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitRange", 72 )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                "lambdaplayers/weapons/tf2/melee/sword_swing1.mp3",
                "lambdaplayers/weapons/tf2/melee/sword_swing2.mp3",
                "lambdaplayers/weapons/tf2/melee/sword_swing3.mp3"
            } )
            wepent:SetWeaponAttribute( "HitSound", {
                "lambdaplayers/weapons/tf2/melee/blade_slice_2.mp3",
                "lambdaplayers/weapons/tf2/melee/blade_slice_3.mp3",
                "lambdaplayers/weapons/tf2/melee/blade_slice_4.mp3"
            } )
            wepent:SetWeaponAttribute( "CustomDamage", TF_DMG_CUSTOM_DECAPITATION )

            wepent.l_TF_Eyelander_PreEquipMaxHealth = self:GetMaxHealth()
            wepent.l_TF_Eyelander_PostEquipMaxHealth = ( wepent.l_TF_Eyelander_PreEquipMaxHealth * 0.75 )
            wepent.l_TF_Eyelander_GiveHealthAmount = ( ( wepent.l_TF_Eyelander_PreEquipMaxHealth - wepent.l_TF_Eyelander_PostEquipMaxHealth ) * 0.6 )
            local newMaxHealth = ( wepent.l_TF_Eyelander_PostEquipMaxHealth + ( 15 * self.l_TF_Decapitations ) )
            self:SetMaxHealth( newMaxHealth )
            self:SetHealth( ceil( self:Health() * ( newMaxHealth / wepent.l_TF_Eyelander_PreEquipMaxHealth ) ) )

            if !self.l_TF_Shield_IsEquipped and random( 1, 3 ) != 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/sword_draw.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,

        OnHolster = function( self, wepent )
            self:SetHealth( ceil( self:Health() * ( wepent.l_TF_Eyelander_PreEquipMaxHealth  / self:GetMaxHealth() ) ) )
            self:SetMaxHealth( wepent.l_TF_Eyelander_PreEquipMaxHealth )
            self.l_WeaponSpeedMultiplier = 1
        end,

        OnDeath = function( self, wepent, dmginfo )            
            self.l_WeaponSpeedMultiplier = 1
            self:SetMaxHealth( wepent.l_TF_Eyelander_PostEquipMaxHealth )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end
            self.l_TF_Decapitations = ( self.l_TF_Decapitations + 1 )

            self:SetMaxHealth( min( wepent.l_TF_Eyelander_PostEquipMaxHealth + ( wepent.l_TF_Eyelander_GiveHealthAmount * self.l_TF_Decapitations ), wepent.l_TF_Eyelander_PostEquipMaxHealth + ( wepent.l_TF_Eyelander_GiveHealthAmount * 4 ) ) )
            LAMBDA_TF2:GiveHealth( self, wepent.l_TF_Eyelander_GiveHealthAmount )
            self.l_WeaponSpeedMultiplier = min( 1 + ( 0.08 * self.l_TF_Decapitations ), 1 + ( 0.08 * 4 ) )
        end
    }
} )