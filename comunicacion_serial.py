
import serial
import threading
import time
from PIL import Image

# ==========================================
# CONFIGURACION
# ==========================================

PORT = 'COM4'
BAUD = 9600

WIDTH = 128
HEIGHT = 128

IMAGE_PATH = r'C:\Users\185008\Downloads\coffe.jpg'

TOTAL_PIXELS = WIDTH * HEIGHT
TOTAL_TX_BYTES = TOTAL_PIXELS * 3
TOTAL_RX_BYTES = TOTAL_PIXELS + 1

CHUNK_SIZE = 64

# Tiempo maximo sin recibir datos.
# Debe permitir que termine el envio de toda la imagen.
TIMEOUT_RECEPCION = 180

# ==========================================
# PREPARAR IMAGEN
# ==========================================

print("Cargando imagen...")

img = Image.open(IMAGE_PATH).convert('RGB')

img.thumbnail(
    (WIDTH, HEIGHT),
    Image.Resampling.LANCZOS
)

canvas = Image.new(
    'RGB',
    (WIDTH, HEIGHT),
    (255, 255, 255)
)

x = (WIDTH - img.width) // 2
y = (HEIGHT - img.height) // 2

canvas.paste(img, (x, y))

# Guardar exactamente la imagen que enviaremos
canvas.save("imagen_enviada.png")

data = canvas.tobytes()

if len(data) != TOTAL_TX_BYTES:
    raise ValueError("Tamaño RGB incorrecto")

print("Imagen preparada.")
print("Resolucion:", WIDTH, "x", HEIGHT)
print("Bytes de entrada:", len(data))

# ==========================================
# VARIABLES DE CONTROL
# ==========================================

error_tx = []
tx_terminado = threading.Event()

# ==========================================
# TRANSMISION
# ==========================================

def enviar_imagen(ser):

    try:

        enviados = 0

        print("\nEnviando imagen a FPGA...")

        while enviados < TOTAL_TX_BYTES:

            bloque = data[
                enviados:enviados + CHUNK_SIZE
            ]

            n = ser.write(bloque)

            if n <= 0:
                raise RuntimeError(
                    "La transmision se detuvo"
                )

            enviados += n

            porcentaje = (
                enviados / TOTAL_TX_BYTES
            ) * 100

            print(
                f"\rEnviado: {porcentaje:.1f}% "
                f"({enviados}/{TOTAL_TX_BYTES})",
                end=''
            )

            # Conservamos una pausa prudente
            # para el puente ESP32 a 9600 baudios.
            time.sleep(0.07)

        ser.flush()

        print("\nTransmision terminada.")

    except Exception as e:

        error_tx.append(e)

    finally:

        tx_terminado.set()


# ==========================================
# RECEPCION
# ==========================================

def recibir_imagen(ser):

    resultado = bytearray()

    print("\nEsperando respuesta de FPGA...")

    ultimo_dato = time.time()

    while len(resultado) < TOTAL_RX_BYTES:

        faltantes = TOTAL_RX_BYTES - len(resultado)

        bloque = ser.read(
            min(CHUNK_SIZE, faltantes)
        )

        if bloque:

            resultado.extend(bloque)

            ultimo_dato = time.time()

            porcentaje = (
                len(resultado) / TOTAL_RX_BYTES
            ) * 100

            print(
                f"\rRecibido: {porcentaje:.2f}% "
                f"({len(resultado)}/{TOTAL_RX_BYTES})",
                end=''
            )

        else:

            # No terminar por timeout mientras
            # Python todavía está enviando la imagen.
            if tx_terminado.is_set():

                if time.time() - ultimo_dato > TIMEOUT_RECEPCION:
                    print("\nTimeout de recepcion.")
                    break

    print("\nBytes recibidos:", len(resultado))
    print("Bytes faltantes:", TOTAL_RX_BYTES - len(resultado))

    return resultado


# ==========================================
# COMUNICACION SERIAL
# ==========================================

try:

    with serial.Serial(
        PORT,
        BAUD,
        timeout=1,
        write_timeout=75
    ) as ser:

        time.sleep(2)

        ser.reset_input_buffer()
        ser.reset_output_buffer()

        hilo_tx = threading.Thread(
            target=enviar_imagen,
            args=(ser,)
        )

        hilo_tx.start()

        resultado = recibir_imagen(ser)

        hilo_tx.join()

        if error_tx:
            raise RuntimeError(
                f"Error de transmision: {error_tx[0]}"
            )

        # ======================================
        # VERIFICAR RECEPCION
        # ======================================

        if len(resultado) != TOTAL_RX_BYTES:

            print("\nERROR: Transmision incompleta.")

            raise RuntimeError(
                "No se reconstruira una imagen incompleta."
            )

        print("\nComunicacion completa.")

        # ======================================
        # SEPARAR IMAGEN Y CLASIFICACION
        # ======================================

        pixeles_img = resultado[:TOTAL_PIXELS]

        es_frijol = resultado[TOTAL_PIXELS]

        print("\n================================")
        print("RESULTADO DE CLASIFICACION")

        if es_frijol == 1:
            print("ES UN FRIJOL")
        elif es_frijol == 0:
            print("NO ES UN FRIJOL")
        else:
            print("ERROR: BYTE DE CLASIFICACION INVALIDO")

        print("Byte recibido:", es_frijol)
        print("================================")

        # ======================================
        # RECONSTRUIR IMAGEN
        # ======================================

        imagen_binaria = bytearray(
            255 if pixel != 0 else 0
            for pixel in pixeles_img
        )

        img_resultado = Image.frombytes(
            'L',
            (WIDTH, HEIGHT),
            bytes(imagen_binaria)
        )

        img_resultado.save("resultado_fpga.png")

        print("\nImagen guardada: resultado_fpga.png")

        img_resultado.show()

except serial.SerialException as e:

    print("Error serial:", e)

except FileNotFoundError:

    print("No se encontro la imagen:", IMAGE_PATH)

except Exception as e:

    print("Error:", e)
