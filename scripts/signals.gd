extends Node

signal loading_started(label)
signal loading_done(label)

signal level_generated(level_data)
signal level_updated(level_data)

signal map_updating()
signal map_updated()

signal level_entry_updated(rectangle)
signal level_exit_updated(rectangle)

signal player_reached_level_exit
signal player_reached_level_entry

signal mob_created(node_id)
signal mob_killed(node)

signal player_ready()
signal move_player_to(position)
