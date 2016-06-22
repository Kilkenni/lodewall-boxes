local ChestComponent = class()

function ChestComponent:initialize()
   local json = radiant.entities.get_json(self)
   self._sensor_name = json.sensor
   self._tracked_entities = {}
end

function ChestComponent:activate()
   if self._sensor_name then
      self:_trace_sensor()
   end
end

function ChestComponent:destroy()
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
end

function ChestComponent:_trace_sensor()
   local sensor_list = self._entity:get_component('sensor_list')
   local sensor = sensor_list:get_sensor(self._sensor_name)
   if sensor then
      self._sensor_trace = sensor:trace_contents('chest')
                                       :on_added(function (id, entity)
                                             self:_on_added_to_sensor(id, entity)
                                          end)
                                       :on_removed(function (id)
                                             self:_on_removed_to_sensor(id)
                                          end)
                                       :push_object_state()
   end
end

function ChestComponent:_on_added_to_sensor(id, entity)
   if self:_valid_entity(entity) then
      if not next(self._tracked_entities) and
         not self._sv.locked then
         -- if this is in our faction, open the chest
         self:_open_chest();
      end
      self._tracked_entities[id] = entity
   end
end

function ChestComponent:_on_removed_to_sensor(id)
   self._tracked_entities[id] = nil
   if not next(self._tracked_entities) then
      self:_close_chest()
   end
end

function ChestComponent:_open_chest()
   if self._close_effect then
      self._close_effect:stop()
      self._close_effect = nil
   end
   if not self._open_effect then
      self._open_effect = radiant.effects.run_effect(self._entity, 'open')
         :set_cleanup_on_finish(false)
   end
end

function ChestComponent:_close_chest()
   if self._open_effect then
      self._open_effect:stop()
      self._open_effect = nil
   end
   if not self._close_effect then
      self._close_effect = radiant.effects.run_effect(self._entity, 'close')
   end
end

function ChestComponent:_valid_entity(entity)
   if not entity then
      return false
   end

   if not radiant.entities.has_free_will(entity) then
      -- entity can't open chests
      return false
   end

   if entity:get_id() == self._entity:get_id() then
      return false
   end

   if radiant.entities.get_player_id(entity) ~= radiant.entities.get_player_id(self._entity) then
      return false
   end

   return true
end

return ChestComponent
