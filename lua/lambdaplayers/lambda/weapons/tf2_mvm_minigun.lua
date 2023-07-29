table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_mvm_minigun = {
        model = "models/lambdaplayers/tf2/weapons/w_minigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "MvM Minigun",
        holdtype = "crossbow",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_minigun",

        ismvmweapon = true,
        clip = 200,
        islethal = true,
        attackrange = 1250,
        keepdistance = 800,
		speedmultiplier = 0.5,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "Spread", 0.08 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_tracer01" )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "WindUpTime", 0.75 )

            wepent:SetWeaponAttribute( "SpinSound", ")mvm/giant_heavy/giant_heavy_gunspin.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")mvm/giant_heavy/giant_heavy_gunfire.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")mvm/giant_heavy/giant_heavy_gunfire.wav" )
            wepent:SetWeaponAttribute( "WindUpSound", ")mvm/giant_heavy/giant_heavy_gunwindup.wav" )
            wepent:SetWeaponAttribute( "WindDownSound", ")mvm/giant_heavy/giant_heavy_gunwinddown.wav" )

            LAMBDA_TF2:MinigunDeploy( self, wepent )
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:MinigunHolster( self, wepent )
        end,

        OnThink = function( self, wepent, dead )
            LAMBDA_TF2:MinigunThink( self, wepent, dead )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:MinigunFire( self, wepent, target )
            return true
        end
    }
} )