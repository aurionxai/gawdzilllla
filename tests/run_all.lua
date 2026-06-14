-- tests/run_all.lua
require("tests/test_character")
require("tests/test_attack_system")
require("tests/test_controller")
require("tests/test_npc_spawner")
require("tests/test_fight_manager")
require("tests/runner").summary()
