local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local angularImpulse = Angle( 500, 0, 0 )
local hitFleshSnds = {
    ")weapons/axe_hit_flesh1.wav",
    ")weapons/axe_hit_flesh2.wav",
    ")weapons/axe_hit_flesh3.wav"
}
local hitWorldSnds = {
    ")player/pl_scout_dodge_can_pitch.wav",
    ")player/pl_scout_dodge_can_pitch.wav",
    ")player/pl_scout_dodge_can_pitch.wav"
}

local function CreateUsedCan( self )
    local usedCan = ents_Create( "prop_physics" )
    usedCan:SetPos( self:GetPos() )
    usedCan:SetAngles( self:GetAngles() )
    usedCan:SetModel( self:GetModel() )
    usedCan:SetSkin( self:GetSkin() )
    usedCan:Spawn()
    usedCan:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    SafeRemoveEntityDelayed( usedCan, 10 )

    usedCan:EmitSound( "player/pl_scout_dodge_can_crush.wav", 65, nil, nil, CHAN_ITEM )
    usedCan.l_PlayedHitSound = false
    usedCan:AddCallback ("PhysicsCollide", function( can )
        if !can.l_PlayedHitSound then
            can.l_PlayedHitSound = true
            can:EmitSound( "player/pl_scout_dodge_can_pitch.wav", 65, nil, nil, CHAN_ITEM )
        end
    end )

    return usedCan
end

local function OnColaTouch( self, ent )
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
                LAMBDA_TF2:MarkForDeath( ent, 5, false, owner:GetWeaponENT() )
                
                if ( CurTime() - self:GetCreationTime() ) >= 1 then
                    LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_custom_critacola_thrown", 1.5 )
                    if critType == TF_CRIT_NONE then critType = TF_CRIT_MINI end
                end
            end

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( 10 )
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

        CreateUsedCan( self )
    else
        self:EmitSound( hitWorldSnds[ random( #hitWorldSnds ) ], nil, nil, nil, CHAN_STATIC )
        self:SetPos( touchTr.HitPos + touchTr.HitNormal * 3 )
        SafeRemoveEntityDelayed( self, 0.1 )

        CreateUsedCan( self )
        
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_red_glow" )
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_blu_glow" )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_custom_critacola_thrown = {
        model = "models/lambdaplayers/tf2/weapons/w_energy_drink.mdl",
        origin = "Team Fortress 2",
        prettyname = "Thrown Crit-a-Cola",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_generic_death",
        keepdistance = 750,
        attackrange = 2500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetSkin( 2 )
            wepent:EmitSound( "player/pl_scout_dodge_can_open.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local throwPos = target:GetPos()
            local throwAng = ( throwPos - self:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( ")weapons/knife_swing.wav", 70, nil, nil, CHAN_WEAPON )

            self:SimpleWeaponTimer( 0.25, function()
                local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                throwPos = ( IsValid( target ) and target:GetPos() or ( self:GetPos() + self:GetForward() * 500 ) )
                throwAng = ( throwPos - spawnPos ):Angle()

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local thrownCan = ents_Create( "base_gmodentity" )
                thrownCan:SetModel( wepent:GetModel() )
                thrownCan:SetSkin( wepent:GetSkin() )
                thrownCan:SetPos( spawnPos )
                thrownCan:SetAngles( throwAng )
                thrownCan:SetOwner( self )
                thrownCan:Spawn()

                thrownCan:SetSolid( SOLID_BBOX )
                thrownCan:SetMoveType( MOVETYPE_FLYGRAVITY )
                thrownCan:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                LAMBDA_TF2:TakeNoDamage( thrownCan )
                
                thrownCan:SetFriction( 0.2 )
                thrownCan:SetElasticity( 0.45 )
                thrownCan:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

                local throwVel = vector_origin
                throwVel = throwVel + throwAng:Forward() * 10
                throwVel = throwVel + throwAng:Up() * 1.4
                throwVel:Normalize()
                throwVel = throwVel * 1500

                thrownCan:SetLocalVelocity( throwVel )
                thrownCan:SetLocalAngularVelocity( angularImpulse )
    
                ParticleEffectAttach( "peejar_trail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ) .. "_glow", PATTACH_ABSORIGIN_FOLLOW, cleaver, 0 )

                thrownCan.l_IsTFWeapon = true
                thrownCan.Touch = OnColaTouch
                
                thrownCan.IsLambdaWeapon = true
                thrownCan.l_killiconname = wepent.l_killiconname

                local critType = self:GetCritBoostType()
                if wepent:CalcIsAttackCriticalHelper() then critType = TF_CRIT_FULL end
                thrownCan.l_CritType = critType

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )