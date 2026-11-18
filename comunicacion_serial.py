import serial
import time
from PIL import Image

PORT = 'COM3'
BAUD = 9600
WIDTH = 128
HEIGHT = 128
IMAGE_PATH = 'frijol.jpg'  #Imagen a transmitir
CHUNK_SIZE = 3072


try:
    #Rescala de imagen y componentes RGB
    img = Image.open(IMAGE_PATH)
    img = img.convert('RGB')
    img = img.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    data = img.tobytes()
    total_bytes = WIDTH * HEIGHT * 3

    if len(data) != total_bytes:
        raise ValueError("El tamaño de la imagen no es correcto")
    print("Imagen preparada correctamente")
    print(f"Resolucion: {WIDTH} x {HEIGHT}")
    print(f"Pixeles: {WIDTH * HEIGHT}")
    print(f"Bytes: {total_bytes}")


    with serial.Serial(PORT,BAUD,timeout=1,write_timeout=10) as ser:
        time.sleep(2)
        print("Comunicacion iniciada")

        inicio = time.time()
        enviados = 0

        while enviados < total_bytes:
            bloque = data[enviados:enviados + CHUNK_SIZE]
            n = ser.write(bloque)
            if n is None or n == 0:
                raise IOError("No se pudieron transmitir los datos")
            enviados += n
            porcentaje = enviados * 100 / total_bytes
            print(f"({enviados}/{total_bytes} bytes)",end="")
            ser.flush()
            fin = time.time()
            print("\n\nTransmision finalizada")
        
except FileNotFoundError:
    print("No se encontro la imagen indicada")

except serial.SerialException as e:
    print(f"Error en el puerto serial: {e}")

except KeyboardInterrupt:
    print("\nTransmision interrumpida")

except Exception as e:
    print(f"Error: {e}")
