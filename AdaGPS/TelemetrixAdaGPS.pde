#include <Adafruit_GPS.h>
#include <SoftwareSerial.h>

SoftwareSerial ss(8,7);
Adafruit_GPS GPS(&ss);

#define GPSECHO false

boolean usingInterrupt = false;
void useInterrupt(boolean);

void setup() {
    Serial.begin(115200);
    Serial.println("Adafruit GPS - Init");

    // Set the baud rate
    GPS.begin(9600);
    // Set the output to RMC + GGA
    GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
    // Set refresh rate
    GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);
    // Get antenna status
    GPS.sendCommand(PGCMD_ANTENNA);

    useInterrupt(true);
    delay(1000);
}

SIGNAL(TIMER0_COMPA_vect) {
    char c = GPS.read();

    #ifdef UDR0
        if (GPSECHO)
            if (c) UDR0 = c;
    #endif
}

void useInterrupt(boolean v) {
    if (v) {
        OCR0A = 0xAF;
        TIMSK0 |= _BV(OCIE0A);
        usingInterrupt = true;
    }
    else {
        TIMSK0 &= ~_BV(OCIE0A);
        usingInterrupt = false;
    }
}

uint32_t timer = millis();
void loop() {
    // if a sentence is received, check the checksum and parse it
    if (GPS.newNMEAreceived()) {
        if (!GPS.parse(GPS.lastNMEA()))
            return;
    }

    // reset the timer
    if (timer > millis()) timer = millis();

    // every x seconds, print out the current stats
    if (millis() - timer > 5000) {
        timer = millis();

        // Timestamp
        Serial.print(GPS.month, DEC); Serial.print('/');
        Serial.print(GPS.day, DEC); Serial.print("/20");
        Serial.print(GPS.year, DEC); Serial.print('-');
        Serial.print(GPS.hour, DEC); Serial.print(':');
        Serial.print(GPS.minute, DEC); Serial.print(':');
        Serial.print(GPS.seconds, DEC); 
        Serial.print(", ");

        // GPS
        if (GPS.fix) {
            // GPS - Latitude 
            Serial.print(GPS.latitude, 4); Serial.print(GPS.lat);
            Serial.print(", ");
            // GPS - Longitude
            Serial.print(GPS.longitude, 4); Serial.print(GPS.lon);
            Serial.print(", ");
            // GPS - Altitude 
            Serial.print(GPS.altitude);
            Serial.print(", ");
            // GPS - Speed
            Serial.print(GPS.speed);
            Serial.print(", ");
        }
        
        Serial.print("\n");
    }
}