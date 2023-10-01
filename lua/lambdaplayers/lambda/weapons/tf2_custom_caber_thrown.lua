local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local angularImpulse = Angle( 500, 0, 0 )
local hitFleshSnds = {
    ")weapons/bottle_hit_flesh1.wav",
    ")weapons/bottle_hit_flesh1.wav",
    ")weapons/bottle_hit_flesh1.wav"
}
local hitWorldSnds = {
    ")weapons/grenade_impact.wav",
    ")weapons/grenade_impact2.wav",
    ")weapons/grenade_impact3.wav"
}


local function CreateExplosion( self )

    local wepPos = self:GetPos()
    ParticleEffect( "ExplosionCore_MidAir", wepPos, ( ( wepPos + vector_up * 1 ) - wepPos ):Angle() )
    self:EmitSound( ")lambdaplayers/tf2/explode" .. random( 1, 3 ) .. ".mp3", 85, nil, nil, CHAN_WEAPON )

    local owner = self:GetOwner()
    if IsValid( owner ) then 
        local explodeinfo = DamageInfo()
        explodeinfo:SetDamage( 45 )
        explodeinfo:SetAttacker( owner )
        explodeinfo:SetInflictor( self )
        explodeinfo:SetDamagePosition( wepPos )
        explodeinfo:SetDamageForce( wepPos )
        explodeinfo:SetDamageType( DMG_BLAST )

        explodeinfo:SetDamageCustom( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_STICKBOMB_EXPLOSION )
        LAMBDA_TF2:SetCritType( explodeinfo, LAMBDA_TF2:GetCritType( explodeinfo ) )

        LAMBDA_TF2:RadiusDamageInfo( explodeinfo, wepPos, 100 )
    end
end

local function OnCaberTouch( self, ent )
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
                
                if ( CurTime() - self:GetCreationTime() ) >= 1 then
                    LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_custom_caber_thrown", 1.5 )
                    if critType == TF_CRIT_NONE then critType = TF_CRIT_MINI end
                end
            end

            local wepPos = self:GetPos()
            ParticleEffect( "ExplosionCore_MidAir", wepPos, ( ( wepPos + vector_up * 1 ) - wepPos ):Angle() )
            self:EmitSound( ")lambdaplayers/tf2/explode" .. random( 1, 3 ) .. ".mp3", 85, nil, nil, CHAN_WEAPON )

            local explodeinfo = DamageInfo()
            explodeinfo:SetDamage( 45 )
            explodeinfo:SetAttacker( owner )
            explodeinfo:SetInflictor( self )
            explodeinfo:SetDamagePosition( wepPos )
            explodeinfo:SetDamageForce( wepPos )
            explodeinfo:SetDamageType( DMG_BLAST )

            explodeinfo:SetDamageCustom( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_STICKBOMB_EXPLOSION )
            LAMBDA_TF2:SetCritType( explodeinfo, LAMBDA_TF2:GetCritType( explodeinfo ) )

            LAMBDA_TF2:RadiusDamageInfo( explodeinfo, wepPos, 100 )

            ent:DispatchTraceAttack( explodeinfo, touchTr, self:GetForward() )
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

        CreateExplosion( self )
    else
        self:EmitSound( hitWorldSnds[ random( #hitWorldSnds ) ], nil, nil, nil, CHAN_STATIC )
        self:SetPos( touchTr.HitPos + touchTr.HitNormal * 3 )
        SafeRemoveEntityDelayed( self, 0.1 )

        CreateExplosion( self )

        local blownCaber = ents_Create( "prop_physics" )
        blownCaber:SetPos( self:GetPos() )
        blownCaber:SetAngles( self:GetAngles() )
        blownCaber:SetModel( self:GetModel() )
        blownCaber:SetBodygroup( 1, 1 )
        blownCaber:Spawn()
        blownCaber:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        SafeRemoveEntityDelayed( blownCaber, 10 )
        
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_red_glow" )
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_blu_glow" )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_custom_caber_thrown = {
        model = "models/lambdaplayers/tf2/weapons/w_caber.mdl",
        origin = "Team Fortress 2",
        prettyname = "Thrown Caber",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_caber_exploded",
        keepdistance = 750,
        attackrange = 2500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
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

                local thrownCaber = ents_Create( "base_anim" )
                thrownCaber:SetModel( wepent:GetModel() )
                thrownCaber:SetSkin( wepent:GetSkin() )
                thrownCaber:SetPos( spawnPos )
                thrownCaber:SetAngles( throwAng )
                thrownCaber:SetOwner( self )
                thrownCaber:Spawn()

                thrownCaber:SetSolid( SOLID_BBOX )
                thrownCaber:SetMoveType( MOVETYPE_FLYGRAVITY )
                thrownCaber:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                LAMBDA_TF2:TakeNoDamage( thrownCaber )
                
                thrownCaber:SetFriction( 0.2 )
                thrownCaber:SetElasticity( 0.45 )
                thrownCaber:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

                thrownCaber:SetLocalVelocity( throwAng:Forward() * 1000 + throwAng:Up() * ( Rand(200, 250 ) + Rand( -10, 10 ) ) + throwAng:Right() * Rand( -10, 10 ) )
                thrownCaber:SetLocalAngularVelocity( angularImpulse )
    
                ParticleEffectAttach( "peejar_trail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ) .. "_glow", PATTACH_ABSORIGIN_FOLLOW, cleaver, 0 )

                thrownCaber.l_IsTFWeapon = true
                thrownCaber.Touch = OnCaberTouch
                
                thrownCaber.IsLambdaWeapon = true
                thrownCaber.l_killiconname = wepent.l_killiconname

                local critType = self:GetCritBoostType()
                if wepent:CalcIsAttackCriticalHelper() then critType = TF_CRIT_FULL end
                thrownCaber.l_CritType = critType

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )