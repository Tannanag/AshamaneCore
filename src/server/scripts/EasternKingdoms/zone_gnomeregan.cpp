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

/* ScriptData
SDName: Gnomeregan
SD%Complete: Intro
SDComment: Quest Support: 27635, 28169
SDCategory: Gnomeregan
EndScriptData */

#include "Creature.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Vehicle.h"
#include "MotionMaster.h"
#include "TemporarySummon.h"
#include "GameObject.h"

enum GnomeCreatureIds
{
    NPC_DECONTAMINATION_BUNNY = 46165,
    NPC_SANITRON_5000         = 46185,
    NPC_CLEAN_CANNON          = 46208,
    NPC_SAFE_TECHNICAN        = 46230,
    NPC_NEVIN_TWISTWRENCH     = 46293,
    NPC_IMUN_AGENT            = 47836
};

enum GnomeSpells
{
    SPELL_CANNON_BURST          = 86080,
    SPELL_DECONTAMINATE_STAGE_1 = 86075,
    SPELL_DECONTAMINATE_STAGE_2 = 86086,
    SPELL_IRRADIATE             = 80653,
    SPELL_EXPLOSION             = 30934
};

enum GnomeQuests
{
    QUEST_DECONTAMINATION              = 27635,
    QUEST_WITHDRAW_TO_THE_LOADING_ROOM = 28169
};

enum GnomeGossips
{
    GOSSIP_TORBEN      = 12104
};

enum GnomeMoves
{
    MOVE_IMUN_AGENT = 4783600
};

// Unit::SetSpeed takes yards per second, not a rate -- it divides by the base
// speed itself. Path 4783600 is 201 yards of walkway and its last two points
// hold the agent for three seconds and then despawn it, so the whole run has to
// fit inside the summon's 60 second life. At 6.4 the agent is at the Loading
// Room around 37 seconds in, with the delay counted.
float const SPEED_IMUN_AGENT = 6.4f;

// The wash ends with the machine blowing itself up, so it has to come back for
// the next player rather than sit out creature.spawntimesecs, which is 300 on
// all three spawns. A timer inside the AI cannot do it: Creature::Update only
// ticks UpdateAI while the creature is alive, which is why the uiRespawnTimer
// this replaces was initialised in Reset() and then never read anywhere. The
// delay is handed to Creature::ForcedDespawn instead, which also takes the
// wreck away with the explosion instead of leaving it lying there for the
// corpse decay time.
Seconds const SANITRON_RESPAWN_DELAY = Seconds(6);

Position const SpawnPosition = { -4981.25f, 780.992f, 288.485f, 3.316f };

class npc_nevin_twistwrench : public CreatureScript
{
public:
    npc_nevin_twistwrench() : CreatureScript("npc_nevin_twistwrench") { }

    struct npc_nevin_twistwrenchAI : public ScriptedAI
    {
        npc_nevin_twistwrenchAI(Creature* creature) : ScriptedAI(creature) { }

        void MoveInLineOfSight(Unit * who) override
        {
            if (who->IsPlayer() && who->IsWithinDist(me, 10.f) && !who->HasAura(SPELL_IRRADIATE)
                && who->ToPlayer()->GetQuestStatus(QUEST_DECONTAMINATION) == QUEST_STATUS_NONE)
                who->CastSpell(who, SPELL_IRRADIATE, true);
        }
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_nevin_twistwrenchAI(creature);
    }

};

class npc_carvo_blastbolt : public CreatureScript
{
public:
    npc_carvo_blastbolt() : CreatureScript("npc_carvo_blastbolt") { }

    bool OnQuestAccept(Player* player, Creature* /*creature*/, Quest const* quest) override
    {
        if (quest->GetQuestId() == QUEST_WITHDRAW_TO_THE_LOADING_ROOM)
        {
            if (TempSummon* agent = player->SummonCreature(NPC_IMUN_AGENT, SpawnPosition, TEMPSUMMON_TIMED_DESPAWN, 60000, 0, true))
            {
                agent->SetSpeed(MOVE_RUN, SPEED_IMUN_AGENT);

                // The summoner link a TempSummon keeps is server-side only, so the
                // client is told separately who the agent belongs to. Only the creator
                // field is set: SetOwnerGUID would also feed GetCharmerOrOwner, the
                // speed floor and attack validity, none of which this agent wants.
                agent->SetCreatorGUID(player->GetGUID());

                // UNIT_FLAG_PLAYER_CONTROLLED is what makes the name blue. The client
                // colours a player controlled unit by whether it can be attacked and
                // whether it is pvp flagged, and lands on blue when it is neither; a
                // creature without the flag skips all of that and is coloured green by
                // reaction instead. The agent never joins the player's controlled list,
                // so Player::SetPvP cannot reach it and the name stays blue even when
                // the player is flagged.
                //
                // Immune, but not hidden from the mouse -- the agent stays clickable
                // so the player can see whose it is and read its name on the way.
                agent->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PLAYER_CONTROLLED | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
                agent->SetReactState(REACT_PASSIVE);
                agent->AI()->Talk(0, player);
                agent->GetMotionMaster()->MovePath(MOVE_IMUN_AGENT, false);
            }
        }

        return true;
    }
};

class npc_sanitron_5000 : public CreatureScript
{
public:
    npc_sanitron_5000() : CreatureScript("npc_sanitron_5000") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (player->GetQuestStatus(QUEST_DECONTAMINATION) == QUEST_STATUS_INCOMPLETE)
        {
            player->HandleEmoteCommand(0);
            creature->GetVehicleKit();
            player->EnterVehicle(creature->ToUnit(), 0);
            creature->AI()->Talk(0);
        }
        return true;
    }

    struct npc_sanitron_5000AI : public ScriptedAI
    {
        npc_sanitron_5000AI(Creature* creature) : ScriptedAI(creature), _vehicle(creature->GetVehicleKit())
        {
            ASSERT(_vehicle); // we dont actually use it, just check if exists
        }

        void Reset() override
        {
            uiTimer = 0;
            uiPhase = 0;

            // 46185 is InhabitType 4, so the machine hovers, and Creature::UpdateMovementFlags
            // hands out MOVEMENTFLAG_DISABLE_GRAVITY every tick to keep it up. It gets that
            // right on a first spawn and never again once the wash has run, because the
            // despawn that ends the run poisons it.
            //
            // DespawnOrUnsummon goes through Creature::ForcedDespawn, which kills the machine
            // first, and setDeathState JUST_DIED drops a flying corpse with MoveFall -- whose
            // first act is SetFall(true). RemoveCorpse follows immediately and only calls
            // StopMoving, so the spline ends and the flag does not. The Sanitron comes back
            // six seconds later still flagged as falling, and the two halves of
            // UpdateMovementFlags then deadlock: it will not grant disable-gravity while
            // IsFalling() is true, and it only clears the fall for a creature that is not
            // airborne -- and this one respawns on its walkway, off the floor. Neither can be
            // met, so the tick that would repair it re-asserts the break instead.
            //
            // The result is a used machine that sits on the ground while the ones nobody has
            // ridden still hover. Clearing the fall here breaks the deadlock, and the gravity
            // is set directly too so the first frame after the respawn is already right.
            // Reset is the place for it: Creature::Respawn runs it after
            // setDeathState(JUST_RESPAWNED), so it lands last.
            //
            // Same trap, and the same fix, as npc_target_acquisition_device in
            // zone_dun_morogh_area_new_tinkertown.cpp.
            me->SetFall(false);
            me->SetDisableGravity(true);
        }

        void JustRespawned() override
        {
            ScriptedAI::JustRespawned();

            // Creature::setDeathState puts UNIT_NPC_FLAGS back to what
            // ObjectMgr::ChooseCreatureFlags reads off the template and the spawn
            // row, and both of those are 0 here. The spell click flag the machine
            // is clicked with is not in either: Vehicle::Vehicle sets it once at
            // creation, from the seat count. Without putting it back the respawned
            // Sanitron has no cursor and no one can ride it again.
            if (_vehicle->HasEmptySeat(0))
                me->SetFlag64(UNIT_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);
        }

        void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
        {
            // A player who leaves the seat part way through the wash -- logging
            // out, or being pulled off it -- would otherwise strand the machine.
            // UpdateAI returns on an empty seat, so uiPhase stops where it was
            // and the Sanitron is left standing out on the walkway for the next
            // player to board half way through the sequence. Phase 10 is the end
            // of the run taking its own passenger off, which is not that.
            if (apply || !passenger->IsPlayer() || uiPhase >= 10)
                return;

            // Delayed a second rather than despawned from inside
            // Vehicle::RemovePassenger, which is still working on the seat it is
            // calling us about.
            me->DespawnOrUnsummon(1 * IN_MILLISECONDS, SANITRON_RESPAWN_DELAY);
        }

        void GetTargets()
        {
            std::list<Creature*> targets = me->FindAllCreaturesInRange(100.0f);

            for (auto itr : targets)
            {
                switch (itr->GetEntry())
                {
                    case NPC_SAFE_TECHNICAN:
                        if (itr->GetDistance2d(-5165.209961f, 713.809021f) <= 1)
                            TechnicianGUID = itr->GetGUID();
                        break;
                    case NPC_DECONTAMINATION_BUNNY:
                        if (itr->GetDistance2d(-5164.919922f, 723.890991f) <= 1)
                            BunnyGUID[0] = itr->GetGUID();
                        if (itr->GetDistance2d(-5182.560059f, 726.656982f) <= 1)
                            BunnyGUID[1] = itr->GetGUID();
                        if (itr->GetDistance2d(-5166.350098f, 706.336975f) <= 1)
                            BunnyGUID[2] = itr->GetGUID();
                        if (itr->GetDistance2d(-5184.040039f, 708.405029f) <= 1)
                            BunnyGUID[3] = itr->GetGUID();
                        break;
                    case NPC_CLEAN_CANNON:
                        if (itr->GetDistance2d(-5164.209961f, 719.267029f) <= 1)
                            CannonGUID[0] = itr->GetGUID();
                        if (itr->GetDistance2d(-5165.000000f, 709.453979f) <= 1)
                            CannonGUID[1] = itr->GetGUID();
                        if (itr->GetDistance2d(-5183.830078f, 722.093994f) <= 1)
                            CannonGUID[2] = itr->GetGUID();
                        if (itr->GetDistance2d(-5184.470215f, 712.554993f) <= 1)
                            CannonGUID[3] = itr->GetGUID();
                        break;
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (_vehicle->HasEmptySeat(0))
                return;

            if (uiTimer <= diff)
            {
                if (Unit* passenger = _vehicle->GetPassenger(0))
                {
                    if (Player* player = passenger->ToPlayer())
                    {
                        switch (uiPhase)
                        {
                            case 0:
                                ++uiPhase;
                                uiTimer = 2500;
                                break;
                            case 1:
                                me->GetMotionMaster()->MovePoint(1, -5173.34f, 730.11f, 294.25f);
                                GetTargets();
                                ++uiPhase;
                                uiTimer = 3000;
                                break;
                            case 2:
                                for (uint8 i = 0; i < 2; ++i)
                                    if (Creature* bunny = ObjectAccessor::GetCreature(*me, BunnyGUID[i]))
                                        bunny->CastSpell(player, SPELL_DECONTAMINATE_STAGE_1, true);

                                ++uiPhase;
                                uiTimer = 1500;
                                break;
                            case 3:
                                me->GetMotionMaster()->MovePoint(2, -5173.72f, 725.7f, 294.03f);
                                ++uiPhase;
                                uiTimer = 500;
                                break;
                            case 4:
                                me->GetMotionMaster()->MovePoint(3, -5174.57f, 716.45f, 289.53f);
                                ++uiPhase;
                                uiTimer = 3000;
                                break;
                            case 5:
                                for (uint8 i = 0; i < 4; ++i)
                                    if (Creature* cannon = ObjectAccessor::GetCreature(*me, CannonGUID[i]))
                                        cannon->CastSpell(player, SPELL_CANNON_BURST, true);

                                ++uiPhase;
                                uiTimer = 4000;
                                break;
                            case 6:
                                if (Creature* technician = ObjectAccessor::GetCreature(*me, TechnicianGUID))
                                    technician->AI()->Talk(0);
                                me->GetMotionMaster()->MovePoint(4, -5175.04f, 707.2f, 294.4f);
                                ++uiPhase;
                                uiTimer = 4000;
                                break;
                            case 7:
                                for (uint8 i = 2; i < 4; ++i)
                                    if (Creature* bunny = ObjectAccessor::GetCreature(*me, BunnyGUID[i]))
                                        bunny->CastSpell(player, SPELL_DECONTAMINATE_STAGE_2, true);

                                player->RemoveAurasDueToSpell(SPELL_IRRADIATE);
                                ++uiPhase;
                                uiTimer = 1000;
                                break;
                            case 8:
                                // TalkedToCreature rather than CompleteQuest. 27635's one
                                // objective is a TALKTO on 46185 -- "Decontamination Process
                                // started" -- and CompleteQuest sets the quest status without
                                // ever crediting it, so the objective stayed at 0/1 and the
                                // player got no credit for the wash.
                                //
                                // TalkedToCreature fills the objective, sends the client its
                                // SendQuestUpdateAddCredit so the log ticks over, and then
                                // completes the quest itself through CanCompleteQuest. The
                                // gate it checks passes here because ObjectMgr gives any
                                // quest with a TALKTO objective QUEST_SPECIAL_FLAGS_SPEAKTO.
                                player->TalkedToCreature(NPC_SANITRON_5000, me->GetGUID());
                                Talk(1);
                                me->GetMotionMaster()->MovePoint(5, -5175.61f, 700.38f, 290.89f);
                                ++uiPhase;
                                uiTimer = 3000;
                                break;
                            case 9:
                                Talk(2);
                                me->CastSpell(me, SPELL_EXPLOSION);
                                ++uiPhase;
                                uiTimer = 1000;
                                break;
                            case 10:
                                _vehicle->RemoveAllPassengers();
                                me->DespawnOrUnsummon(0, SANITRON_RESPAWN_DELAY);
                                ++uiPhase;
                                uiTimer = 0;
                                break;
                        }
                    }
                }

            }
            else uiTimer -= diff;
        }

    private:
        Vehicle* _vehicle;

        ObjectGuid TechnicianGUID;
        ObjectGuid BunnyGUID[4] = {};
        ObjectGuid CannonGUID[4] = {};

        uint32 uiTimer;
        uint8 uiPhase;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_sanitron_5000AI(creature);
    }
};

class npc_gnomeregan_torben : public CreatureScript
{
public:
    npc_gnomeregan_torben() : CreatureScript("npc_gnomeregan_torben") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        AddGossipItemFor(player, GOSSIP_TORBEN, 1, GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);
        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());

        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);
        if (action == GOSSIP_ACTION_INFO_DEF + 1)
        {
            player->KilledMonsterCredit(NPC_NEVIN_TWISTWRENCH);
            player->TeleportTo(0, -5201.58f, 477.98f, 388.47f, 5.13f);
            CloseGossipMenuFor(player);
        }
        return true;
    }
};

struct npc_multi_bot : public ScriptedAI
{
    npc_multi_bot(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->GetScheduler().Schedule(2s, [this](TaskContext context)
        {
            if (GameObject* gobject = me->FindNearestGameObject(203975, 5))
            {
                if (Player* owner = me->GetOwner()->ToPlayer())
                {
                    Talk(0);
                    gobject->SetGoState(GO_STATE_ACTIVE);
                    me->CastSpell(me, 79424, true);
                    me->CastSpell(me, 79422, true);
                }
            }
            
            context.Repeat();
        });
    }
};

void AddSC_zone_gnomeregan()
{
    new npc_nevin_twistwrench();
    new npc_carvo_blastbolt();
    new npc_sanitron_5000();
    new npc_gnomeregan_torben();
    RegisterCreatureAI(npc_multi_bot);
}

