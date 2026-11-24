//128x128px: 491520 bits rx     9600: 51.2s       115200: 4.27s
//100x100px: 300000 bits rx     9600: 31.25s      115200: 2.6s
//75x75px:   168759 bits rx     9600: 17.6s       115200: 1.46s
//50x50px:   75000  bits rx     9600: 7.8s        115200: 0.65s

#include <Arduino.h>
static const int FPGA_RX_PIN = 16; // RX del ESP32 recibe desde TX de FPGA
static const int FPGA_TX_PIN = 17; // TX del ESP32 transmite hacia RX de FPGA
static const uint32_t PC_BAUD = 9600;
static const uint32_t FPGA_BAUD = 9600;
HardwareSerial FPGA_Serial(2);

void setup(){
  Serial.begin(PC_BAUD);
  delay(500);
  FPGA_Serial.begin(FPGA_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
  // Serial.println("ESP32 listo: puente PC <-> FPGA");
}

  Serial.println("ESP32 listo: puente PC <-> FPGA");
}
void loop(){
  while(Serial.available()){
    uint8_t dato = (uint8_t)Serial.read();
    FPGA_Serial.write(dato);
  }
  while(FPGA_Serial.available()){
    uint8_t dato = (uint8_t)FPGA_Serial.read();
    Serial.write(dato);
  }
}
