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
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiersImpl.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "PassiveAI.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "TaskScheduler.h"
#include "TemporarySummon.h"
#include "WaypointManager.h"
#include <G3D/Vector3.h>
#include <array>

// The Wisps (48624) of Shadowglen and Dolanaar each fly one fixed CatmullRom path,
// forever, at their run speed of 8 yd/s. Retail sends it in one of two ways and the
// path decides which:
//
// - a closed loop, sent once as a cyclic spline in the create block and never
//   followed by another movement packet -- 15 of the 23 sniffed wisps;
// - a rising helix around a tree trunk, sent as a plain spline from the foot to the
//   top; at the top the wisp is teleported back to the foot and the same spline is
//   sent again -- the other 8.
//
// The core has no cyclic waypoint mode and its waypoint generator stops and re-aims
// at every node, which segments a curve like this badly, so the AI drives the spline
// itself. The nodes come from the waypoint_data path the spawn's creature_addon
// names, which keeps the data in SQL where the rest of the movement work lives, and
// keeps this AI free of coordinates. The spawn keeps MovementType 0: a random or
// waypoint generator would call StopMoving() under the spline.
//
// A path is a loop when getting from its last node back to its first is just another
// leg -- for the sniffed loops the closing leg is never longer than the longest leg
// in the path, and for every helix it is at least three times longer (a 22-45 yd
// climb against legs of 5-9 yd). 1.5x sits in the middle of that gap.
//
// The velocity is deliberately not set: with DisableGravity and no FLYING movement
// flag, MoveSplineInit picks the run speed, and 8.0 is what the sniff shows even
// though the template's flight speed is 7.
struct npc_wisp_flight_path : public NullCreatureAI
{
    npc_wisp_flight_path(Creature* creature) : NullCreatureAI(creature) { }

    void UpdateAI(uint32 /*diff*/) override
    {
        // True at spawn, after anything that stopped the wisp, and -- for a helix --
        // every time it reaches the top. A loop's cyclic spline never finalizes.
        if (!me->movespline->Finalized())
            return;

        WaypointPath const* path = sWaypointMgr->GetPath(me->GetWaypointPath());
        if (!path || path->size() < 3)
            return;

        // Retail snaps a helix wisp back to the foot with a teleport between laps,
        // and a loop that was interrupted mid-lap would otherwise gain the point it
        // stopped at as an extra node. Node 1 is the spawn point, so at spawn this
        // is a no-op.
        WaypointData const* first = path->front();
        if (me->GetExactDist(first->x, first->y, first->z) > 0.5f)
            me->NearTeleportTo(first->x, first->y, first->z, me->GetOrientation());

        Movement::MoveSplineInit init(me);
        // MoveSplineInit::Launch overwrites the first point with the current position.
        init.Path().emplace_back(first->x, first->y, first->z);
        for (size_t i = 1; i < path->size(); ++i)
            init.Path().emplace_back((*path)[i]->x, (*path)[i]->y, (*path)[i]->z);

        init.SetFly();
        init.SetSmooth();
        init.SetUncompressed();
        if (IsClosedLoop(init.Path()))
            init.SetCyclic();
        init.Launch();
    }

private:
    static bool IsClosedLoop(Movement::PointsArray const& points)
    {
        float longestLeg = 0.0f;
        for (size_t i = 1; i < points.size(); ++i)
            longestLeg = std::max(longestLeg, (points[i] - points[i - 1]).length());

        return (points.front() - points.back()).length() <= longestLeg * 1.5f;
    }
};

// Moriana Dawnlight (34756) and Doranel Amberleaf (34757) stand together at the top
// of Aldrassil and, when a player steps between them, Amberleaf voices her doubts
// about Fandral, Dawnlight hushes her, and both turn to look at the player before
// turning back. In the 14 Sep sniff the scene is not an OOC line-of-sight bark: it
// fires on areatrigger 5481 (r 3.95 at 10452.4, 843.4, the spot between them) and
// only on entering it -- the client sends the leave 1.2 s later and nothing answers
// it. SmartTrigger fires SMART_EVENT_AREATRIGGER_ONTRIGGER on leave as well, and
// SMART_ACTION_SET_DATA drops the invoker, so a SmartAI build could neither ignore
// the leave nor have the two face the player; hence the C++.
//
// Dawnlight owns the lockout. At T0 she casts 88811 "CSA Area Trigger Dummy Timer
// Aura" on herself, a 30 s dummy, and while she carries it the trigger does nothing:
// at 23:39:15 another player set the scene off and the sniffed player's own entry
// at 23:39:36 was ignored. Offsets below are from her cast, identical in both runs
// the player caused (23:08:18 and 23:10:18):
//   +0.1 s  Amberleaf: "Don't get me wrong... What happened to Fandral?"
//   +3.2 s  Dawnlight: "Shh! Someone's here."
//   +4.3 s  both face the player (MonsterMove Face: Target)
//  +15.2 s  both face their spawn orientation again (Face: Angle 5.0615 / 2.0246)
enum DawnlightAmberleafData
{
    NPC_MORIANA_DAWNLIGHT                       = 34756,
    NPC_DORANEL_AMBERLEAF                       = 34757,
    SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA     = 88811,

    SAY_AMBERLEAF_WHAT_HAPPENED_TO_FANDRAL      = 0,
    SAY_DAWNLIGHT_SOMEONE_IS_HERE               = 0
};

struct npc_moriana_dawnlight : public ScriptedAI
{
    npc_moriana_dawnlight(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
    }

    // Called by the areatrigger script with the player who stepped on 5481.
    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        // The aura is the lockout, as on retail: no restart, no queue.
        if (me->HasAura(SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA))
            return;

        // Amberleaf spawns 1.4 yd from her; if she is not there (dead, despawned)
        // there is no conversation to have.
        Creature* amberleaf = me->FindNearestCreature(NPC_DORANEL_AMBERLEAF, 10.0f);
        if (!amberleaf)
            return;

        _playerGUID = guid;
        _amberleafGUID = amberleaf->GetGUID();
        _scheduler.CancelAll();

        // A real cast -- the sniff has SMSG_SPELL_START and SMSG_SPELL_GO for it,
        // not just the aura update. Cast time is 0 so nothing waits on it.
        DoCastSelf(SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA);

        _scheduler.Schedule(Milliseconds(100), [this](TaskContext /*task*/)
        {
            if (Creature* amberleaf = GetAmberleaf())
                amberleaf->AI()->Talk(SAY_AMBERLEAF_WHAT_HAPPENED_TO_FANDRAL);
        });

        _scheduler.Schedule(Milliseconds(3200), [this](TaskContext /*task*/)
        {
            Talk(SAY_DAWNLIGHT_SOMEONE_IS_HERE);
        });

        _scheduler.Schedule(Milliseconds(4300), [this](TaskContext /*task*/)
        {
            // The player may have logged out or moved out of range in the 4 s; the
            // scene still finishes, they just do not turn.
            if (Player* player = ObjectAccessor::GetPlayer(*me, _playerGUID))
            {
                me->SetFacingToObject(player);
                if (Creature* amberleaf = GetAmberleaf())
                    amberleaf->SetFacingToObject(player);
            }
        });

        _scheduler.Schedule(Milliseconds(15200), [this](TaskContext /*task*/)
        {
            // Spawn orientation, not a fixed angle: both spawns sit on the sniffed
            // marks to the bit and MovementType 0 keeps the home position there.
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
            if (Creature* amberleaf = GetAmberleaf())
                amberleaf->SetFacingTo(amberleaf->GetHomePosition().GetOrientation());
        });
    }

    void UpdateAI(uint32 diff) override
    {
        // Out of combat too -- the whole scene is out of combat.
        _scheduler.Update(diff);

        if (!UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }

private:
    Creature* GetAmberleaf() const
    {
        return ObjectAccessor::GetCreature(*me, _amberleafGUID);
    }

    TaskScheduler _scheduler;
    ObjectGuid _playerGUID;
    ObjectGuid _amberleafGUID;
};

// Areatrigger 5481, the spot between the two.
class at_aldrassil_dawnlight_amberleaf : public AreaTriggerScript
{
public:
    at_aldrassil_dawnlight_amberleaf() : AreaTriggerScript("at_aldrassil_dawnlight_amberleaf") { }

    bool OnTrigger(Player* player, AreaTriggerEntry const* /*trigger*/, bool entered) override
    {
        // The client reports the leave too, about a second later; retail answers
        // only the entry.
        if (!entered || !player->IsAlive())
            return false;

        // 11 yd from the trigger centre to the pair.
        Creature* dawnlight = player->FindNearestCreature(NPC_MORIANA_DAWNLIGHT, 30.0f);
        if (!dawnlight)
            return false;

        dawnlight->AI()->SetGUID(player->GetGUID());
        return true;
    }
};

// Ilthalaine (2079) and the Huntress Sandrya Moonfall (49477) / Dentaria Silverglade
// (49478) scene at the turn-in of 28713 "The Balance of Nature".
//
// Retail keeps three Ilthalaines up at once, one per quest step, under quest
// invisibility auras that the player's own detection aura picks from (creature_addon
// and spell_area, 2026_09_16_04_world.sql). The one under 49414 -- v2, visible from
// 28713's objectives completing until 28714's -- is the one the huntresses come to
// see. They are per-player summons: the 14 Sep sniff creates them (CreatedBy = the
// player, aura 163465) in the same packet burst as QUEST_UPDATE_COMPLETE 28713.
// From then until the turn-in Sandrya and Ilthalaine v2 trade OneShotTalk emotes at
// random 2.4-7.2 s intervals, always a multiple of 1.2 s; alone, Ilthalaine settles
// to a steady 7.2 s. T0 = CMSG_QUEST_GIVER_CHOOSE_REWARD:
//   +0.15  Ilthalaine v2 turns to Sandrya (5.2185) and says his line
//   +8.3   Sandrya's line
//   +16.8  Dentaria's first line, +22.8 her second (to the player, $n)
//   +27.7  Sandrya runs off south at her run speed of 9.7 yd/s, Dentaria at +28.9
//   +36.2  Ilthalaine turns back to his spawn orientation; his emotes resume
//   +37.4 / +39.4  Sandrya / Dentaria destroyed at the end of their runs
// Every line carries a talk emote (creature_text.Emote). The summons are not
// summoner-only: anyone at the same quest step carries the type-7 detection and sees
// every player's pair, as the sniffer saw another player's at 23:16:28.
//
// A pair that has outlived its reason goes: the huntresses poll their summoner every
// 2 s and despawn when he has left the map or 28713 is no longer COMPLETE
// (abandoned), unless their scene is running. The pair is also summoned when a
// player with 28713 COMPLETE enters Shadowglen -- login included -- and, as a last
// resort, at the turn-in itself, so the scene never plays to an empty spot.
enum IlthalaineData
{
    NPC_ILTHALAINE                          = 2079,
    NPC_HUNTRESS_SANDRYA_MOONFALL           = 49477,
    NPC_DENTARIA_SILVERGLADE                = 49478,

    QUEST_THE_BALANCE_OF_NATURE             = 28713,
    AREA_SHADOWGLEN                         = 188,

    // On the v2 spawn (creature_addon); marks the Ilthalaine the huntresses talk to.
    SPELL_GENERIC_QUEST_INVISIBILITY_7      = 49414,

    SAY_ILTHALAINE_NONE_ARE_READY           = 0,
    SAY_SANDRYA_TIME_NOT_ON_OUR_SIDE        = 0,
    SAY_DENTARIA_LEAVE_YOU_TO_TRAINING      = 0,
    SAY_DENTARIA_STUDY_WELL                 = 1,

    ACTION_HUNTRESS_SCENE_STARTED           = 1,
    ACTION_HUNTRESS_LEAVE                   = 2,

    GROUP_IDLE_TALK                         = 1
};

Position const HuntressSandryaSpawn  = { 10314.459f, 826.6042f, 1326.4797f, 2.1468f };
Position const HuntressDentariaSpawn = { 10316.962f, 827.2656f, 1326.4653f, 2.4435f };
float const IlthalaineFacingSandrya  = 5.2185f;

std::array<G3D::Vector3, 4> const HuntressSandryaLeavePath =
{{
    { 10335.50f, 796.25f, 1325.77f },
    { 10346.11f, 778.41f, 1324.82f },
    { 10349.21f, 761.46f, 1324.36f },
    { 10343.50f, 744.47f, 1326.62f }
}};

std::array<G3D::Vector3, 4> const HuntressDentariaLeavePath =
{{
    { 10338.36f, 797.35f, 1325.00f },
    { 10349.53f, 779.83f, 1324.18f },
    { 10353.87f, 762.19f, 1323.14f },
    { 10347.22f, 740.51f, 1325.35f }
}};

// 2.4, 3.6, 4.8, 6.0 or 7.2 s.
Milliseconds RandomTalkInterval()
{
    return Milliseconds(1200 * urand(2, 6));
}

struct HuntressOfPlayerCheck
{
    HuntressOfPlayerCheck(uint32 entry, ObjectGuid const& summoner) : _entry(entry), _summoner(summoner) { }

    bool operator()(Creature* creature) const
    {
        if (creature->GetEntry() != _entry)
            return false;

        TempSummon const* summon = creature->ToTempSummon();
        return summon && summon->GetSummonerGUID() == _summoner;
    }

private:
    uint32 _entry;
    ObjectGuid _summoner;
};

// The player's own huntress of that entry, if she is up. The search is around the
// spawn spot, not the player: he may be anywhere in Shadowglen.
Creature* FindHuntressOf(Player* player, uint32 entry)
{
    std::list<Creature*> found;
    HuntressOfPlayerCheck check(entry, player->GetGUID());
    Trinity::CreatureListSearcher<HuntressOfPlayerCheck> searcher(player, found, check);
    Cell::VisitGridObjects(HuntressSandryaSpawn.GetPositionX(), HuntressSandryaSpawn.GetPositionY(), player->GetMap(), searcher, 30.0f);
    return found.empty() ? nullptr : found.front();
}

// Summons whichever of the pair the player does not have yet.
void SummonHuntressesFor(Player* player)
{
    if (player->GetMapId() != MAP_KALIMDOR)
        return;

    if (!FindHuntressOf(player, NPC_HUNTRESS_SANDRYA_MOONFALL))
        player->SummonCreature(NPC_HUNTRESS_SANDRYA_MOONFALL, HuntressSandryaSpawn);
    if (!FindHuntressOf(player, NPC_DENTARIA_SILVERGLADE))
        player->SummonCreature(NPC_DENTARIA_SILVERGLADE, HuntressDentariaSpawn);
}

struct npc_ilthalaine : public ScriptedAI
{
    npc_ilthalaine(Creature* creature) : ScriptedAI(creature), _scenesRunning(0) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        _scenesRunning = 0;

        // Only v2 chats with the huntresses. The addon aura that marks him is on by
        // the time the creature is in the world, which Reset() need not be.
        _scheduler.Schedule(Seconds(1), [this](TaskContext /*task*/)
        {
            if (me->HasAura(SPELL_GENERIC_QUEST_INVISIBILITY_7))
                StartIdleTalk();
        });
    }

    void sQuestReward(Player* player, Quest const* quest, uint32 /*opt*/) override
    {
        if (quest->GetQuestId() != QUEST_THE_BALANCE_OF_NATURE)
            return;

        SummonHuntressesFor(player);
        Creature* sandrya = FindHuntressOf(player, NPC_HUNTRESS_SANDRYA_MOONFALL);
        Creature* dentaria = FindHuntressOf(player, NPC_DENTARIA_SILVERGLADE);
        if (!sandrya || !dentaria)
            return;

        sandrya->AI()->DoAction(ACTION_HUNTRESS_SCENE_STARTED);
        dentaria->AI()->DoAction(ACTION_HUNTRESS_SCENE_STARTED);

        // Two players turning in within 36 s of each other get two scenes at once,
        // each talking to its own pair; he stays quiet until the last one is over.
        ++_scenesRunning;
        _scheduler.CancelGroup(GROUP_IDLE_TALK);

        ObjectGuid playerGUID = player->GetGUID();
        ObjectGuid sandryaGUID = sandrya->GetGUID();
        ObjectGuid dentariaGUID = dentaria->GetGUID();

        _scheduler.Schedule(Milliseconds(150), [this, playerGUID](TaskContext /*task*/)
        {
            me->SetFacingTo(IlthalaineFacingSandrya);
            Talk(SAY_ILTHALAINE_NONE_ARE_READY, ObjectAccessor::GetPlayer(*me, playerGUID));
        });

        _scheduler.Schedule(Milliseconds(8300), [this, playerGUID, sandryaGUID](TaskContext /*task*/)
        {
            if (Creature* sandrya = ObjectAccessor::GetCreature(*me, sandryaGUID))
                sandrya->AI()->Talk(SAY_SANDRYA_TIME_NOT_ON_OUR_SIDE, ObjectAccessor::GetPlayer(*me, playerGUID));
        });

        _scheduler.Schedule(Milliseconds(16800), [this, playerGUID, dentariaGUID](TaskContext /*task*/)
        {
            if (Creature* dentaria = ObjectAccessor::GetCreature(*me, dentariaGUID))
                dentaria->AI()->Talk(SAY_DENTARIA_LEAVE_YOU_TO_TRAINING, ObjectAccessor::GetPlayer(*me, playerGUID));
        });

        _scheduler.Schedule(Milliseconds(22800), [this, playerGUID, dentariaGUID](TaskContext /*task*/)
        {
            if (Creature* dentaria = ObjectAccessor::GetCreature(*me, dentariaGUID))
                dentaria->AI()->Talk(SAY_DENTARIA_STUDY_WELL, ObjectAccessor::GetPlayer(*me, playerGUID));
        });

        _scheduler.Schedule(Milliseconds(27700), [this, sandryaGUID](TaskContext /*task*/)
        {
            if (Creature* sandrya = ObjectAccessor::GetCreature(*me, sandryaGUID))
                sandrya->AI()->DoAction(ACTION_HUNTRESS_LEAVE);
        });

        _scheduler.Schedule(Milliseconds(28900), [this, dentariaGUID](TaskContext /*task*/)
        {
            if (Creature* dentaria = ObjectAccessor::GetCreature(*me, dentariaGUID))
                dentaria->AI()->DoAction(ACTION_HUNTRESS_LEAVE);
        });

        _scheduler.Schedule(Milliseconds(36200), [this](TaskContext /*task*/)
        {
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
            if (--_scenesRunning == 0)
                StartIdleTalk();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);

        if (!UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }

private:
    void StartIdleTalk()
    {
        _scheduler.Schedule(RandomTalkInterval(), GROUP_IDLE_TALK, [this](TaskContext task)
        {
            me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
            // With a Sandrya to answer him the gaps are random; alone they are steady.
            task.Repeat(me->FindNearestCreature(NPC_HUNTRESS_SANDRYA_MOONFALL, 10.0f) ? RandomTalkInterval() : Milliseconds(7200));
        });
    }

    TaskScheduler _scheduler;
    uint32 _scenesRunning;
};

// Both huntresses. Sandrya chats, Dentaria stands by; both leave when Ilthalaine says so.
struct npc_ilthalaine_huntress : public NullCreatureAI
{
    npc_ilthalaine_huntress(Creature* creature) : NullCreatureAI(creature), _inScene(false) { }

    void IsSummonedBy(Unit* summoner) override
    {
        _summonerGUID = summoner->GetGUID();

        if (me->GetEntry() == NPC_HUNTRESS_SANDRYA_MOONFALL)
        {
            _scheduler.Schedule(Milliseconds(0), GROUP_IDLE_TALK, [this](TaskContext task)
            {
                me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                task.Repeat(RandomTalkInterval());
            });
        }

        _scheduler.Schedule(Seconds(2), [this](TaskContext task)
        {
            Player* player = ObjectAccessor::GetPlayer(*me, _summonerGUID);
            if (!player || (!_inScene && player->GetQuestStatus(QUEST_THE_BALANCE_OF_NATURE) != QUEST_STATUS_COMPLETE))
            {
                me->DespawnOrUnsummon();
                return;
            }

            task.Repeat();
        });
    }

    void DoAction(int32 action) override
    {
        switch (action)
        {
            case ACTION_HUNTRESS_SCENE_STARTED:
                _inScene = true;
                _scheduler.CancelGroup(GROUP_IDLE_TALK);
                // Should Ilthalaine lose the scene half way, they do not stand here forever.
                me->DespawnOrUnsummon(Minutes(1));
                break;
            case ACTION_HUNTRESS_LEAVE:
            {
                // Straight legs, as retail moves them segment by segment; the speed is
                // the template's run speed, 9.7 yd/s as sniffed.
                Movement::MoveSplineInit init(me);
                // MoveSplineInit::Launch overwrites the first point with the current position.
                init.Path().emplace_back(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ());
                std::array<G3D::Vector3, 4> const& path = me->GetEntry() == NPC_HUNTRESS_SANDRYA_MOONFALL ? HuntressSandryaLeavePath : HuntressDentariaLeavePath;
                init.Path().insert(init.Path().end(), path.begin(), path.end());
                init.SetWalk(false);
                me->DespawnOrUnsummon(Milliseconds(init.Launch()));
                break;
            }
            default:
                break;
        }
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    TaskScheduler _scheduler;
    ObjectGuid _summonerGUID;
    bool _inScene;
};

// 28713: the huntresses arrive the moment the objectives are done.
class quest_the_balance_of_nature : public QuestScript
{
public:
    quest_the_balance_of_nature() : QuestScript("quest_the_balance_of_nature") { }

    void OnQuestStatusChange(Player* player, Quest const* /*quest*/, QuestStatus /*oldStatus*/, QuestStatus newStatus) override
    {
        if (newStatus == QUEST_STATUS_COMPLETE)
            SummonHuntressesFor(player);
    }
};

// A player who completed 28713 in an earlier session, or came back from another
// map, finds them waiting when he enters Shadowglen; login counts as entering.
class player_shadowglen_huntresses : public PlayerScript
{
public:
    player_shadowglen_huntresses() : PlayerScript("player_shadowglen_huntresses") { }

    void OnUpdateArea(Player* player, Area* newArea, Area* /*oldArea*/) override
    {
        if (newArea && newArea->GetId() == AREA_SHADOWGLEN && player->GetQuestStatus(QUEST_THE_BALANCE_OF_NATURE) == QUEST_STATUS_COMPLETE)
            SummonHuntressesFor(player);
    }
};

// Tarindrella (49480), the dryad who walks Shadowthread Cave with each player from
// 28725 "The Woodland Protector" until 28728 "Signs of Things to Come" is taken.
//
// Retail summons her per player and the DB already carries the mechanism: spell_area
// 92237 on the player while he is in area 257 and lacks 92239; 92237 triggers 92238
// at once and every 10 s; 92238 summons her 7 yd behind the player with
// SummonProperties 2996 -- Control ALLY, flag 512, PERSONAL_SPAWN -- so the core makes
// her a Guardian of the player, at his level and faction, visible to him alone. She
// answers 1.7 s later with 92239 "Tarindrella Guardian Aura" on her owner, which is
// what stops the next 92238 tick from summoning a second one, and greets him. Leave
// the cave and she is gone in the same second; 92239 goes with her and the next tick
// after walking back in brings her back -- the flicker the sniff shows at the cave lip
// (three copies in one run, one of them alive for two seconds).
//
// In the 14 Sep sniff she is no passive escort: she opens every fight of the owner's
// with 33844 Entangling Roots (7 casts in a five-minute run, one per spider or so)
// and calls three treants with 92573 Summon Nature's Bite five times over the same
// run, never twice within 14 s. Each treant announces itself with 37846 on arrival.
// She takes the owner's target and drops the fight when he walks off.
//
// Twelve Webwood Spider kills for 28726 got one bark from her copy, on kill #4, and
// a second player's copy barked once in the same two minutes: a random group-1 line
// on roughly one kill in ten. Githyiss the Vile dying within 20 yd (anyone's kill --
// 1994's SmartAI sets data 1/1 on every Tarindrella in range) has her name the totem
// 2.0 s later and, if the Gnarlpine Corruption Totem 49598 stands within reach, go
// for it with melee and 92573; the sniff has it dead 5 s after she engages, and she
// has no retail damage table here, so she finishes it herself at that mark. The
// totem is IMMUNE_TO_NPC, which a player's guardian ignores; her treants are flagged
// player-controlled for the same reason.
//
// Accepting 28728 from her casts 92420 on the player (spell_target_position: the
// cured Dentaria's side, facing 3.4732) and destroys her in the same packet. The
// farewell line 49480/4 is not said anywhere in the sniff.
enum TarindrellaData
{
    NPC_TARINDRELLA                         = 49480,
    NPC_WEBWOOD_SPIDER                      = 1986,
    NPC_GNARLPINE_CORRUPTION_TOTEM          = 49598,

    SPELL_TARINDRELLA_GUARDIAN_AURA         = 92239,
    SPELL_ENTANGLING_ROOTS                  = 33844,
    SPELL_SUMMON_NATURES_BITE               = 92573,
    SPELL_FORCE_OF_NATURE                   = 37846,
    SPELL_TARINDRELLAS_NATURE_TELEPORT      = 92420,

    QUEST_SIGNS_OF_THINGS_TO_COME           = 28728,
    AREA_SHADOWTHREAD_CAVE                  = 257,

    SAY_TARINDRELLA_COME_TO_HELP            = 0,
    SAY_TARINDRELLA_SPIDER_KILLED           = 1,
    SAY_TARINDRELLA_TOTEM                   = 2,

    DATA_GITHYISS_DIED                      = 1,
    ACTION_OWNER_KILLED_SPIDER              = 1,

    GROUP_TARINDRELLA_COMBAT                = 1
};

uint32 const NaturesBiteCooldown = 20000;

// The player's own Tarindrella, if she is with him.
Creature* FindTarindrellaOf(Player* player)
{
    for (Unit* controlled : player->m_Controlled)
        if (controlled->GetEntry() == NPC_TARINDRELLA)
            return controlled->ToCreature();
    return nullptr;
}

struct npc_tarindrella : public ScriptedAI
{
    npc_tarindrella(Creature* creature) : ScriptedAI(creature), _naturesBiteTime(0) { }

    void IsSummonedBy(Unit* summoner) override
    {
        _ownerGUID = summoner->GetGUID();

        // Defensive, not aggressive: the fights she joins are the owner's, not every
        // spider she has line of sight to.
        me->SetReactState(REACT_DEFENSIVE);

        _scheduler.Schedule(Milliseconds(1700), [this](TaskContext /*task*/)
        {
            DoCastSelf(SPELL_TARINDRELLA_GUARDIAN_AURA, true);
            Talk(SAY_TARINDRELLA_COME_TO_HELP, GetOwner());
        });

        // Gone the moment the owner is out of the cave, off the map or logged out.
        _scheduler.Schedule(Seconds(1), [this](TaskContext task)
        {
            Player* owner = GetOwner();
            if (!owner || owner->GetAreaId() != AREA_SHADOWTHREAD_CAVE)
            {
                me->DespawnOrUnsummon();
                return;
            }

            task.Repeat();
        });
    }

    void EnterCombat(Unit* /*who*/) override
    {
        _scheduler.CancelGroup(GROUP_TARINDRELLA_COMBAT);

        _scheduler.Schedule(Milliseconds(0), GROUP_TARINDRELLA_COMBAT, [this](TaskContext task)
        {
            DoCastVictim(SPELL_ENTANGLING_ROOTS);
            task.Repeat(Seconds(12));
        });

        _scheduler.Schedule(Milliseconds(1600), GROUP_TARINDRELLA_COMBAT, [this](TaskContext task)
        {
            if (GetMSTimeDiffToNow(_naturesBiteTime) >= NaturesBiteCooldown)
            {
                _naturesBiteTime = getMSTime();
                DoCastVictim(SPELL_SUMMON_NATURES_BITE);
            }

            task.Repeat(Seconds(3));
        });
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        _scheduler.CancelGroup(GROUP_TARINDRELLA_COMBAT);
        ScriptedAI::EnterEvadeMode(why);
    }

    void JustSummoned(Creature* summon) override
    {
        // A player's guardian may hit the IMMUNE_TO_NPC totem; her treants need the
        // same flag to follow her onto it.
        summon->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PVP_ATTACKABLE);
        summon->CastSpell(summon, SPELL_FORCE_OF_NATURE, true);
        if (Unit* victim = me->GetVictim())
            summon->AI()->AttackStart(victim);
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->GetEntry() == NPC_WEBWOOD_SPIDER)
            DoAction(ACTION_OWNER_KILLED_SPIDER);
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_OWNER_KILLED_SPIDER && roll_chance_i(10))
            Talk(SAY_TARINDRELLA_SPIDER_KILLED);
    }

    void SetData(uint32 id, uint32 /*value*/) override
    {
        if (id != DATA_GITHYISS_DIED)
            return;

        _scheduler.Schedule(Seconds(2), [this](TaskContext /*task*/)
        {
            Talk(SAY_TARINDRELLA_TOTEM);

            Creature* totem = me->FindNearestCreature(NPC_GNARLPINE_CORRUPTION_TOTEM, 20.0f);
            if (!totem)
                return;

            AttackStart(totem);
            DoCast(totem, SPELL_SUMMON_NATURES_BITE);

            ObjectGuid totemGUID = totem->GetGUID();
            _scheduler.Schedule(Seconds(5), [this, totemGUID](TaskContext /*task*/)
            {
                Creature* totem = ObjectAccessor::GetCreature(*me, totemGUID);
                if (totem && totem->IsAlive() && me->GetVictim() == totem)
                    me->Kill(totem);
            });
        });
    }

    void sQuestAccept(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() != QUEST_SIGNS_OF_THINGS_TO_COME)
            return;

        player->CastSpell(player, SPELL_TARINDRELLAS_NATURE_TELEPORT, true);
        me->DespawnOrUnsummon();
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);

        if (!UpdateVictim())
        {
            if (Unit* target = OwnerTarget())
                AttackStart(target);
            return;
        }

        // She stays with the owner rather than finishing a fight he has walked out of.
        if (Player* owner = GetOwner())
            if (!me->IsWithinDist(owner, 40.0f))
            {
                EnterEvadeMode(EVADE_REASON_OTHER);
                return;
            }

        DoMeleeAttackIfReady();
    }

private:
    Player* GetOwner() const
    {
        return ObjectAccessor::GetPlayer(*me, _ownerGUID);
    }

    // What the owner is fighting: his target first, then whatever is on him.
    Unit* OwnerTarget() const
    {
        Player* owner = GetOwner();
        if (!owner || !owner->IsInCombat() || !me->IsWithinDist(owner, 40.0f))
            return nullptr;

        if (Unit* victim = owner->GetVictim())
            if (me->IsValidAttackTarget(victim))
                return victim;

        for (Unit* attacker : owner->getAttackers())
            if (me->IsValidAttackTarget(attacker))
                return attacker;

        return nullptr;
    }

    TaskScheduler _scheduler;
    ObjectGuid _ownerGUID;
    uint32 _naturesBiteTime;
};

// Kills by the player himself; hers come through KilledUnit.
class player_tarindrella_spider_kills : public PlayerScript
{
public:
    player_tarindrella_spider_kills() : PlayerScript("player_tarindrella_spider_kills") { }

    void OnCreatureKill(Player* killer, Creature* killed) override
    {
        if (killed->GetEntry() != NPC_WEBWOOD_SPIDER)
            return;

        if (Creature* tarindrella = FindTarindrellaOf(killer))
            tarindrella->AI()->DoAction(ACTION_OWNER_KILLED_SPIDER);
    }
};

void AddSC_teldrassil()
{
    RegisterCreatureAI(npc_wisp_flight_path);
    RegisterCreatureAI(npc_moriana_dawnlight);
    new at_aldrassil_dawnlight_amberleaf();
    RegisterCreatureAI(npc_ilthalaine);
    RegisterCreatureAI(npc_ilthalaine_huntress);
    new quest_the_balance_of_nature();
    new player_shadowglen_huntresses();
    RegisterCreatureAI(npc_tarindrella);
    new player_tarindrella_spider_kills();
}
