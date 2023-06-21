local Rand = math.Rand
local random = math.random
local min = math.min
local max = math.max
local Clamp = math.Clamp
local CurTime = CurTime
local isnumber = isnumber
local bulletTbl = {
    TracerName = "Tracer",
    Num = 1
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sniperrifle = {
        model = "models/lambdaplayers/tf2/weapons/w_sniper_rifle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sniper Rifle",
        holdtype = {
            idle = ACT_HL2MP_IDLE_RPG,
            run = ACT_HL2MP_RUN_RPG,
            walk = ACT_HL2MP_WALK_RPG,
            jump = ACT_HL2MP_JUMP_RPG,
            crouchIdle = ACT_HL2MP_IDLE_CROUCH_AR2,
            crouchWalk = ACT_HL2MP_WALK_CROUCH_AR2,
            swimIdle = ACT_HL2MP_SWIM_IDLE_RPG,
            swimMove = ACT_HL2MP_SWIM_RPG
        },
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_sniperrifle",

        clip = 25,
        keepdistance = 2000,
        attackrange = 4000,
        islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 30 )
            wepent:SetWeaponAttribute( "RateOfFire", { 1.5, 2.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", ")weapons/sniper_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/sniper_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            
            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_sniperrifle" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent.l_TF_IsCharging = false
            wepent.l_TF_NextZoomTime = CurTime()
            wepent.l_TF_ZoomedTime = CurTime()
            wepent.l_TF_ChargeIsFull = false
            wepent.l_TF_ChargeStartTime = CurTime()
            wepent.l_TF_ChargeTimeRequired = 3.3

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead then
                local ene = self:GetEnemy()
                if self:GetState() == "Combat" and IsValid( ene ) and ( self:CanSee( ene ) or self:IsInRange( ene, 512 ) ) then
                    wepent.l_TF_ZoomedTime = CurTime() + Rand( 1.0, 3.0 )
                end

                wepent.l_TF_IsCharging = ( CurTime() > wepent.l_TF_NextZoomTime and CurTime() <= wepent.l_TF_ZoomedTime )
                if wepent.l_TF_IsCharging then 
                    self.l_WeaponSpeedMultiplier = 0.27
        
                    if self:InCombat() then
                        local distMap = LAMBDA_TF2:RemapClamped( self:GetRangeTo( ene ), 128, 768, 0, 1 )
                        wepent.l_TF_ChargeTimeRequired = LAMBDA_TF2:RemapClamped( distMap, 0, 1, 0.5, Rand( 3.3, 4 ) )
                    else
                        wepent.l_TF_ChargeTimeRequired = 3.3
                    end

                    if !wepent.l_TF_ChargeIsFull and ( CurTime() - wepent.l_TF_ChargeStartTime ) >= 3.3 then
                        wepent.l_TF_ChargeIsFull = true
                        wepent:EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
                    end
                else
                    if CurTime() >= self.l_WeaponUseCooldown then self.l_WeaponUseCooldown = CurTime() + 1.0 end
                    self.l_WeaponSpeedMultiplier = 1
                    wepent.l_TF_ChargeStartTime = CurTime()
                end
            end

            return 0.1
        end,

        OnAttack = function( self, wepent, target )
            local chargeStartTime = ( CurTime() - wepent.l_TF_ChargeStartTime )
            if wepent.l_TF_IsCharging and chargeStartTime < wepent.l_TF_ChargeTimeRequired then return true end

            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end
            
            wepent.l_TF_ChargeStartTime = CurTime()
            wepent.l_TF_NextZoomTime = ( CurTime() + 1 )

            local headHitBox = LAMBDA_TF2:GetEntityHeadBone( target )
            local targetPos = ( ( wepent.l_TF_IsCharging and headHitBox and ( wepent.l_TF_ChargeIsFull or random( 1, 3 ) != 1 ) ) and LAMBDA_TF2:GetBoneTransformation( target, headHitBox ) or target:WorldSpaceCenter() )
            wepent.l_TF_ChargeIsFull = false

            local srcPos = wepent:GetPos()
            bulletTbl.Dir = ( targetPos - srcPos ):GetNormalized()

            local spread = LAMBDA_TF2:RemapClamped( chargeStartTime, 0, 3.3, 0.1, 0.01 )
            bulletTbl.Spread = Vector( spread, spread, 0 )

            local dmgMult = LAMBDA_TF2:RemapClamped( chargeStartTime, 0, 3.3, 1, 3 )
            local damage = ( wepent:GetWeaponAttribute( "Damage" ) * dmgMult )
            bulletTbl.Damage = damage
            bulletTbl.Force = ( damage / 2 )

            bulletTbl.Attacker = self
            bulletTbl.IgnoreEntity = self
            bulletTbl.Src = srcPos

            local muzzlePos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            bulletTbl.Callback = function( attacker, tr, dmginfo )
                local traceLifeTime = LAMBDA_TF2:RemapClamped( chargeStartTime, 0, 3.3, 0.25, 1 )
                LAMBDA_TF2:CreateCritBulletTracer( muzzlePos, tr.HitPos, self:GetPlyColor():ToColor(), 0.4, traceLifeTime )

                if chargeStartTime > 0.2 and tr.HitGroup == HITGROUP_HEAD then 
                    dmginfo:SetDamageCustom( TF_DMG_CUSTOM_HEADSHOT ) 
                end

                if GetConVar( "lambdaplayers_tf2_alwayscrit" ):GetBool() then
                    dmginfo:SetDamageCustom( TF_DMG_CUSTOM_HEADSHOT ) 
                end
            end

            wepent:FireBullets( bulletTbl )

            self:SimpleWeaponTimer( 0.666667, function()
                wepent:EmitSound( "weapons/sniper_bolt_back.wav", nil, nil, 0.45 )
            end )
            self:SimpleWeaponTimer( 0.966667, function()
                LAMBDA_TF2:CreateShellEject( wepent, "RifleShellEject" )
                wepent:EmitSound( "weapons/sniper_bolt_forward.wav", nil, nil, 0.45 )
            end )

            return true
        end
    }
} )