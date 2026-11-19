import serial
import threading
import time
from PIL import Image

# ==========================================
# CONFIGURACION
# ==========================================

PORT = 'COM3'
BAUD = 115200

WIDTH = 128
HEIGHT = 128

IMAGE_PATH = r'C:\Users\185008\Downloads\bean.jpg'

# Cantidad de pixeles
TOTAL_PIXELS = WIDTH * HEIGHT

# Cada pixel tiene 3 bytes: R, G, B
TOTAL_TX_BYTES = TOTAL_PIXELS * 3

# La FPGA devuelve 1 byte por pixel
TOTAL_RX_BYTES = TOTAL_PIXELS

CHUNK_SIZE = 1024

# ==========================================
# PREPARAR IMAGEN
# ==========================================

print("Cargando imagen...")

img = Image.open(IMAGE_PATH).convert('RGB')

# Redimensionar conservando las proporciones
img.thumbnail((WIDTH, HEIGHT), Image.Resampling.LANCZOS)

# Crear un fondo blanco de 128x128
canvas = Image.new('RGB', (WIDTH, HEIGHT), (255, 255, 255))

# Centrar la imagen
x = (WIDTH - img.width) // 2
y = (HEIGHT - img.height) // 2

canvas.paste(img, (x, y))

# Convertir imagen a bytes RGB
data = canvas.tobytes()

if len(data) != TOTAL_TX_BYTES:
    raise ValueError("El tamaño de la imagen RGB no es correcto")

print("Imagen preparada correctamente.")
print("Resolucion:", WIDTH, "x", HEIGHT)
print("Bytes RGB:", TOTAL_TX_BYTES)

# ==========================================
# TRANSMISION A LA FPGA
# ==========================================

def enviar_imagen(ser):

    enviados = 0

    print("\nEnviando imagen a la FPGA...")

    while enviados < TOTAL_TX_BYTES:

        bloque = data[enviados:enviados + CHUNK_SIZE]

        n = ser.write(bloque)

        enviados += n

        porcentaje = (enviados / TOTAL_TX_BYTES) * 100

        print(
            f"\rTransmitido: {porcentaje:.1f}%",
            end=''
        )

    print("\nTransmision finalizada.")

# ==========================================
# RECEPCION DE LA FPGA
# ==========================================

def recibir_imagen(ser):

    resultado = bytearray()

    print("\nEsperando imagen procesada...")

    while len(resultado) < TOTAL_RX_BYTES:

        faltantes = TOTAL_RX_BYTES - len(resultado)

        bloque = ser.read(min(CHUNK_SIZE, faltantes))

        if bloque:
            resultado.extend(bloque)

            porcentaje = (len(resultado) / TOTAL_RX_BYTES) * 100

            print(
                f"\rRecibido: {porcentaje:.1f}%",
                end=''
            )

    print("\nRecepcion finalizada.")

    return resultado

# ==========================================
# COMUNICACION SERIAL
# ==========================================

try:

    with serial.Serial(
        PORT,
        BAUD,
        timeout=1,
        write_timeout=10
    ) as ser:

        # Dar tiempo para estabilizar la comunicacion
        time.sleep(2)

        # Limpiar buffers
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        # Hilo de transmision
        hilo_tx = threading.Thread(
            target=enviar_imagen,
            args=(ser,)
        )

        hilo_tx.start()

        # Recepcion simultanea
        resultado = recibir_imagen(ser)

        # Esperar a que termine la transmision
        hilo_tx.join()

        print("\nComunicacion finalizada correctamente.")

# ==========================================
# RECONSTRUIR IMAGEN
# ==========================================

    # Convertir los bytes 0 y 1 a valores 0 y 255
    imagen_binaria = bytearray(
        255 if pixel != 0 else 0
        for pixel in resultado
    )

    # Crear imagen en escala de grises
    img_resultado = Image.frombytes(
        'L',
        (WIDTH, HEIGHT),
        bytes(imagen_binaria)
    )

    # Guardar imagen
    img_resultado.save('resultado_fpga.png')

    print("\nImagen guardada como resultado_fpga.png")

    # Mostrar imagen procesada
    img_resultado.show()

except serial.SerialException as e:

    print("Error de comunicacion serial:", e)

except FileNotFoundError:

    print("No se encontro el archivo:", IMAGE_PATH)

except Exception as e:

    print("Ocurrio un error:", e)
