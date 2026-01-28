struct PulseSettings {                                                                  // Double vibration structure
    var shortGap : float;
    var longGap  : float;
    var firstIntensity : int;
    var secondIntensity : int;
}

class CHorseVibrationManager extends CObject {
    private var active          : bool;
    private var gaitSettings    : array<PulseSettings>;
    private var horsePulseTimer : float;
    private var doubleVibe      : bool;
    private var lastGaitIndex   : int;
    private var wasInAction     : bool;
    private var speedingUp      : bool;

    public function Init() {                                                            // Populate array / (re)set flags
        gaitSettings.Clear();
        AddPulse(0.49f, 0.49f, 3, 3);   // 0 Walk
        AddPulse(0.30f, 0.39f, 3, 2);   // 1 Trot 
        AddPulse(0.12f, 0.46f, 1, 0);   // 2 Canter
        AddPulse(0.11f, 0.56f, 2, 1);   // 3 Gallop

        horsePulseTimer = 0.0f;
        doubleVibe = false;
        lastGaitIndex = -1;
        SetActive(true);
    }

    private function AddPulse(sGap: float, lGap: float, i1: int, i2: int) {             // Add struct to array
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
        var horseActor: CActor;

        if ( theGame.IsDialogOrCutscenePlaying() || theGame.IsBlackscreenOrFading() ) {      
            SetActive(false); 
        } else {
            SetActive(true); 
        }
        
        if (!active) {                                                                      
            lastGaitIndex = -1;
            return;
        }

        if ( horse.IsInHorseAction() ) {                            // Rearing
            if (!wasInAction) {
                theGame.VibrateController(0.4f, 0.8f, 0.7f); 
                wasInAction = true; 
            } 
            return; 
        } else if (wasInAction) {
            horsePulseTimer = 0.0f; 
            wasInAction = false; 
        }

        if (isIdle) {                                               // Stopped?  How Hard?  Vibrate?
            if (lastGaitIndex >= 0) {
                if (lastGaitIndex >= 2) {
                    theGame.VibrateController(0.4f, 0.8f, 0.7f);
                } else {
                    Vibrate(1, 0.04f);
                }
                lastGaitIndex = -1;
            }
            return;
        } 
        
        horseActor = (CActor)horse.GetEntity();
        if ( horseActor.IsInAir() ) {                               // Jumping
            return; 
        }

        horsePulseTimer -= dt;                                      // Reduce counter

        if (speedingUp && horsePulseTimer <= 0.0f) {                // Second tap for spur horse
            theGame.VibrateController(8.5f, 4.5f, 0.07f);
            speedingUp = false;
            horsePulseTimer = 0.4f; 
            return;
        }

        if (horse.inCanter) {                                       // CDPR doesn't know gallop is faster than canter - fix it here
            gaitIndex = 3;
        } else if (horse.inGallop) {
            gaitIndex = 2;
        } else {
            speed = horse.InternalGetSpeed();
            if (speed < 0.5f) {
                horsePulseTimer = 0.0f;
                doubleVibe = false;
                lastGaitIndex = 0;
                return;
            } else if (speed <= 1.0f) {
                gaitIndex = 0;
            } else {                        
                gaitIndex = 1;
            }
        }

        if (gaitIndex != lastGaitIndex) {                           // Speeding up / slowing down
            if (gaitIndex > lastGaitIndex) {
                theGame.VibrateController(7.0f, 3.0f, 0.07f);
                horsePulseTimer = 0.3f;
                speedingUp = true;
            } else if (gaitIndex < lastGaitIndex) {
                Vibrate(3, 0.2f);
                horsePulseTimer = 0.1f;
            }
            lastGaitIndex = gaitIndex;
            if (speedingUp) {
                return;
            }
        }    

        settings = gaitSettings[gaitIndex];                         // Use gait-specific vibrations for hoofbeats

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

            if (horsePulseTimer < -1.0f) {                          // Cap timer at -1s lag
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

// Add / remove instance on mount / dismount 
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
    theGame.VibrateControllerLight(0.1);
    return wrappedMethod(entity, vehicleSlot);
}

@wrapMethod(W3HorseComponent) function OnDismountStarted( entity : CEntity ) {
    if (entity == thePlayer && vibeManager) {
        vibeManager.SetActive(false);
        delete vibeManager;
        vibeManager = NULL;
    }
    theGame.VibrateControllerVeryHard(0.1);
    return wrappedMethod(entity);
}

@wrapMethod(CR4Player) function OnSpawned( spawnData : SEntitySpawnData ) {             // In case we spawn on horse
    var retVal: bool; 
    var horse: W3HorseComponent;

    retVal = wrappedMethod(spawnData);

    if ( this.IsUsingHorse() ) {
        horse = this.GetUsedHorseComponent();
        if (!horse.vibeManager) {
            horse.vibeManager = new CHorseVibrationManager in horse;
            horse.vibeManager.Init();
        }
        horse. vibeManager.SetActive(true);
    }

    return retVal;
}

//Main work here:
@wrapMethod(W3HorseComponent) function OnTick(dt: float) {
    if (vibeManager) {
        vibeManager.Update(dt, this, isInIdle);
    }
    return wrappedMethod(dt);
}
