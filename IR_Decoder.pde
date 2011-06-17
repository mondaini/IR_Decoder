/* Raw IR decoder sketch!
 
 This sketch/program uses the Arduno and a PNA4602 to 
 decode IR received. This can be used to make a IR receiver
 (by looking for a particular code)
 or transmitter (by pulsing an IR LED at ~38KHz for the
 durations detected 
 
 This code is based on https://raw.github.com/adafruit/Raw-IR-decoder-for-Arduino
 Modified by: Filipe Mondaini
 Github: github.com/fmondaini
 */

#include <LiquidCrystal.h>
#include "ircodes.h"

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

// http://arduino.cc/en/Hacking/PinMapping168 for the 'raw' pin mapping
#define IRpin_PIN      PIND
#define IRpin          6

// the maximum pulse we'll listen for - 65 milliseconds is a long time
#define MAX_PULSE_TIME 65000

// Maximum number of pulses to be storaged in the array.
#define MAX_PULSES 34

// what our timing resolution should be, larger is better
// as its more 'precise' - but too large and you wont get
// accurate timing
#define RESOLUTION 20 

#define ERROR_MARGIN 20

// we will store up to 100 pulse pairs (this is -a lot-)
uint16_t pulses[MAX_PULSES][2];  // pair is high and low pulse 
uint8_t currentpulse = 0; // index for pulses we're storing

void setup(void) {
  lcd.begin(16,2);
  lcd.setCursor(0,0);
  lcd.print("Decodificador IR");
  lcd.setCursor(0,1);

  //Serial.begin(9600);
  //Serial.println("Ready to decode IR!");
}

void loop(void) {
  int numberpulses;
   
  numberpulses = listenForIR();
  
  lcd.setCursor(0,1);
  //TODO: Find a better solution for cleaning up the 2nd line of the lcd display
  lcd.print("                "); 
  lcd.setCursor(0,1);
  
  //Serial.print("Heard ");
  //Serial.print(numberpulses);
  //Serial.println("-pulse long IR signal");
  
  if (IRcompare(numberpulses, IRPlay)) {
    //Serial.println("PLAY");   
    lcd.print("PLAY");       
  }
  if (IRcompare(numberpulses, IRBackward)) {
    //Serial.println("REWIND");
    lcd.print("REWIND");
  }
  if (IRcompare(numberpulses, IRForward)) {
    //Serial.println("FORWARD");
    lcd.print("FORWARD");
  }
  if (IRcompare(numberpulses, IRVolumePlus)) {
    //Serial.println("VOLUME +");
    lcd.print("VOLUME +");
  }
  if (IRcompare(numberpulses, IRVolumeMinus)) {
    //Serial.println("VOLUME -");
    lcd.print("VOLUME -");
  } 
  if (IRcompare(numberpulses, IRPower)) {
    //Serial.println("POWER");
    lcd.print("POWER");
  }  
}

int listenForIR(void) {
  currentpulse = 0;

  while (1) {    
    uint16_t highpulse, lowpulse;  // temporary storage timing
    highpulse = lowpulse = 0; // start out with no pulse length
  
    // pin is still HIGH
    while (IRpin_PIN & (1 << IRpin)) {    

      // count off another few microseconds
      highpulse++;
      delayMicroseconds(RESOLUTION);

      // If the pulse is too long, we 'timed out' - either nothing
      // was received or the code is finished, so print what
      // we've grabbed so far, and then reset
      if ((highpulse >= MAX_PULSE_TIME) && (currentpulse != 0)) {
        return currentpulse;
      }
    }
    // we didn't time out so lets stash the reading
    pulses[currentpulse][0] = highpulse;

    // same as above
    while (! (IRpin_PIN & _BV(IRpin))) {
      // pin is still LOW
      lowpulse++;
      delayMicroseconds(RESOLUTION);
      if ((lowpulse >= MAX_PULSE_TIME)  && (currentpulse != 0)) {
        return currentpulse;
      }
    }
    pulses[currentpulse][1] = lowpulse;

    // we read one high-low pulse successfully, continue!
    currentpulse++;
    
    if (currentpulse >= MAX_PULSES){
      return currentpulse;
    }
  }
}

boolean IRcompare(int numpulses, int Signal[]) {

  for (int i=0; i< numpulses-1; i++) {
    int oncode = pulses[i][1] * RESOLUTION / 10;
    int offcode = pulses[i+1][0] * RESOLUTION / 10;

    // check to make sure the error is less than ERROR_MARGIN percent
    if ( abs(oncode - Signal[i*2 + 0]) <= (Signal[i*2 + 0] * ERROR_MARGIN / 100)) {
    } 
    else {
      // we didn't match perfectly, return a false match
      return false;
    }

    if (abs(offcode - Signal[i*2 + 1]) <= (Signal[i*2 + 1] * ERROR_MARGIN / 100)) {
      //Serial.print(" (ok)");
    } 
    else {
      //Serial.print(" (x)");
      // we didn't match perfectly, return a false match
      return false;
    }

    //Serial.println();
  }
  // Everything matched!
  return true;
}

