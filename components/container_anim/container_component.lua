local DoorComponent = class()

local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3

local DOOR_FILTERS = {}

local get_door_filter = function(door_entity)
   local player_id = radiant.entities.get_player_id(door_entity)
   local lockable = door_entity:get_component('lodewall-boxes:container'):is_lockable()
   local filter_id
   if lockable then
      filter_id = door_entity:get_id()
   else
      filter_id = player_id
   end
   local filter = DOOR_FILTERS[filter_id]
   if not filter then
      local filter_fn = function(entity)
         local entity_player_id = radiant.entities.get_player_id(entity)
         local is_friendly = stonehearth.player:are_player_ids_friendly(player_id, entity_player_id)
         local door_component = door_entity and door_entity:get_component('lodewall-boxes:container')
         local is_locked = door_component and door_component:is_locked()
         return is_friendly and not is_locked
      end

      local frc = stonehearth.ai:create_filter_result_cache(filter_fn, player_id .. ' door movement_guard_shape frc')
      local amenity_changed_listener = radiant.events.listen(radiant, 'stonehearth:amenity:sync_changed', function(e)
            local faction_a = e.faction_a
            local faction_b = e.faction_b
            if player_id == faction_a or player_id == faction_b then
               if frc and frc.cache then
                  frc.cache:clear()
               end
            end
         end)
      if lockable then
         radiant.events.listen(door_entity, 'lodewall-boxes:container:lock_changed', function(e)
            if frc and frc.cache then
               frc.cache:clear()
            end
         end)
      end
      filter = {
         frc = frc,
         listener = amenity_changed_listener
      }
      DOOR_FILTERS[filter_id] = filter
   end
   return filter
end

function DoorComponent:initialize()
   self._sv.locked = nil;
   local json = radiant.entities.get_json(self)
   self._sensor_name = json.sensor
   self._tracked_entities = {}
end

function DoorComponent:activate(entity, json)
   if self._sensor_name then
      self:_trace_sensor()
      self:_add_collision_shape()
      self._unit_info_trace = self._entity:add_component('unit_info')
                                    :trace_player_id('door component')
                                       :on_changed(function(player_id)
                                             self:_on_player_id_changed()
                                          end)
                                       :push_object_state()
   end
end

function DoorComponent:destroy()
   if self._sensor_trace then
      self._sensor_trace:destroy()
      self._sensor_trace = nil
   end

   if self._open_effect then
      self._open_effect:stop()
      self._open_effect = nil
   end

   if self._close_effect then
      self._close_effect:stop()
      self._close_effect = nil
   end

   if self._unit_info_trace then
      self._unit_info_trace:destroy()
      self._unit_info_trace = nil
   end
end

function DoorComponent:toggle_lock()
   local locked = self._sv.locked
   if locked == nil then
      locked = false
   end
   self._sv.locked = not locked
   self.__saved_variables:mark_changed()
   radiant.events.trigger(self._entity, 'lodewall-boxes:container:lock_changed')
end

function DoorComponent:is_locked()
   return self._sv.locked == true
end

function DoorComponent:is_lockable()
   local commands = self._entity:get_component('stonehearth:commands')
   return commands and commands:has_command('stonehearth:commands:toggle_lock')
end

-- On load, the doors have a player id of "", so recalculate when
-- it can get the correct player id
function DoorComponent:_on_player_id_changed()
   local mgs = self._entity:get_component('movement_guard_shape')
   local filter_data = get_door_filter(self._entity)
   mgs:set_filter_result_cache(filter_data.frc.cache)
end

function DoorComponent:_add_collision_shape() --Possibly this is the first candidate to DELETE
   local portal = self._entity:get_component('stonehearth:portal')
   if portal then
      local mob = self._entity:add_component('mob')
      local mgs = self._entity:add_component('movement_guard_shape')

      local region2 = portal:get_portal_region()
      local region3 = mgs:get_region()
      if not region3 then
         region3 = radiant.alloc_region3()
         mgs:set_region(region3)
      end
      region3:modify(function(cursor)
            cursor:clear()
            for rect in region2:each_cube() do
               cursor:add_unique_cube(Cube3(Point3(rect.min.x, rect.min.y,  0),
                                            Point3(rect.max.x, rect.max.y,  1)))
            end
         end)
   end
end

function DoorComponent:_trace_sensor()
   local sensor_list = self._entity:get_component('sensor_list')
   local sensor = sensor_list:get_sensor(self._sensor_name)
   if sensor then
      self._sensor_trace = sensor:trace_contents('door')
                                       :on_added(function (id, entity)
                                             self:_on_added_to_sensor(id, entity)
                                          end)
                                       :on_removed(function (id)
                                             self:_on_removed_to_sensor(id)
                                          end)
                                       :push_object_state()
   end
end

function DoorComponent:_on_added_to_sensor(id, entity)
   if self:_valid_entity(entity) then
      if not next(self._tracked_entities) and
         not self._sv.locked then
         -- if this is in our faction, open the door
         self:_open_door();
      end
      self._tracked_entities[id] = entity
   end
end

function DoorComponent:_on_removed_to_sensor(id)
   self._tracked_entities[id] = nil
   if not next(self._tracked_entities) then
      self:_close_door()
   end
end

function DoorComponent:_open_door()
   if self._close_effect then
      self._close_effect:stop()
      self._close_effect = nil
   end
   if not self._open_effect then
      self._open_effect = radiant.effects.run_effect(self._entity, 'open')
         :set_cleanup_on_finish(false)
   end
end

function DoorComponent:_close_door()
   if self._open_effect then
      self._open_effect:stop()
      self._open_effect = nil
   end
   if not self._close_effect then
      self._close_effect = radiant.effects.run_effect(self._entity, 'close')
   end
end

function DoorComponent:_valid_entity(entity)
   if not entity then
      return false
   end

   if not radiant.entities.has_free_will(entity) then
      -- entity can't open doors
      return false
   end

   if entity:get_id() == self._entity:get_id() then
      return false
   end

   if radiant.entities.get_player_id(entity) ~= radiant.entities.get_player_id(self._entity) then
      return false
   end
   
   --[[
   if not mob_component or not mob_component:get_moving() then
      return false
   end
   ]]

   return true
end

return DoorComponent