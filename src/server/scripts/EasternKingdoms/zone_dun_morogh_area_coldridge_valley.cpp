/*
 * Copyright (C) 2008-2018 TrinityCore <https://www.trinitycore.org/>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "ScriptMgr.h"
#include "CombatAI.h"
#include "Containers.h"
#include "HostileRefManager.h"
#include "MotionMaster.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "ThreatManager.h"
#include <algorithm>
#include <queue>
#include <unordered_map>
#include <unordered_set>
#include <vector>

enum WoundedColdridgeMountaineer
{
    NPC_JOREN_IRONSTOCK            = 37081,
    SAY_THANK_PLAYER               = 0,
    SPELL_HEAL_WOUNDED_MOUNTAINEER = 69855,
    SPELL_LOW_HEALTH               = 76143,
    EVENT_TURN_TO_PLAYER           = 1,
    EVENT_THANK_PLAYER             = 2,
    EVENT_MOVE_TO_SAFETY           = 3
};

/*######
# wounded_coldridge_mountaineer
######*/

class npc_wounded_coldridge_mountaineer : public CreatureScript
{
public:
    npc_wounded_coldridge_mountaineer() : CreatureScript("npc_wounded_coldridge_mountaineer") { }

    struct npc_wounded_coldridge_mountaineerAI : public ScriptedAI
    {
        npc_wounded_coldridge_mountaineerAI(Creature* creature) : ScriptedAI(creature), _tapped(false) { }

        void Reset() override
        {
            _events.Reset();
            DoCastSelf(SPELL_LOW_HEALTH);
            _tapped = false;
        }

        void SpellHit(Unit* caster, SpellInfo const* spell) override
        {
            if (_tapped)
                return;

            if (spell->Id == SPELL_HEAL_WOUNDED_MOUNTAINEER)
            {
                if (caster->GetTypeId() == TYPEID_PLAYER)
                {
                    _tapped = true;
                    _playerGUID = caster->GetGUID();
                    me->SetUInt32Value(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC);
                    me->SetUInt32Value(UNIT_FIELD_BYTES_1, UNIT_STAND_STATE_STAND);
                    _events.ScheduleEvent(EVENT_TURN_TO_PLAYER, Seconds(2));
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!_tapped)
                return;

            _events.Update(diff);

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                case EVENT_TURN_TO_PLAYER:
                    me->SetFacingToObject(ObjectAccessor::GetUnit(*me, _playerGUID));
                    _events.ScheduleEvent(EVENT_THANK_PLAYER, Seconds(1));
                    break;
                case EVENT_THANK_PLAYER:
                    Talk(SAY_THANK_PLAYER, ObjectAccessor::GetUnit(*me, _playerGUID));
                    _events.ScheduleEvent(EVENT_MOVE_TO_SAFETY, Seconds(5));
                    break;
                case EVENT_MOVE_TO_SAFETY:
                    if (Creature* joren = me->FindNearestCreature(NPC_JOREN_IRONSTOCK, 75.0f, true))
                         me->GetMotionMaster()->MovePoint(0, joren->GetPosition(), true);
                    me->DespawnOrUnsummon(Seconds(5));
                    break;
                default:
                    break;
                }
            }
        }
    private:
        EventMap _events;
        ObjectGuid _playerGUID;
        bool _tapped;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_wounded_coldridge_mountaineerAI(creature);
    }
};

/*####
## npc_wounded_milita
####*/

enum WoundedMilita
{
    QUEST_KILL_CREDIT  = 44175,
    SPELL_FLASH_HEAL   = 2061,
    EVENT_RESET_HEALTH = 4
};

class npc_wounded_milita : public CreatureScript
{
public:
    npc_wounded_milita() : CreatureScript("npc_wounded_milita") { }

    struct npc_wounded_militaAI : public ScriptedAI
    {
        npc_wounded_militaAI(Creature* creature) : ScriptedAI(creature)
        {
            Initialize();
        }

        void Initialize()
        {
            _hitBySpell = false;
            _percentHP = urand(15, 55);
        }

        void Reset() override
        {
            Initialize();
            me->SetHealth(me->CountPctFromMaxHealth(_percentHP));
        }

        void SpellHit(Unit* caster, SpellInfo const* spell) override
        {
            if (!_hitBySpell)
            {
                _hitBySpell = true;
                _events.ScheduleEvent(EVENT_RESET_HEALTH, Seconds(30));
            }

            if (spell->Id == SPELL_FLASH_HEAL)
                if (Player* player = caster->ToPlayer())
                    player->KilledMonsterCredit(QUEST_KILL_CREDIT);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!_hitBySpell)
                return;

            _events.Update(diff);

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_RESET_HEALTH:
                        me->SetHealth(me->CountPctFromMaxHealth(_percentHP));
                        _hitBySpell = false;
                        break;
                    default:
                        break;
                }
            }
        }
    private:
        EventMap _events;
        uint8 _percentHP;
        bool _hitBySpell;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_wounded_militaAI(creature);
    }
};

/*######
## npc_milos_gyro
######*/

enum MilosGyro
{
    NPC_MILO                      = 37518,
    SPELL_RIDE_VEHICLE_HARD_CODED = 46598,
    SPELL_EJECT_ALL_PASSENGERS    = 50630,
    SAY_MILO_FLIGHT_1             = 0,
    SAY_MILO_FLIGHT_2             = 1,
    SAY_MILO_FLIGHT_3             = 2,
    SAY_MILO_FLIGHT_4             = 3,
    SAY_MILO_FLIGHT_5             = 4,
    SAY_MILO_FLIGHT_6             = 5,
    SAY_MILO_FLIGHT_7             = 6,
    EVENT_START_PATH              = 5,
    EVENT_MILO_SAY_0              = 6,
    EVENT_MILO_SAY_1              = 7,
    EVENT_MILO_SAY_2              = 8,
    EVENT_MILO_SAY_3              = 9,
    EVENT_MILO_SAY_4              = 10,
    EVENT_MILO_SAY_5              = 11,
    EVENT_MILO_SAY_6              = 12,
    EVENT_MILO_DESPAWN            = 13
};

Position const kharanosPath[] =
{
    { -6247.328f, 299.5365f, 390.266f   },
    { -6247.328f, 299.5365f, 390.266f   },
    { -6250.934f, 283.5417f, 393.46f    },
    { -6253.335f, 252.7066f, 403.0702f  },
    { -6257.292f, 217.4167f, 424.3807f  },
    { -6224.2f,   159.9861f, 447.0882f  },
    { -6133.597f, 164.3177f, 491.0316f  },
    { -6084.236f, 183.375f, 508.5401f   },
    { -6020.382f, 179.5052f, 521.5396f  },
    { -5973.592f, 161.7396f, 521.5396f  },
    { -5953.665f, 151.6111f, 514.5687f  },
    { -5911.031f, 146.4462f, 482.1806f  },
    { -5886.389f, 124.125f, 445.6252f   },
    { -5852.08f,  55.80903f, 406.7922f  },
    { -5880.707f, 12.59028f, 406.7922f  },
    { -5927.887f, -74.02257f, 406.7922f },
    { -5988.436f, -152.0174f, 425.6251f },
    { -6015.274f, -279.467f, 449.528f   },
    { -5936.465f, -454.1875f, 449.528f  },
    { -5862.575f, -468.0504f, 444.3899f },
    { -5783.58f,  -458.6042f, 432.5026f },
    { -5652.707f, -463.4427f, 415.0308f },
    { -5603.897f, -466.3438f, 409.8931f },
    { -5566.957f, -472.5642f, 399.0056f }
};
size_t const pathSize = std::extent<decltype(kharanosPath)>::value;

class npc_milos_gyro : public CreatureScript
{
public:
    npc_milos_gyro() : CreatureScript("npc_milos_gyro") { }

    struct npc_milos_gyro_AI : public VehicleAI
    {
        npc_milos_gyro_AI(Creature* creature) : VehicleAI(creature), _waitBeforePath(true) { }

        void Reset() override
        {
            _events.Reset();
            _miloGUID.Clear();
            _waitBeforePath = true;
        }

        void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
        {
            if (apply && passenger->GetTypeId() == TYPEID_PLAYER)
            {
                if (Creature* milo = passenger->SummonCreature(NPC_MILO, me->GetPosition(), TEMPSUMMON_CORPSE_DESPAWN, 0))
                {
                    _waitBeforePath = false;
                    _miloGUID = milo->GetGUID();
                    milo->CastSpell(me, SPELL_RIDE_VEHICLE_HARD_CODED);
                    _events.ScheduleEvent(EVENT_START_PATH, Seconds(1));
                }
            }
        }

        void MovementInform(uint32 type, uint32 pointId) override
        {
            if (type == EFFECT_MOTION_TYPE && pointId == pathSize)
                _events.ScheduleEvent(EVENT_MILO_DESPAWN, Seconds(1));
        }

        void UpdateAI(uint32 diff) override
        {
            if (_waitBeforePath)
                return;

            _events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_START_PATH:
                        me->GetMotionMaster()->MoveSmoothPath(uint32(pathSize), kharanosPath, pathSize, false, true);
                        _events.ScheduleEvent(EVENT_MILO_SAY_0, Seconds(5));
                        break;
                    case EVENT_MILO_SAY_0:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_1, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_1, Seconds(6));
                        break;
                    case EVENT_MILO_SAY_1:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_2, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_2, Seconds(11));
                        break;
                    case EVENT_MILO_SAY_2:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_3, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_3, Seconds(11));
                        break;
                    case EVENT_MILO_SAY_3:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_4, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_4, Seconds(18));
                        break;
                    case EVENT_MILO_SAY_4:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_5, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_5, Seconds(11));
                        break;
                    case EVENT_MILO_SAY_5:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_6, me);
                        _events.ScheduleEvent(EVENT_MILO_SAY_6, Seconds(14));
                        break;
                    case EVENT_MILO_SAY_6:
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->AI()->Talk(SAY_MILO_FLIGHT_7, me);
                        break;
                    case EVENT_MILO_DESPAWN:
                        me->RemoveAllAuras();
                        if (Creature* milo = ObjectAccessor::GetCreature(*me, _miloGUID))
                            milo->DespawnOrUnsummon();
                        _waitBeforePath = true;
                        break;
                    default:
                        break;
                }
            }
        }
    private:
        EventMap _events;
        ObjectGuid _miloGUID;
        bool _waitBeforePath;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_milos_gyro_AI(creature);
    }
};

enum HandsSpringsprocket
{
    QUEST_A_TRIP_TO_IRONFORGE = 24490,

    // "Alright, so you're just going to head through this tunnel and whaaaaa....?"
    SAY_CAVE_IN               = 0
};

/*######
# npc_hands_springsprocket
# 6782 - Hands Springsprocket
######*/

class npc_hands_springsprocket : public CreatureScript
{
public:
    npc_hands_springsprocket() : CreatureScript("npc_hands_springsprocket") { }

    bool OnQuestReward(Player* player, Creature* creature, Quest const* quest, uint32 /*opt*/) override
    {
        if (quest->GetQuestId() == QUEST_A_TRIP_TO_IRONFORGE)
            creature->AI()->Talk(SAY_CAVE_IN, player);

        return false;
    }
};

/*######
# spell_a_trip_to_ironforge_quest_complete
# 70046 - A Trip to Ironforge - Quest Complete
######*/

class spell_a_trip_to_ironforge_quest_complete : public SpellScriptLoader
{
public:
    spell_a_trip_to_ironforge_quest_complete() : SpellScriptLoader("spell_a_trip_to_ironforge_quest_complete") { }

    class spell_a_trip_to_ironforge_quest_complete_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_a_trip_to_ironforge_quest_complete_SpellScript);

        void HandleForceCast(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
            GetHitUnit()->CastSpell(GetHitUnit(), GetSpellInfo()->GetEffect(effIndex)->TriggerSpell, true);
        }

        void SuppressDuplicateSound(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_a_trip_to_ironforge_quest_complete_SpellScript::HandleForceCast, EFFECT_0, SPELL_EFFECT_FORCE_CAST);
            OnEffectHitTarget += SpellEffectFn(spell_a_trip_to_ironforge_quest_complete_SpellScript::SuppressDuplicateSound, EFFECT_1, SPELL_EFFECT_PLAY_SOUND);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_a_trip_to_ironforge_quest_complete_SpellScript();
    }
};

/*######
# spell_follow_that_gyrocopter_quest_start
# 70047 - Follow That Gyro-Copter - Quest Start
######*/

class spell_follow_that_gyrocopter_quest_start : public SpellScriptLoader
{
public:
    spell_follow_that_gyrocopter_quest_start() : SpellScriptLoader("spell_follow_that_gyrocopter_quest_start") { }

    class spell_follow_that_gyrocopter_quest_start_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_follow_that_gyrocopter_quest_start_SpellScript);

        void HandleForceCast(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
            GetHitUnit()->CastSpell(GetHitUnit(), GetSpellInfo()->GetEffect(effIndex)->TriggerSpell, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_follow_that_gyrocopter_quest_start_SpellScript::HandleForceCast, EFFECT_1, SPELL_EFFECT_FORCE_CAST);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_follow_that_gyrocopter_quest_start_SpellScript();
    }
};

/*######
# spell_throw_priceless_artifact
# 69897 - Throw Priceless Artifact
######*/

enum ThrowPricelessArtifact
{
    SPELL_CREATE_PRICELESS_ROCKJAW_ARTIFACT = 104959,
    QUEST_MAKE_HAY_WHILE_THE_SUN_SHINES     = 24486
};

// Throw Priceless Artifact, for quest 24486.
// Players are still able to loot from dead troggs
// this is retail behaviour
class spell_throw_priceless_artifact : public SpellScriptLoader
{
public:
    spell_throw_priceless_artifact() : SpellScriptLoader("spell_throw_priceless_artifact") { }

    class spell_throw_priceless_artifact_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_throw_priceless_artifact_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return ValidateSpellInfo({ SPELL_CREATE_PRICELESS_ROCKJAW_ARTIFACT });
        }

        void GiveArtifact(SpellEffIndex /*effIndex*/)
        {
            Player* player = GetHitPlayer();
            if (!player || player->GetQuestStatus(QUEST_MAKE_HAY_WHILE_THE_SUN_SHINES) != QUEST_STATUS_INCOMPLETE)
                return;

            GetCaster()->CastSpell(player, SPELL_CREATE_PRICELESS_ROCKJAW_ARTIFACT, true);
        }

        void SuppressTriggerOnSelf(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_throw_priceless_artifact_SpellScript::GiveArtifact, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
            OnEffectHit += SpellEffectFn(spell_throw_priceless_artifact_SpellScript::SuppressTriggerOnSelf, EFFECT_1, SPELL_EFFECT_TRIGGER_MISSILE);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_throw_priceless_artifact_SpellScript();
    }
};

/*######
# spell_low_health
# 76143 - Low Health
######*/

class spell_low_health: public SpellScriptLoader
{
public:
    spell_low_health() : SpellScriptLoader("spell_low_health") { }

    class spell_low_health_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_low_health_SpellScript);

        void HandleDummyEffect(SpellEffIndex /*eff*/)
        {
            if (Creature* target = GetHitCreature())
            {
                target->setRegeneratingHealth(false);
                target->SetHealth(target->CountPctFromMaxHealth(10));
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_low_health_SpellScript::HandleDummyEffect, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_low_health_SpellScript();
    }
};

Position const RockjawInvaderSpawnPoints[7] =
{
    { -6237.6807f, 375.5191f,  385.44696f, 5.168368339538574218f },
    { -6299.6113f, 347.11978f, 377.25546f, 6.068230628967285156f },
    { -6208.724f,  354.3229f,  387.3534f,  4.338659286499023437f },
    { -6261.8228f, 371.06598f, 383.35944f, 5.383506298065185546f },
    { -6253.722f,  340.1389f,  382.50888f, 5.957066535949707031f },
    { -6286.6113f, 316.9566f,  376.9441f,  6.195390701293945312f },
    { -6204.599f,  304.64932f, 388.9596f,  2.362043619155883789f }
};

enum JorenIronstockData
{
    NPC_ROCKJAW_INVADER            = 37070,

    // creature_text stores his three lines as three separate groups, one line each, and
    // Talk() picks a group - so each one has to be asked for by name or it never plays.
    SAY_SHOOT_ROCKJAW              = 0,    // "Eat dwarven lead!"
    SAY_MELEE_ROCKJAW              = 1,    // "Get back, ye filthy beast!"
    SAY_BATTLE_CRY                 = 2,    // "For Ironforge!"

    // Upstream uses 70014, which nothing in this core references. 6660 is the
    // Shoot this core already uses for the Coldridge Defender riflemen (37177).
    SPELL_SHOOT                    = 6660,

    INVADER_DESPAWN_TIME           = 18 * IN_MILLISECONDS,

    // Time between the shot leaving the barrel and the invader dropping
    SHOT_TRAVEL_TIME               = 1,

    // He sights the shot for a beat once an invader is in range instead of snapping to it
    AIM_TIME_MIN                   = 1,
    AIM_TIME_MAX                   = 2,

    // Don't kill the invaders in one swing all the time
    MELEE_MAX_SWING_PCT            = 25,

    // Chance per melee swing that he lands a finishing blow.
    // He is "sparring" with them so normal attacks should not kill them
    MELEE_KILLING_BLOW_CHANCE      = 15,

    // How often he checks that his invaders are still coming for him instead of trading
    // blows with whatever stepped into their path, in milliseconds.
    INVADER_LEASH_INTERVAL         = 500,

    // He swings about once a second, so the melee bark needs a leash of its own
    SHOOT_BARK_CHANCE              = 50,
    MELEE_BARK_CHANCE              = 35,
    MELEE_BARK_COOLDOWN            = 6 * IN_MILLISECONDS,
    BATTLE_CRY_CHANCE              = 25
};

// Threat handed to an invader's rightful target on every leash tick. Everything else on
// its list is zeroed in the same breath, so any amount clear of zero holds the lead - this
// is just comfortably above what a stray attacker can pile on between two ticks.
float const INVADER_LEASH_THREAT = 500.0f;

// 37081 - Joren Ironstock
//
// He holds the pass and never leaves it, gunning down the invaders he summons. His summons
// fight only him or the first player to pull them. Anything that is not an invader gets a
// fight too, and the vignette pauses until he is clear of it.
struct npc_joren_ironstock : public ScriptedAI
{
    npc_joren_ironstock(Creature* creature) : ScriptedAI(creature) { }

    bool IsVignetteInvader(Unit const* who) const
    {
        return who && _invaders.find(who->GetGUID()) != _invaders.end();
    }

    static bool IsInvader(Unit const* who)
    {
        return who && who->GetEntry() == NPC_ROCKJAW_INVADER;
    }

    // True while something outside the vignette holds threat on him. Rockjaw Invaders never
    // count, whether they are his summons or one of the static spawns a Defender pushed his
    // way - either is a trogg on his doorstep and the vignette carries on around it.
    bool IsFightingOutsider() const
    {
        if (!me->IsInCombat())
            return false;

        for (HostileReference const* ref : me->getThreatManager().getThreatList())
            if (!IsInvader(ref->getTarget()))
                return true;

        return false;
    }

    // A level 65 dwarf can flatten a level 1 trogg in a single swing, which makes the melee
    // look like a bug rather than a brawl. Cap what he can take off an invader per hit so
    // it costs him a few swings. The rifle is unaffected - that one is meant to be lethal,
    // and it kills through Unit::Kill, which never reaches this hook.
    void DamageDealt(Unit* victim, uint32& damage, DamageEffectType damageType) override
    {
        if (damageType != DIRECT_DAMAGE || !IsInvader(victim))
            return;

        // Same guard the rifle uses: never take the kill out from under a player. An
        // invader a player has tagged is their quest credit, and Joren landing the
        // finishing blow would cost them it. He still swings, he just cannot finish it.
        bool const playerClaimed = victim->GetVictim() && victim->GetVictim()->GetTypeId() == TYPEID_PLAYER;

        if (!playerClaimed && roll_chance_i(MELEE_KILLING_BLOW_CHANCE))
        {
            damage = victim->GetHealth();
            return;
        }

        damage = std::min<uint32>(damage, std::max<uint32>(1, CalculatePct(victim->GetMaxHealth(), MELEE_MAX_SWING_PCT)));

        // Something got close enough to swing at - that is what the melee line is for
        if (!_meleeBarkCooldown && roll_chance_i(MELEE_BARK_CHANCE))
        {
            Talk(SAY_MELEE_ROCKJAW, victim);
            _meleeBarkCooldown = MELEE_BARK_COOLDOWN;
        }
    }

    void KilledUnit(Unit* victim) override
    {
        if (!IsInvader(victim))
            return;

        if (roll_chance_i(BATTLE_CRY_CHANCE))
            Talk(SAY_BATTLE_CRY);
    }

    void JustSummoned(Creature* summon) override
    {
        if (summon->GetEntry() != NPC_ROCKJAW_INVADER)
            return;

        _invaders.insert(summon->GetGUID());

        // Anchor their leash on Joren rather than on the spot they spawned at. A creature
        // gives up when its victim is further than ThreatRadius from its own home position
        // (Creature::CanCreatureAttack), and the outer spawn points are 60-73 yards out -
        // past the default 60 - so those invaders used to break off mid-charge and walk
        // back to their spawn. Their home is wherever Joren is standing; the charge is the
        // whole point of them.
        summon->SetHomePosition(me->GetPosition());
    }

    void SummonedCreatureDespawn(Creature* summon) override
    {
        _invaders.erase(summon->GetGUID());
        _invaderClaims.erase(summon->GetGUID());
    }

    // Who an invader is allowed to fight: Joren, or the first player to attack it. The
    // claim sticks for the invader's whole short life, so a Coldridge Defender wading in
    // afterwards cannot pull it off either of them.
    Unit* GetInvaderTarget(Creature* invader)
    {
        auto claim = _invaderClaims.find(invader->GetGUID());
        if (claim != _invaderClaims.end())
        {
            if (Player* claimant = ObjectAccessor::GetPlayer(*me, claim->second))
                if (claimant->IsAlive() && invader->IsValidAttackTarget(claimant))
                    return claimant;

            // Dead, gone, or no longer fair game - it goes back to running at Joren.
            _invaderClaims.erase(claim);
        }

        for (HostileReference const* ref : invader->getThreatManager().getThreatList())
        {
            Unit* hater = ref->getTarget();
            if (hater && hater->GetTypeId() == TYPEID_PLAYER && ref->getThreat() > 0.0f)
            {
                _invaderClaims[invader->GetGUID()] = hater->GetGUID();
                return hater;
            }
        }

        return me;
    }

    void LeashInvaders()
    {
        for (ObjectGuid const& guid : _invaders)
        {
            Creature* invader = ObjectAccessor::GetCreature(*me, guid);
            if (!invader || !invader->IsAlive() || !invader->IsAIEnabled)
                continue;

            Unit* target = GetInvaderTarget(invader);

            // Zero the rest rather than dropping them: the defender is still swinging, so
            // the reference comes straight back either way. It just never reaches the top
            // of the list, because the owner is topped up in the same pass.
            invader->getThreatManager().resetAggro([target](Unit* who) { return who != target; });
            invader->AddThreat(target, INVADER_LEASH_THREAT);

            if (invader->GetVictim() != target)
                invader->AI()->AttackStart(target);
        }
    }

    void EnqueueInvader(Unit* invader, Seconds minTime, Seconds maxTime)
    {
        _scheduler.Schedule(minTime, maxTime, [this, guid = invader->GetGUID()](TaskContext /*task*/)
        {
            _invadersToShoot.push(guid);
        });
    }

    void SummonInvader()
    {
        Creature* invader = me->SummonCreature(NPC_ROCKJAW_INVADER, Trinity::Containers::SelectRandomContainerElement(RockjawInvaderSpawnPoints), TEMPSUMMON_CORPSE_TIMED_DESPAWN, INVADER_DESPAWN_TIME);
        if (!invader)
            return;

        // Invaders that walk into his line of fire get shot sooner
        if (me->HasInArc(float(M_PI), invader) && !me->IsInCombat())
            EnqueueInvader(invader, Seconds(1), Seconds(3));
        else
            EnqueueInvader(invader, Seconds(5), Seconds(8));

        invader->AI()->AttackStart(me);

        // Put him on Joren's threat list straight away, at zero threat.
        // Without this, killing the invader he is currently shooting empties his threat
        // list, Creature::SelectVictim finds nothing and evades him, and CombatStop drops
        // every other invader's aggro - so the ones still charging turn around and go home.
        me->AddThreat(invader, 0.0f);
    }

    // Mirrors what Spell::GetMinMaxRange works out for the shot, so the queue only offers
    // him targets the cast will actually accept.
    bool IsInShootingRange(Unit const* invader) const
    {
        SpellInfo const* shoot = sSpellMgr->GetSpellInfo(SPELL_SHOOT);
        if (!shoot)
            return false;

        float maxRange = me->GetSpellMaxRangeForTarget(invader, shoot) + me->GetCombatReach() + invader->GetCombatReach();
        return me->GetExactDist(invader) <= maxRange;
    }

    void FireAt(ObjectGuid guid, TaskContext& task)
    {
        Creature* invader = ObjectAccessor::GetCreature(*me, guid);
        if (!invader || !invader->IsAlive())
            return;

        // Don't snipe a kill out from under a player - wait until they are done with it
        if (invader->GetVictim() && invader->GetVictim()->GetTypeId() == TYPEID_PLAYER)
        {
            _invadersToShoot.push(guid);
            return;
        }

        // Moved back out of range or behind cover while he was lining it up
        if (!IsInShootingRange(invader) || !me->CastSpell(invader, SPELL_SHOOT, false))
        {
            _invadersToShoot.push(guid);
            return;
        }

        if (roll_chance_i(SHOOT_BARK_CHANCE))
            Talk(SAY_SHOOT_ROCKJAW, invader);

        // One shot, one invader. Wait for the bullet to land before dropping him.
        task.Schedule(Seconds(SHOT_TRAVEL_TIME), [this, guid](TaskContext /*killTask*/)
        {
            Creature* target = ObjectAccessor::GetCreature(*me, guid);
            if (target && target->IsAlive())
                me->Kill(target);
        });
    }

    void ShootNextInvader(TaskContext& task)
    {
        // Take the first invader that has closed to within rifle range. The ones still
        // running in keep their place in the queue, instead of wasting this tick on a
        // target he cannot reach yet.
        for (size_t remaining = _invadersToShoot.size(); remaining > 0; --remaining)
        {
            ObjectGuid guid = _invadersToShoot.front();
            _invadersToShoot.pop();

            Creature* invader = ObjectAccessor::GetCreature(*me, guid);
            if (!invader || !invader->IsAlive())
                continue; // gone for good, drop it from the queue

            if (!IsInShootingRange(invader))
            {
                _invadersToShoot.push(guid);
                continue;
            }

            // He takes a beat to sight the shot rather than firing the instant they cross
            // into range.
            task.Schedule(Seconds(AIM_TIME_MIN), Seconds(AIM_TIME_MAX), [this, guid](TaskContext shot)
            {
                FireAt(guid, shot);
            });

            return;
        }
    }

    // Re-applied on every evade and respawn, not just once, so he cannot drift off his post.
    void Reset() override
    {
        // He never chases - they come to him.
        SetCombatMovement(false);
        me->SetReactState(REACT_DEFENSIVE);
    }

    void InitializeAI() override
    {
        ScriptedAI::InitializeAI();

        _scheduler.Schedule(Seconds(1), [this](TaskContext task)
        {
            if (IsFightingOutsider())
            {
                // Hold the vignette until he is out of combat with whatever that was
                task.Repeat(Seconds(2));
                return;
            }

            SummonInvader();
            task.Repeat(Seconds(3), Seconds(20));
        });

        _scheduler.Schedule(Seconds(1), [this](TaskContext task)
        {
            ShootNextInvader(task);
            task.Repeat(Seconds(1));
        });

        _scheduler.Schedule(Milliseconds(INVADER_LEASH_INTERVAL), [this](TaskContext task)
        {
            LeashInvaders();
            task.Repeat();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);

        if (_meleeBarkCooldown > diff)
            _meleeBarkCooldown -= diff;
        else
            _meleeBarkCooldown = 0;

        if (!UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }

private:
    TaskScheduler _scheduler;
    std::queue<ObjectGuid> _invadersToShoot;
    GuidUnorderedSet _invaders;
    std::unordered_map<ObjectGuid, ObjectGuid> _invaderClaims;
    uint32 _meleeBarkCooldown = 0;
};

void AddSC_dun_morogh_area_coldridge_valley()
{
    new npc_wounded_coldridge_mountaineer();
    new npc_wounded_milita();
    new npc_milos_gyro();
    new npc_hands_springsprocket();
    new spell_a_trip_to_ironforge_quest_complete();
    new spell_follow_that_gyrocopter_quest_start();
    new spell_low_health();
    new spell_throw_priceless_artifact();
    RegisterCreatureAI(npc_joren_ironstock);
}
