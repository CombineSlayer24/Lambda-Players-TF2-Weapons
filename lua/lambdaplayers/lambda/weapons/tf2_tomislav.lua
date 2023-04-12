table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_tomislav = {
        model = "models/lambdaplayers/tf2/weapons/w_tomislav.mdl",
        origin = "Team Fortress 2",
        prettyname = "Tomislav",
        holdtype = "crossbow",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_tomislav",

        clip = 200,
        islethal = true,
        attackrange = 1500,
        keepdistance = 400,
		speedmultiplier = 0.77,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "Spread", 0.064 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.126 )
            wepent:SetWeaponAttribute( "WindUpTime", 0.6 )

            wepent:SetWeaponAttribute( "FireSound", ")weapons/tomislav_shoot.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/tomislav_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "WindUpSound", ")weapons/tomislav_wind_up.wav" )
            wepent:SetWeaponAttribute( "WindDownSound", ")weapons/tomislav_wind_down.wav" )

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