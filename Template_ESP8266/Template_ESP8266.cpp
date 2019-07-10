/*************************************************************
  This is a DEMO. You can use it only for development and testing.
  You should open Setting.h and modify General options.

  If you would like to add these features to your product,
  please contact Blynk for Businesses:

                   http://www.blynk.io/

 *************************************************************/
#include <Arduino.h>

//#define USE_SPARKFUN_BLYNK_BOARD    // Uncomment the board you are using
//#define USE_NODE_MCU_BOARD        // Comment out the boards you are not using
//#define USE_WITTY_CLOUD_BOARD
#define USE_CUSTOM_BOARD          // For all other ESP8266-based boards -
                                    // see "Custom board configuration" in Settings.h

#define APP_DEBUG        // Comment this out to disable debug prints

#define BLYNK_PRINT Serial

#include "BlynkProvisioning.h"

uint8_t gpio0_pin = 0;
uint8_t gpio2_pin = 2;

void setup() {
    pinMode(gpio0_pin, OUTPUT);
    digitalWrite(gpio0_pin, LOW);
    Serial.begin(115200);
    BlynkProvisioning.begin();
}

/**
 * Performs when user write value to V0. Set reset state if writen value is 1.
 * (Blynk and WIFI configuration will be reset in BlynkProvisioning.run() )
 *
 */
BLYNK_WRITE(V0)
{
    bool isVirtualPinReset = param.asInt() == 1;
    if (isVirtualPinReset) {
        BlynkState::set(MODE_RESET_CONFIG);
    }
}

void loop() {
    // This handles the network and cloud connection
    BlynkProvisioning.run();
}

