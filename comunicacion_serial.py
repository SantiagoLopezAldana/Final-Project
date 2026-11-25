
import serial
import threading
import time
from PIL import Image

# ==========================================
# CONFIGURACION
# ==========================================

PORT = 'COM4'
BAUD = 115200

WIDTH = 128
HEIGHT = 128

IMAGE_PATH = r"C:\Users\185008\Pictures\bean5.png"

# Cantidad total de pixeles
TOTAL_PIXELS = WIDTH * HEIGHT

# 3 bytes por pixel: RGB
TOTAL_TX_BYTES = TOTAL_PIXELS * 3

# 1 byte por pixel + 1 byte de clasificacion
TOTAL_RX_BYTES = TOTAL_PIXELS + 1

# Paquetes de transmision
CHUNK_SIZE = 1024

# Tiempo maximo sin recibir datos una vez terminado el envio
TIMEOUT_RECEPCION = 15


# ==========================================
# PREPARAR IMAGEN
# ==========================================

print("Cargando imagen...")

img = Image.open(IMAGE_PATH).convert('RGB')

# Redimensionar conservando proporciones
img.thumbnail(
    (WIDTH, HEIGHT),
    Image.Resampling.LANCZOS
)

# Crear fondo blanco de 128x128
canvas = Image.new(
    'RGB',
    (WIDTH, HEIGHT),
    (255, 255, 255)
)

# Centrar imagen
x = (WIDTH - img.width) // 2
y = (HEIGHT - img.height) // 2

canvas.paste(img, (x, y))

# Guardar imagen original preparada
canvas.save("imagen_enviada.png")

# Convertir a bytes RGB
data = canvas.tobytes()

if len(data) != TOTAL_TX_BYTES:
    raise ValueError("El tamaño de la imagen RGB es incorrecto")

print("Imagen preparada correctamente.")
print("Resolucion:", WIDTH, "x", HEIGHT)
print("Bytes RGB a enviar:", len(data))


# ==========================================
# CONTROL DE TRANSMISION
# ==========================================

tx_terminado = threading.Event()
error_tx = []


# ==========================================
# TRANSMISION A LA FPGA
# ==========================================

def enviar_imagen(ser):

    try:

        enviados = 0

        print("\nEnviando imagen a la FPGA...")

        while enviados < TOTAL_TX_BYTES:

            bloque = data[
                enviados:enviados + CHUNK_SIZE
            ]

            n = ser.write(bloque)

            if n <= 0:
                raise RuntimeError(
                    "Error al transmitir datos"
                )

            enviados += n

            porcentaje = (
                enviados / TOTAL_TX_BYTES
            ) * 100

            print(
                f"\rTransmitido: {porcentaje:.2f}% "
                f"({enviados}/{TOTAL_TX_BYTES})",
                end=''
            )

        # Esperar a que salgan todos los datos
        ser.flush()

        print("\nTransmision finalizada.")

    except Exception as e:

        error_tx.append(e)

    finally:

        tx_terminado.set()


# ==========================================
# RECEPCION DESDE LA FPGA
# ==========================================

def recibir_imagen(ser):

    resultado = bytearray()

    print("\nEsperando imagen procesada y clasificacion...")

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

            # Solo iniciar el timeout cuando
            # Python haya terminado de transmitir.
            if tx_terminado.is_set():

                if error_tx:
                    break

                if time.time() - ultimo_dato > TIMEOUT_RECEPCION:

                    print("\nTimeout: no llegan mas datos.")
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

        # Estabilizar comunicacion
        time.sleep(2)

        # Limpiar buffers antes de comenzar
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        # Iniciar transmision en un hilo
        hilo_tx = threading.Thread(
            target=enviar_imagen,
            args=(ser,)
        )

        hilo_tx.start()

        # Recibir simultaneamente
        resultado = recibir_imagen(ser)

        # Esperar finalizacion del hilo
        hilo_tx.join()

        if error_tx:
            raise RuntimeError(
                f"Error de transmision: {error_tx[0]}"
            )

        # ======================================
        # VERIFICAR DATOS RECIBIDOS
        # ======================================

        if len(resultado) != TOTAL_RX_BYTES:
            faltantes = TOTAL_RX_BYTES - len(resultado)
            print("\nERROR: Transmision incompleta.")
            resultado.extend([0]*faltantes)
        print("Bytes finales: ", len(resultado))

        print("\nComunicacion completada correctamente.")

        # ======================================
        # SEPARAR IMAGEN Y CLASIFICACION
        # ======================================

        pixeles_img = resultado[:TOTAL_PIXELS]

        es_frijol = resultado[TOTAL_PIXELS]

        print("\n==========================================")

        if es_frijol == 1:

            print("VEREDICTO FPGA: ES UN FRIJOL (is_bean = 1)")

        elif es_frijol == 0:

            print("VEREDICTO FPGA: NO ES UN FRIJOL (is_bean = 0)")

        else:

            print("ERROR: BYTE DE CLASIFICACION INVALIDO")

        print("Byte de clasificacion:", es_frijol)

        print("==========================================")

        # ======================================
        # RECONSTRUIR IMAGEN BINARIA
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

        # Guardar resultado
        img_resultado.save("resultado_fpga.png")

        print("\nImagen guardada como resultado_fpga.png")

        # Mostrar imagen
        img_resultado.show()


except serial.SerialException as e:

    print("Error de comunicacion serial:", e)


except FileNotFoundError:

    print("No se encontro el archivo:", IMAGE_PATH)


except Exception as e:

    print("Ocurrio un error:", e)
