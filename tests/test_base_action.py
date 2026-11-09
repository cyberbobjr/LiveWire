"""LWBaseAction: shared helpers, new(), getDuration(), waitToStart() and guard() of every timed action."""
import unittest

from test_simulation import make
from action_harness import load_actions


class BaseAction(unittest.TestCase):
    def setUp(self):
        self.lua = make()
        load_actions(self.lua)
        self.lua.execute('''
        DEAD, INSTANT, SAFE, CLIENT = false, false, true, false
        isClient = function() return CLIENT end
        SafeHouse = {isSafehouseAllowInteract = function() return SAFE end}
        function square(x, y, z)
            return {getX = function() return x end, getY = function() return y end, getZ = function() return z end}
        end
        function placed(sq, index)
            return {getSquare = function() return sq end, getObjectIndex = function() return index or 0 end}
        end
        FACED = {}
        CH = {x = 0.5, y = 0.5, z = 0, TURNING = false,
            getX = function(s) return s.x end, getY = function(s) return s.y end, getZ = function(s) return s.z end,
            isDead = function() return DEAD end, isTimedActionInstant = function() return INSTANT end,
            faceThisObject = function(_, o) FACED.object = o end,
            faceLocation = function(_, x, y) FACED.at = x .. "," .. y end,
            shouldBeTurning = function(s) return s.TURNING end}
        LWTestAction = LWBaseAction:derive("LWTestAction")
        LWTestAction.duration = 77
        LWTestAction.subject = "target"
        LWTestAction.partners = {"other"}
        LWTestAction.facing = true
        function LWTestAction:new(character, target, other)
            return LWBaseAction.new(self, character, {target = target, other = other})
        end
        ''')

    def run_lua(self, code):
        self.lua.execute(code)

    def test_authority_ready_needs_server_side_registry_writable_and_character_alive(self):
        self.run_lua('''
        local ready = LWBaseAction.authorityReady
        LiveWire.Registry.ready = true; LiveWire.Registry.readOnly = false
        assert(ready(CH))
        DEAD = true; assert(not ready(CH)); DEAD = false
        assert(not ready(nil))
        CLIENT = true; assert(not ready(CH)); CLIENT = false
        LiveWire.Registry.readOnly = true; assert(not ready(CH)); LiveWire.Registry.readOnly = false
        LiveWire.Registry.ready = false; assert(not ready(CH)); LiveWire.Registry.ready = true
        ''')

    def test_object_still_there_near_and_allowed(self):
        self.run_lua('''
        local sq = square(0, 0, 0)
        assert(LWBaseAction.objectStillThere(placed(sq, 0)))
        assert(not LWBaseAction.objectStillThere(placed(sq, -1)))
        assert(not LWBaseAction.objectStillThere(placed(nil)))
        assert(not LWBaseAction.objectStillThere(nil))
        assert(LWBaseAction.near(CH, sq, 2))
        assert(LWBaseAction.near(CH, square(2, 2, 0), 2) and not LWBaseAction.near(CH, square(4, 0, 0), 2))
        assert(LWBaseAction.near(CH, square(4, 0, 0), 3.5) == true)
        assert(not LWBaseAction.near(CH, square(0, 0, 1), 2) and not LWBaseAction.near(CH, nil, 2))
        assert(LiveWire.canTouch(CH, sq))
        SAFE = false; assert(not LiveWire.canTouch(CH, sq)); SAFE = true
        SafeHouse = nil; assert(LiveWire.canTouch(CH, sq))
        ''')

    def test_new_sets_the_fields_and_the_length_and_get_duration_follows_instant_actions(self):
        self.run_lua('''
        local sq = square(0, 0, 0)
        local a = LWTestAction:new(CH, placed(sq), "other")
        assert(a.character == CH and a.other == "other" and a.maxTime == 77)
        INSTANT = true
        assert(LWTestAction:new(CH, placed(sq), nil).maxTime == 1 and a:getDuration() == 1)
        ''')

    def test_wait_to_start_faces_an_object_or_a_square_and_reports_turning(self):
        self.run_lua('''
        local obj = placed(square(3, 4, 0))
        local a = ACT(LWTestAction, {character = CH, target = obj})
        CH.TURNING = true
        assert(a:waitToStart() == true and FACED.object == obj)
        CH.TURNING = false
        assert(a:waitToStart() == false)
        local b = ACT(LWTestAction, {character = CH, target = square(5, 6, 0), subjectIsSquare = true})
        b:waitToStart()
        assert(FACED.at == "5,6")
        local c = ACT(LWTestAction, {character = CH, target = obj, facing = false})
        FACED = {}
        assert(c:waitToStart() == false and FACED.object == nil)
        ''')

    def test_guard_checks_authority_objects_distance_and_safehouse(self):
        self.run_lua('''
        local sq = square(0, 0, 0)
        local target, other = placed(sq), placed(sq)
        local function guard(fields, class)
            fields.character = CH
            return ACT(class or LWTestAction, fields):guard()
        end
        LiveWire.Registry.ready = true; LiveWire.Registry.readOnly = false
        assert(guard({target = target, other = other}))
        LiveWire.Registry.readOnly = true
        assert(not guard({target = target, other = other}))
        LiveWire.Registry.readOnly = false
        DEAD = true; assert(not guard({target = target, other = other})); DEAD = false
        assert(not guard({target = placed(sq, -1), other = other}))
        assert(not guard({target = target, other = placed(sq, -1)}))
        assert(not guard({target = placed(square(9, 9, 0)), other = other}))
        SAFE = false; assert(not guard({target = target, other = other})); SAFE = true
        -- A larger range keeps a farther object.
        local far = placed(square(3, 0, 0))
        assert(not guard({target = far, other = other}))
        assert(guard({target = far, other = other, range = 3}))
        -- A square subject, no partner, and an action without subject (authority only).
        assert(guard({target = sq, subjectIsSquare = true, partners = false}))
        assert(not guard({target = nil, subjectIsSquare = true, partners = false}))
        assert(guard({subject = false, partners = false}))
        LiveWire.Registry.readOnly = true
        assert(not guard({subject = false, partners = false}))
        ''')


if __name__ == '__main__':
    unittest.main()
