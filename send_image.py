import cv2
import serial
import time

PORT = "COM3"
BAUD_RATE = 9600     # Debe coincidir con uart_rx.v y arduino_esp32_bridge.ino
IMAGE_PATH = "frijol.jpg"

# 1. Cargar imagen, convertir de BGR a RGB y escalar a 128x128
img = cv2.imread(IMAGE_PATH)
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
img_resized = cv2.resize(img_rgb, (128, 128), interpolation=cv2.INTER_AREA)

# 2. Abrir puerto serial y esperar 2s a que el ESP32 termine de reiniciarse
ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
time.sleep(2)

# 3. Enviar los 49,152 bytes (R, G, B por cada píxel)
data = img_resized.tobytes()
print(f"Enviando {len(data)} bytes...")
ser.write(data)
ser.flush()

print("Imagen enviada.")
ser.close()
