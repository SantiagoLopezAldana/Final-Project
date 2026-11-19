#python -m pip install pyserial Pillow


import serial
import time
import threading
from PIL import Image

PORT = 'COM3'
BAUD = 9600
WIDTH = 128
HEIGHT = 128
IMAGE_PATH = 'frijol.jpg'
CHUNK_SIZE = 3072

TOTAL_PIXELS = WIDTH * HEIGHT
TOTAL_TX_BYTES = TOTAL_PIXELS * 3
TOTAL_RX_BYTES = TOTAL_PIXELS

# Aquí se guardarán los errores del hilo de transmisión
tx_errors = []

def transmitir(ser, data):
    try:
        enviados = 0

        while enviados < len(data):
            bloque = data[enviados:enviados + CHUNK_SIZE]

            n = ser.write(bloque)

            if n is None or n == 0:
                raise IOError("No se pudieron transmitir los datos")

            enviados += n

            porcentaje = enviados * 100 / len(data)

            print(
                f"\rTransmitidos: {enviados}/{len(data)} bytes "
                f"({porcentaje:.1f}%)",
                end=""
            )

        ser.flush()
        print("\nTransmision de imagen finalizada")

    except Exception as e:
        tx_errors.append(e)


try:
    # 1. Preparar la imagen
    img = Image.open(IMAGE_PATH)
    img = img.convert('RGB')
    img = img.resize(
        (WIDTH, HEIGHT),
        Image.Resampling.LANCZOS
    )

    data = img.tobytes()

    if len(data) != TOTAL_TX_BYTES:
        raise ValueError("El tamaño de la imagen no es correcto")

    print("Imagen preparada correctamente")
    print(f"Resolucion: {WIDTH} x {HEIGHT}")
    print(f"Pixeles: {TOTAL_PIXELS}")
    print(f"Bytes RGB a transmitir: {TOTAL_TX_BYTES}")
    print(f"Bytes de salida esperados: {TOTAL_RX_BYTES}")

    # 2. Abrir comunicación serial
    with serial.Serial(
        PORT,
        BAUD,
        timeout=1,
        write_timeout=10
    ) as ser:

        time.sleep(2)
        ser.reset_input_buffer()
        print("\nComunicacion iniciada")

        inicio = time.time()

        # 3. Iniciar transmisión en un hilo independiente
        hilo_tx = threading.Thread(
            target=transmitir,
            args=(ser, data)
        )

        hilo_tx.start()

        # 4. Recibir los resultados de la FPGA
        resultado = bytearray()

        print("\nRecibiendo imagen procesada...")

        while len(resultado) < TOTAL_RX_BYTES:

            faltantes = TOTAL_RX_BYTES - len(resultado)

            bloque = ser.read(min(4096, faltantes))

            if bloque:
                resultado.extend(bloque)

                porcentaje = len(resultado) * 100 / TOTAL_RX_BYTES

                print(
                    f"\rRecibidos: {len(resultado)}/{TOTAL_RX_BYTES} "
                    f"bytes ({porcentaje:.1f}%)",
                    end=""
                )

        # 5. Esperar a que termine el hilo de transmisión
        hilo_tx.join()

        if tx_errors:
            raise tx_errors[0]

        fin = time.time()

        print("\n\nTransmision y recepcion finalizadas")
        print(f"Tiempo total: {fin - inicio:.2f} segundos")

        # 6. Convertir los bytes recibidos en una imagen
        # La FPGA devuelve 0 o 1; PIL necesita valores de 0 a 255.
        imagen_salida = bytearray(
            255 if pixel != 0 else 0
            for pixel in resultado
        )

        img_resultado = Image.frombytes(
            'L',
            (WIDTH, HEIGHT),
            bytes(imagen_salida)
        )

        img_resultado.save('resultado_fpga.png')
        img_resultado.show()

        print("Imagen procesada guardada como resultado_fpga.png")

except FileNotFoundError:
    print("No se encontro la imagen indicada")

except serial.SerialException as e:
    print(f"Error en el puerto serial: {e}")

except KeyboardInterrupt:
    print("\nTransmision interrumpida")

except Exception as e:
    print(f"Error: {e}")
