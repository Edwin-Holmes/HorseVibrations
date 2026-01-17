struct PulseSettings {
    var shortGap : float;
    var longGap  : float;
    var firstIntensity : int;
    var secondIntensity : int;
}

class CHorseVibrationManager extends CObject {
    private var gaitSettings    : array<PulseSettings>;
    private var horsePulseTimer : float;
    private var doubleVibe      : bool;
    private var active          : bool;
    private var lastGaitIndex : int;

    public function Init() {
        var cw: CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
        gaitSettings.Clear();
        AddPulse(StringToFloat(cw.GetVarValue('horsevibe', 'walkS')), StringToFloat(cw.GetVarValue('horsevibe', 'walkL')), 3, 3);   // 0 Walk
        AddPulse(StringToFloat(cw.GetVarValue('horsevibe', 'trotS')), StringToFloat(cw.GetVarValue('horsevibe', 'trotL')), 3, 2);   // 1 Trot 
        AddPulse(StringToFloat(cw.GetVarValue('horsevibe', 'canterS')), StringToFloat(cw.GetVarValue('horsevibe', 'canterL')), 1, 0);   // 2 Canter
        AddPulse(StringToFloat(cw.GetVarValue('horsevibe', 'gallopS')), StringToFloat(cw.GetVarValue('horsevibe', 'gallopL')), 2, 1);   // 3 Gallop

        horsePulseTimer = 0.0f;
        doubleVibe = false;
        lastGaitIndex = -1;
    }

    private function AddPulse(sGap: float, lGap: float, i1: int, i2: int) {
        var settings: PulseSettings;
        settings.shortGap = sGap;
        settings.longGap = lGap;
        settings.firstIntensity = i1;
        settings.secondIntensity = i2;
        gaitSettings.PushBack(settings);
    }

    public function SetActive(toggle: bool) {
        active = toggle;
    }

    public function Update(dt: float, horse: W3HorseComponent, isIdle: bool) {
        var speed: float;
        var gaitIndex: int = 0;
        var settings: PulseSettings;

        if (!active || isIdle) {
            if (lastGaitIndex > 0) {
            theGame.VibrateControllerVeryHard(0.12f);
            lastGaitIndex = 0;
            }

            return;
        } 
        

        horsePulseTimer -= dt;

        if (horse.inCanter) {               // CDPR doesn't know gallop is faster than canter
            gaitIndex = 3;
        }
        else if (horse.inGallop) {
            gaitIndex = 2;
        }
        else {
            speed = horse.InternalGetSpeed();
            if (speed < 0.5f) {
                horsePulseTimer = 0.0f;
                doubleVibe = false;
                lastGaitIndex = 0;
                return;
            }
            else if (speed <= 1.0f) {
                gaitIndex = 0;
            }
            else {                        
                gaitIndex = 1;
            }
        }

        if (gaitIndex != lastGaitIndex) {
            if (gaitIndex > lastGaitIndex) {
                theGame.VibrateController(0.8f, 0.0f, 0.04f); 
                horsePulseTimer = 0.06f;
            }
            else if (gaitIndex < lastGaitIndex) {
                theGame.VibrateControllerVeryHard(0.12f);
                horsePulseTimer = 0.1f;
            }
            lastGaitIndex = gaitIndex;
        }    

        settings = gaitSettings[gaitIndex];

        if (horsePulseTimer <= 0.0f) {
            if (doubleVibe) {
                Vibrate(settings.secondIntensity, 0.04f);
                horsePulseTimer += settings.longGap;
                doubleVibe = false;
            } else {
                Vibrate(settings.firstIntensity, 0.02f);
                horsePulseTimer += settings.shortGap;
                doubleVibe = true;
            }

            if (horsePulseTimer < -1.0f) {
                horsePulseTimer = 0.0f;
            }
        }
    }

    private function Vibrate(intensity: int, duration: float) {
        switch (intensity) {
            case 3: 
                theGame.VibrateControllerVeryHard(duration); 
                break;
            case 2: 
                theGame.VibrateControllerHard(duration); 
                break;
            case 1: 
                theGame.VibrateControllerLight(duration); 
                break;
            case 0:
                theGame.VibrateControllerVeryLight(duration);
                break;
            default: 
                GetWitcherPlayer().DisplayHudMessage("Invalid vibration intensity requested");
                break;
        }
    }
}

@addField(W3HorseComponent) 
public var vibeManager : CHorseVibrationManager;

@wrapMethod(W3HorseComponent) function OnMountStarted( entity : CEntity, vehicleSlot : EVehicleSlot ) {
    if (entity == thePlayer) {
        if (!vibeManager) {
            vibeManager = new CHorseVibrationManager in this;
            vibeManager.Init();
        }
        vibeManager.SetActive(true);
    }
    return wrappedMethod(entity, vehicleSlot);
}

@wrapMethod(W3HorseComponent) function OnDismountStarted( entity : CEntity ) {
    if (entity == thePlayer && vibeManager) {
        vibeManager.SetActive(false);
        delete vibeManager;
        vibeManager = NULL;
    }
    return wrappedMethod(entity);
}

@wrapMethod(W3HorseComponent) function OnTick(dt: float) {
    if (vibeManager) {
        vibeManager.Update(dt, this, isInIdle);
    }
    return wrappedMethod(dt);
}