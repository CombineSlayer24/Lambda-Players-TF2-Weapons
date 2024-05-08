local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local angularImpulse = Angle( 500, 0, 0 )
local hitFleshSnds = {
    ")weapons/blade_slice_2.wav",
    ")weapons/blade_slice_3.wav",
    ")weapons/blade_slice_4.wav"
}
local hitWorldSnds = {
    ")mvm/melee_impacts/bottle_hit_robo01.wav",
    ")mvm/melee_impacts/bottle_hit_robo02.wav",
    ")mvm/melee_impacts/bottle_hit_robo03.wav"
}

local function OnFireaxeTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    if ent:IsPlayer() and ignorePlys:GetBool() then self:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end

    local owner = self:GetOwner()
    if IsValid( owner ) then 
        if ent == owner then return end

        if IsValid( ent ) then
            local critType = self.l_CritType

            if LAMBDA_TF2:IsValidCharacter( ent ) then
                LAMBDA_TF2:MakeBleed( ent, owner, owner:GetWeaponENT(), 5 )
                
                if ( CurTime() - self:GetCreationTime() ) >= 1 then
                    LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_custom_fireaxe_thrown", 1.5 )
                    if critType == TF_CRIT_NONE then critType = TF_CRIT_MINI end
                end
            end

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( 50 )
            dmginfo:SetDamagePosition( self:GetPos() )
            dmginfo:SetDamageForce( self:GetVelocity() * dmginfo:GetDamage() )
            dmginfo:SetDamageType( DMG_GENERIC )
            LAMBDA_TF2:SetCritType( dmginfo, critType )

            ent:DispatchTraceAttack( dmginfo, touchTr, self:GetForward() )
        end
    end
    
    self:AddSolidFlags( FSOLID_NOT_SOLID )
    self:SetMoveType( MOVETYPE_NONE )

    if IsValid( ent ) and LAMBDA_TF2:IsValidCharacter( ent, false ) then
        self:EmitSound( hitFleshSnds[ random( #hitFleshSnds ) ], nil, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:CreateBloodParticle( self:GetPos(), AngleRand( -180, 180 ), ent )

        self:SetNoDraw( true )
        self:DrawShadow( false )
        self:SetSolid( SOLID_NONE )
        SafeRemoveEntityDelayed( self, 0.1 )
    else
        self:EmitSound( hitWorldSnds[ random( #hitWorldSnds ) ], nil, nil, nil, CHAN_STATIC )
        self:SetPos( touchTr.HitPos + touchTr.HitNormal * 3 )
        SafeRemoveEntityDelayed( self, 2 )
        
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_red_glow" )
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_blu_glow" )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_custom_fireaxe_thrown = {
        model = "models/lambdaplayers/tf2/weapons/w_fireaxe.mdl",
        origin = "Team Fortress 2",
        prettyname = "Thrown Fireaxe",
        holdtype = "melee2",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_fireaxe",
        keepdistance = 750,
        attackrange = 2500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "weapons/cleaver_draw.wav", nil, nil, nil, CHAN_STATIC )
        end,

        OnAttack = function( self, wepent, target )
            local throwPos = target:GetPos()
            local throwAng = ( throwPos - self:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( ")weapons/wrench_swing.wav", 70, nil, nil, CHAN_WEAPON )

            self:SimpleWeaponTimer( 0.25, function()
                local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                throwPos = ( IsValid( target ) and target:GetPos() or ( self:GetPos() + self:GetForward() * 500 ) )
                throwAng = ( throwPos - spawnPos ):Angle()

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local fireaxe = ents_Create( "base_gmodentity" )
                fireaxe:SetModel( wepent:GetModel() )
                fireaxe:SetPos( spawnPos )
                fireaxe:SetAngles( throwAng )
                fireaxe:SetOwner( self )
                fireaxe:Spawn()

                fireaxe:SetSolid( SOLID_BBOX )
                fireaxe:SetMoveType( MOVETYPE_FLYGRAVITY )
                fireaxe:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                LAMBDA_TF2:TakeNoDamage( fireaxe )
                
                fireaxe:SetFriction( 0.2 )
                fireaxe:SetElasticity( 0.45 )
                fireaxe:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

                local throwVel = vector_origin
                throwVel = throwVel + throwAng:Forward() * 10
                throwVel = throwVel + throwAng:Up() * 1.2
                throwVel:Normalize()
                throwVel = throwVel * 2000

                fireaxe:SetLocalVelocity( throwVel )
                fireaxe:SetLocalAngularVelocity( angularImpulse )
    
                ParticleEffectAttach( "peejar_trail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ) .. "_glow", PATTACH_ABSORIGIN_FOLLOW, fireaxe, 0 )

                fireaxe.l_IsTFWeapon = true
                fireaxe.Touch = OnFireaxeTouch
                
                fireaxe.IsLambdaWeapon = true
                fireaxe.l_killiconname = wepent.l_killiconname

                local critType = self:l_GetCritBoostType()
                if wepent:CalcIsAttackCriticalHelper() then critType = TF_CRIT_FULL end
                fireaxe.l_CritType = critType

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )