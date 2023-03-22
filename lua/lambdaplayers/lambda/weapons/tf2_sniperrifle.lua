local Rand = math.Rand
local random = math.random
local min = math.min
local max = math.max
local Remap = math.Remap
local CurTime = CurTime
local isnumber = isnumber
local bulletTbl = {
    TracerName = "Tracer",
    Num = 1
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sniperrifle = {
        model = "models/lambdaplayers/weapons/tf2/w_sniper_rifle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sniper Rifle",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_sniperrifle",

        clip = 25,
        keepdistance = 2000,
        attackrange = 2000,
        islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 30 )
            wepent:SetWeaponAttribute( "RateOfFire", { 1.5, 2.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/sniperrifle/sniper_shoot.mp3" )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ClipDrain", false )

            wepent.l_TF_IsCharging = false
            wepent.l_TF_NextZoomTime = CurTime()
            wepent.l_TF_ChargeIsFull = false
            wepent.l_TF_ChargeStartTime = CurTime()
            wepent.l_TF_ChargeTimeRequired = 3.3
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 60 )
        end,

        OnThink = function( self, wepent )
            local ene = self:GetEnemy()
            wepent.l_TF_IsCharging = ( CurTime() > wepent.l_TF_NextZoomTime and self:GetState() == "Combat" and IsValid( ene ) and !self:IsInRange( ene, 400 ) and ( self:CanSee( ene ) or self:IsInRange( ene, 768 ) ) )

            if wepent.l_TF_IsCharging then 
                self.l_WeaponSpeedMultiplier = 0.27
                wepent.l_TF_ChargeTimeRequired = min( Remap( self:GetRangeTo( ene ), 128, 768, 1.5, 4 ), Rand( 3.3, 4 ) )

                if !wepent.l_TF_ChargeIsFull and ( CurTime() - wepent.l_TF_ChargeStartTime ) >= 3.3 then
                    wepent.l_TF_ChargeIsFull = true
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/recharged.mp3", 75, 100, 0.5, CHAN_STATIC )
                end
            else
                if CurTime() >= self.l_WeaponUseCooldown then self.l_WeaponUseCooldown = CurTime() + 1.0 end
                self.l_WeaponSpeedMultiplier = 1
                wepent.l_TF_ChargeStartTime = CurTime()
            end

            return 0.1
        end,

        OnAttack = function( self, wepent, target )
            local chargeStartTime = ( CurTime() - wepent.l_TF_ChargeStartTime )
            if wepent.l_TF_IsCharging and chargeStartTime < wepent.l_TF_ChargeTimeRequired then return true end

            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end
            
            wepent.l_TF_ChargeStartTime = CurTime()
            wepent.l_TF_NextZoomTime = ( CurTime() + 1 )

            local headBone = target:LookupBone( "ValveBiped.Bip01_Head1" )
            local targetPos = ( ( wepent.l_TF_IsCharging and isnumber( headBone ) and ( wepent.l_TF_ChargeIsFull or random( 1, 3 ) != 1 ) ) and LAMBDA_TF2:GetBoneTransformation( target, headBone ) or target:WorldSpaceCenter() )
            wepent.l_TF_ChargeIsFull = false

            local srcPos = wepent:GetPos()
            bulletTbl.Dir = ( targetPos - srcPos ):GetNormalized()

            local spread = max( Remap( chargeStartTime, 0, 3.3, 0.125, 0.0175 ), 0 )
            bulletTbl.Spread = Vector( spread, spread, 2 )

            local dmgMult = min( 3, Remap( chargeStartTime, 0, 3.3, 1, 3 ) )
            local damage = ( wepent:GetWeaponAttribute( "Damage" ) * dmgMult )
            bulletTbl.Damage = damage
            bulletTbl.Force = ( damage / 2 )

            bulletTbl.Attacker = self
            bulletTbl.IgnoreEntity = self
            bulletTbl.Src = srcPos
            bulletTbl.Callback = function( attacker, tr, dmginfo )
                LAMBDA_TF2:CreateCritBulletTracer( tr.StartPos, tr.HitPos, self:GetPlyColor():ToColor(), 0.4, 1 )
                if tr.HitGroup == HITGROUP_HEAD then dmginfo:SetDamageCustom( TF_DMG_CUSTOM_HEADSHOT ) end
            end

            wepent:FireBullets( bulletTbl )

            self:SimpleWeaponTimer( 0.6, function()
                LAMBDA_TF2:CreateShellEject( wepent, "RifleShellEject" )
                wepent:EmitSound( "lambdaplayers/weapons/tf2/sniperrifle/sniper_bolt_back.mp3", 65 )
            end )
            self:SimpleWeaponTimer( 0.9, function()
                wepent:EmitSound( "lambdaplayers/weapons/tf2/sniperrifle/sniper_bolt_forward.mp3", 65 )
            end )
                
            return true
        end
    }
} )