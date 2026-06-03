untyped

// Crouch Kick Fix — companion to the native crouchkick_plugin.dll.
// The plugin does the input buffering + native kick detection, then PUSHES each detected kick
// into this VM by calling CKF_OnKick (no per-frame polling). This script just:
//   1. reads the Mod Settings ConVars and pushes them to the plugin (enable), and
//   2. on each kick, flashes the speed gain (+N / -N) on the HUD, just under the speedometer.

global function InitCrouchKickFix
global function CKF_OnKick   // called from the native plugin when a kick is detected

struct {
    int enabled = -1
    var hud = null
    int fadeSeq = 0
} file

int function CKF_CvarInt( string name, int def )
{
    try { return GetConVarInt( name ) } catch ( e ) { return def }
}

void function InitCrouchKickFix()
{
    PushOptions( true )
    thread SettingsWatcher()
}

// Placement: just under the S2 speedometer (track its pos convar + offset); sane fallback if the
// speedometer isn't installed.
vector function KickHudPos()
{
    try {
        array<string> v = split( GetConVarString( "s2_speedometer_pos" ), " " )
        return Vector( v[0].tofloat(), v[1].tofloat() + 0.05, 0.0 )
    } catch ( e ) {}
    return <0.7, 0.30, 0.0>
}

// Native -> Squirrel push: a kick was detected. gain = outgoing-incoming speed (u/s). The HUD RUI
// is created lazily on the first kick — by then we're in a match and the cockpit topology exists
// (creating it in the Before callback crashes: the topology isn't ready yet).
void function CKF_OnKick( int gain, int wallFrame, int crouch )
{
    if ( CKF_CvarInt( "ckf_ui_feedback", 1 ) != 1 )
        return
    // "Crouch Kicks Only": skip plain wall kicks (crouch == 0).
    if ( CKF_CvarInt( "ckf_crouch_only", 1 ) == 1 && crouch != 1 )
        return

    if ( file.hud == null )
    {
        file.hud = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, -1 )
        RuiSetInt( file.hud, "maxLines", 1 )
        RuiSetInt( file.hud, "lineNum", 1 )
        RuiSetFloat( file.hud, "msgFontSize", 36.0 )
        RuiSetFloat( file.hud, "thicken", 0.0 )
    }

    // gain arrives in u/s (hammer units) -> the user's chosen unit via the shared FromWau.Units
    // mod (a hard dependency, like ModSettings).
    float value = Units_ConvertSpeed( gain.tofloat() )
    string text = ( value >= 0.0 ? "+" : "" ) + format( "%.1f", value )
    RuiSetFloat2( file.hud, "msgPos", KickHudPos() )
    RuiSetString( file.hud, "msgText", text )
    RuiSetFloat3( file.hud, "msgColor", gain >= 0 ? <0.3, 1.0, 0.3> : <1.0, 0.45, 0.2> )
    RuiSetFloat( file.hud, "msgAlpha", 1.0 )

    file.fadeSeq++
    thread FadeKick( file.fadeSeq )
}

// Short-lived: fades the readout out over ~0.8s, then exits. Only runs after a kick — no
// continuous per-frame work. A newer kick supersedes an in-progress fade via the sequence.
void function FadeKick( int seq )
{
    float alpha = 1.0
    while ( alpha > 0.0 )
    {
        WaitFrame()
        if ( seq != file.fadeSeq )
            return // a newer kick took over the HUD
        alpha -= 0.02
        if ( alpha < 0.0 )
            alpha = 0.0
        RuiSetFloat( file.hud, "msgAlpha", alpha )
    }
}

void function PushOptions( bool force )
{
    int enabled = CKF_CvarInt( "ckf_enabled", 1 )
    if ( force || enabled != file.enabled )
    {
        file.enabled = enabled
        CKF_SetOptions( enabled )
    }
}

// Mod Settings writes the ConVars directly; poll at a low rate (a few times a second, NOT every
// frame) so toggles apply mid-session without a restart.
void function SettingsWatcher()
{
    while ( true )
    {
        wait 0.3
        PushOptions( false )
    }
}
