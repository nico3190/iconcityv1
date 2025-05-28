Config = {}

Config.NotifyTrigger = function(type, msg)
    exports['ms_finalhud']:Notify(type, 'Lockpick', msg, 5000)
end

Config.progress_bar = function(msg, time)
    exports["ms_finalhud"]:ProgressBar(true, time, msg)
end

Config.VehicleLockpickTime = 10000
Config.DoorLockpickTime = 8000
Config.VehicleLockpickChance = 80
Config.DoorLockpickChance = 70
Config.MaxDistance = 3.0

Config.Locales = {
    ['vehicle_lockpick_success'] = 'Fahrzeug erfolgreich aufgebrochen!',
    ['door_lockpick_success'] = 'Tür erfolgreich aufgebrochen!',
    ['vehicle_lockpick_failed'] = 'Dietrich ist beim Fahrzeug zerbrochen!',
    ['door_lockpick_failed'] = 'Dietrich ist an der Tür zerbrochen!',
    ['no_target'] = 'Kein Fahrzeug oder Tür in der Nähe!',
    ['vehicle_not_locked'] = 'Das Fahrzeug ist nicht abgeschlossen!',
    ['door_not_locked'] = 'Die Tür ist nicht abgeschlossen!',
    ['lockpicking_vehicle'] = 'Breche Fahrzeug auf...',
    ['lockpicking_door'] = 'Breche Tür auf...',
    ['too_far'] = 'Du bist zu weit entfernt!'
}

Config.Discord = {
    webhook = "https://discord.com/api/webhooks/1345121658494779392/vp6UuPyceiX112ibq88NDK6oMHMv8BBdrTwJEeyWt8z8GzBIqvXf-I2NyZFaxBWQzhcY",
    botName = "IC | Icon City",
    color = 15158332,
    footer = "IC | Icon City"
}

Config.DiscordLogs = {
    ['vehicle_lockpick_attempt'] = 'Spieler hat Fahrzeug aufgebrochen',
    ['door_lockpick_attempt'] = 'Spieler hat Tür aufgebrochen',
    ['vehicle_success_desc'] = 'hat erfolgreich ein Fahrzeug aufgebrochen.',
    ['vehicle_failed_desc'] = 'ist beim Aufbrechen eines Fahrzeugs gescheitert.',
    ['door_success_desc'] = 'hat erfolgreich eine Tür aufgebrochen.',
    ['door_failed_desc'] = 'ist beim Aufbrechen einer Tür gescheitert.',
    ['coordinates'] = 'Koordinaten:',
    ['target_info'] = 'Ziel:',
    ['target_type'] = 'Typ:',
    ['result'] = 'Ergebnis:',
    ['player_identifiers'] = 'Player Identifiers:',
    ['discord_ping'] = 'Discord Ping:',
    ['time'] = 'Time'
}