// Minimal Crouch Kick Fix Auto-Enable Script
// This script automatically enables the crouch kick fix on game start

global function InitCrouchKickFix

struct {
    var hudElement
} file

void function InitCrouchKickFix()
{
    // Enable crouch kick fix by setting bit 4 of voice_forcemicrecord
    // Bit 4 corresponds to SRMM_settings.CKfix (0-indexed position 4)
    int currentSettings = GetConVarInt("voice_forcemicrecord")
    int ckFixBit = (1 << 4)  // Bit 4 = 16

    // Set bit 4 to 1 (enable crouch kick fix)
    SetConVarInt("voice_forcemicrecord", currentSettings | ckFixBit)

    print("Crouch Kick Fix: ENABLED")

    // Create HUD display
    thread CreateHudDisplay()
}

void function CreateHudDisplay()
{
    // Wait for game to initialize
    wait 2.0

    try {
        // Create a HUD element to show CKF is enabled
        file.hudElement = CreateCockpitRui( $"ui/cockpit_console_text_top_left.rpak" )
        RuiSetFloat2( file.hudElement, "msgPos", <0.15, 0.86, 0.0> )
        RuiSetString( file.hudElement, "msgText", "CKF ENABLED" )
        RuiSetFloat( file.hudElement, "msgFontSize", 35.0 )
        RuiSetFloat( file.hudElement, "msgAlpha", 0.7 )
        RuiSetFloat3( file.hudElement, "msgColor", <0.0, 1.0, 0.0> )  // Green color

        print("Crouch Kick Fix HUD: Displayed")
    } catch (exception) {
        print("Crouch Kick Fix HUD: Failed to create - " + exception)
    }
}
