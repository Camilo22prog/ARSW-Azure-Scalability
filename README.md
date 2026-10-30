### Escuela Colombiana de Ingeniería
### Arquitecturas de Software - ARSW

## Escalamiento en Azure con Maquinas Virtuales, Sacale Sets y Service Plans

### Dependencias
* Cree una cuenta gratuita dentro de Azure. Para hacerlo puede guiarse de esta [documentación](https://azure.microsoft.com/es-es/free/students/). Al hacerlo usted contará con $100 USD para gastar durante 12 meses.

### Parte 0 - Entendiendo el escenario de calidad

Adjunto a este laboratorio usted podrá encontrar una aplicación totalmente desarrollada que tiene como objetivo calcular el enésimo valor de la secuencia de Fibonnaci.

**Escalabilidad**
Cuando un conjunto de usuarios consulta un enésimo número (superior a 1000000) de la secuencia de Fibonacci de forma concurrente y el sistema se encuentra bajo condiciones normales de operación, todas las peticiones deben ser respondidas y el consumo de CPU del sistema no puede superar el 70%.

### Parte 1 - Escalabilidad vertical

1. Diríjase a el [Portal de Azure](https://portal.azure.com/) y a continuación cree una maquina virtual con las características básicas descritas en la imágen 1 y que corresponden a las siguientes:
    * Resource Group = SCALABILITY_LAB
    * Virtual machine name = VERTICAL-SCALABILITY
    * Image = Ubuntu Server 
    * Size = Standard B1ls
    * Username = scalability_lab
    * SSH publi key = Su llave ssh publica

![Imágen 1](images/part1/part1-vm-basic-config.png)

2. Para conectarse a la VM use el siguiente comando, donde las `x` las debe remplazar por la IP de su propia VM (Revise la sección "Connect" de la virtual machine creada para tener una guía más detallada).

    `ssh scalability_lab@xxx.xxx.xxx.xxx`

3. Instale node, para ello siga la sección *Installing Node.js and npm using NVM* que encontrará en este [enlace](https://linuxize.com/post/how-to-install-node-js-on-ubuntu-18.04/).
4. Para instalar la aplicación adjunta al Laboratorio, suba la carpeta `FibonacciApp` a un repositorio al cual tenga acceso y ejecute estos comandos dentro de la VM:

    `git clone <your_repo>`

    `cd <your_repo>/FibonacciApp`

    `npm install`

5. Para ejecutar la aplicación puede usar el comando `npm FibinacciApp.js`, sin embargo una vez pierda la conexión ssh la aplicación dejará de funcionar. Para evitar ese compartamiento usaremos *forever*. Ejecute los siguientes comando dentro de la VM.

    ` node FibonacciApp.js`

6. Antes de verificar si el endpoint funciona, en Azure vaya a la sección de *Networking* y cree una *Inbound port rule* tal como se muestra en la imágen. Para verificar que la aplicación funciona, use un browser y user el endpoint `http://xxx.xxx.xxx.xxx:3000/fibonacci/6`. La respuesta debe ser `The answer is 8`.

![](images/part1/part1-vm-3000InboudRule.png)

7. La función que calcula en enésimo número de la secuencia de Fibonacci está muy mal construido y consume bastante CPU para obtener la respuesta. Usando la consola del Browser documente los tiempos de respuesta para dicho endpoint usando los siguintes valores:
    * 1000000
    * 1010000
    * 1020000
    * 1030000
    * 1040000
    * 1050000
    * 1060000
    * 1070000
    * 1080000
    * 1090000    

8. Dírijase ahora a Azure y verifique el consumo de CPU para la VM. (Los resultados pueden tardar 5 minutos en aparecer).

![Imágen 2](images/part1/part1-vm-cpu.png)

9. Ahora usaremos Postman para simular una carga concurrente a nuestro sistema. Siga estos pasos.
    * Instale newman con el comando `npm install newman -g`. Para conocer más de Newman consulte el siguiente [enlace](https://learning.getpostman.com/docs/postman/collection-runs/command-line-integration-with-newman/).
    * Diríjase hasta la ruta `FibonacciApp/postman` en una maquina diferente a la VM.
    * Para el archivo `[ARSW_LOAD-BALANCING_AZURE].postman_environment.json` cambie el valor del parámetro `VM1` para que coincida con la IP de su VM.
    * Ejecute el siguiente comando.

    ```
    newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10 &
    newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10
    ```

10. La cantidad de CPU consumida es bastante grande y un conjunto considerable de peticiones concurrentes pueden hacer fallar nuestro servicio. Para solucionarlo usaremos una estrategia de Escalamiento Vertical. En Azure diríjase a la sección *size* y a continuación seleccione el tamaño `B2ms`.

![Imágen 3](images/part1/part1-vm-resize.png)

11. Una vez el cambio se vea reflejado, repita el paso 7, 8 y 9.
12. Evalue el escenario de calidad asociado al requerimiento no funcional de escalabilidad y concluya si usando este modelo de escalabilidad logramos cumplirlo.
13. Vuelva a dejar la VM en el tamaño inicial para evitar cobros adicionales.

### 1. ¿Cuántos y cuáles recursos crea Azure junto con la VM?
Al desplegar una máquina virtual en el grupo de recursos, Azure crea por defecto los siguientes **6 recursos esenciales**:

1. **Virtual Machine:** La instancia de cómputo que emula el sistema operativo Ubuntu.
2. **OS Disk (Disco administrado):** Almacenamiento persistente para el sistema operativo y la aplicación.
3. **Network Interface (NIC):** Interfaz de red virtual que conecta la VM a la subred.
4. **Public IP Address:** Dirección IP pública para la comunicación hacia internet (SSH y HTTP).
5. **Network Security Group (NSG):** Firewall virtual que controla el tráfico de entrada (*Inbound*) y salida (*Outbound*).
6. **Virtual Network (VNet):** Red virtual privada aislada que contiene la subred del entorno.

<img width="1188" height="853" alt="{F2662812-E767-499F-863D-C302EA8E5DD7}" src="https://github.com/user-attachments/assets/611d7b11-a02c-4fce-9e07-468d43d969aa" />

* **Descripción:** Vista del Grupo de Recursos `SCALABILITY_LAB` mostrando los 6 recursos aprovisionados por Azure.

---

### 2. ¿Brevemente describa para qué sirve cada recurso?
* **Virtual Machine:** Proporciona los núcleos de procesamiento (vCPU) y la memoria RAM necesarios para ejecutar la lógica de la aplicación.
* **OS Disk:** Mantiene guardados de forma persistente los binarios, el entorno de Node.js y el código fuente.
* **Network Interface (NIC):** Permite el enrutamiento de paquetes entre la máquina virtual y la infraestructura de red de Azure.
* **Public IP Address:** Facilita el acceso remoto de administración y la exposición de los servicios web hacia el cliente.
* **Network Security Group (NSG):** Aplica políticas de seguridad bloqueando o permitiendo puertos específicos (como el puerto 22 para SSH y el puerto 3000 para la aplicación).
* **Virtual Network (VNet):** Proporciona un espacio de direcciones IP privadas y aislamiento lógico para los recursos en la nube.

---

### 3. Cierre de sesión SSH y regla de puerto de entrada
* **¿Por qué se cae la aplicación al cerrar la sesión SSH?** Cuando se ejecuta `node FibonacciApp.js` en una terminal interactiva, el proceso se crea como un proceso hijo de la sesión de shell. Al cerrar la conexión SSH, el sistema operativo envía la señal `SIGHUP` (Hang Up), terminando la ejecución. Para evitarlo, se utiliza un administrador de procesos como `forever` para desvincular el demonio de la terminal interactiva.
* **¿Por qué debemos crear un Inbound Port Rule?** Por defecto, las políticas de seguridad de Azure bloquean todo el tráfico entrante (*Deny by default*). Aunque Node.js esté escuchando en el puerto `3000` internamente, los paquetes externos son descartados en el perímetro hasta que se habilita explícitamente una regla en el NSG para el puerto `3000`.

<img width="1600" height="324" alt="image" src="https://github.com/user-attachments/assets/013171ea-548f-492d-9901-71c5f25453c7" />

* **Descripción:** Consola SSH de la máquina virtual mostrando el comando `forever list` con `FibonacciApp.js` en ejecución activa.

<img width="1513" height="500" alt="image" src="https://github.com/user-attachments/assets/eaceaab7-c1b4-4bdd-90c9-ab39082d0b2f" />
<img width="1600" height="145" alt="image" src="https://github.com/user-attachments/assets/3eaa893c-70b5-4eeb-9178-2fcfd92ba8f2" />

* **Descripción:** Configuración de la regla *Inbound port rule* para el puerto `3000` en Azure y el navegador respondiendo correctamente con el valor `8` para `/fibonacci/6`.

---

### 4. Tabla de tiempos e interpretación
<img width="1600" height="492" alt="image" src="https://github.com/user-attachments/assets/2b7646e0-26cb-4f71-8348-08272b39c543" />
<img width="1725" height="888" alt="image" src="https://github.com/user-attachments/assets/b46ecb95-b279-4d51-90a2-63b01d19f032" />

* **Descripción:** Registro de los tiempos de respuesta para los 10 valores de Fibonacci obtenidos desde las herramientas de desarrollo (*DevTools*).
* **Interpretación:** La función de Fibonacci procesa un número con más de 200,000 dígitos mediante sumas iterativas masivas de cadenas/arreglos. Esto eleva la complejidad algorítmica y satura el procesamiento. Los picos donde el tiempo se duplica (ej. N = 1,010,000, 1,050,000 y 1,080,000) ocurren debido a las pausas del *Garbage Collector* de Node.js intentando liberar la memoria masiva acumulada en una VM con recursos muy limitados (0.5 GiB de RAM).

---

### 5. Consumo de CPU de la VM
<img width="1600" height="727" alt="image" src="https://github.com/user-attachments/assets/117621b1-a9ae-4a7d-a25b-6f9d7b9e9738" />
<img width="1529" height="611" alt="image" src="https://github.com/user-attachments/assets/2e86dbf6-97e7-4cf0-bb3f-d79b12ff3eee" />

* **Descripción:** Gráfica de Azure Metrics reflejando el pico de utilización de CPU al 100% durante las peticiones concurrentes en el tamaño inicial.
* **Interpretación:** La aplicación es de naturaleza 100% *CPU-bound* y se ejecuta de forma síncrona sobre el hilo principal (*Event Loop*) de Node.js. Al no haber operaciones de E/S (I/O) que liberen el procesador durante el cálculo, el núcleo asignado llega al 100% de utilización de manera constante durante las peticiones.

---

### 6. Resumen de la ejecución de Newman (Prueba Concurrente)
<img width="1600" height="850" alt="image" src="https://github.com/user-attachments/assets/b721443e-56c1-4e2e-bb0c-6ae080915766" />

* **Descripción:** Consolas paralelas ejecutando Newman (`-n 10`) donde se evidencian los fallos por saturación (*ECONNRESET*).
* **Tiempos de ejecución:** Al lanzar múltiples procesos concurrentes con Newman, el tiempo promedio se incrementa de forma lineal debido a la saturación de la cola de espera.
* **Fallos documentados:** Se registraron errores de tipo **`read ECONNRESET`** y *timeouts*. Ocurren porque el único hilo de ejecución de Node.js se congestiona procesando la carga y, al no responder a tiempo, las conexiones TCP se cierran bruscamente.

---

### 7. Diferencia entre los tamaños `B2ms` (o `B2as v2`) y `B1ls`
La serie *Burstable* (B) permite acumular créditos de CPU cuando hay baja demanda y gastarlos en ráfagas.  
* El tamaño `B1ls` cuenta con una capacidad base de CPU muy baja y créditos reducidos, estrangulando el rendimiento rápidamente.
* Los tamaños superiores (`B2ms` / `B2as v2`) multiplican los núcleos (vCPU), la memoria RAM (8 GiB) y otorgan una acumulación de créditos de CPU mucho mayor, permitiendo soportar mejor los picos operativos.

---

### 8. ¿Aumentar el tamaño de la VM es una buena solución? ¿Qué pasa con la aplicación?
<img width="1600" height="766" alt="image" src="https://github.com/user-attachments/assets/9ed9ab93-faa4-4a4b-90c0-1ca54c10dd20" />

* **¿Es buena solución? No.** Aunque se aumente el hardware de la máquina, **Node.js es monohilo (*single-threaded*)** por defecto, por lo que solo aprovechará un núcleo de procesamiento; el resto de vCPUs adicionales permanecen ociosos frente a esta aplicación.
* **Efectos en la app:** Al redimensionar la VM, Azure realiza un reinicio físico, lo que apaga el proceso de Node.js (`forever`) provocando una caída temporal del servicio si no está configurado como un servicio de arranque automático del sistema (`systemd`).

---

### 9. ¿Qué pasa con la infraestructura al cambiar el tamaño?
<img width="1914" height="701" alt="{71396D50-5B65-414C-A194-4F823ADB5455}" src="https://github.com/user-attachments/assets/8373fbc6-fa9d-4be7-a59c-75b445f633d5" />

Implica un reinicio del hipervisor y de la máquina virtual (*downtime*), lo que interrumpe abruptamente cualquier conexión activa con los clientes y genera un punto único de falla (*SPOF*).

---

### 10. ¿Hubo mejora en el consumo de CPU o en los tiempos de respuesta?
<img width="1600" height="856" alt="image" src="https://github.com/user-attachments/assets/b3a9d2fa-d9da-4799-87d6-e18611466649" />

* **Descripción:** Pruebas de carga concurrentes ejecutadas tras escalar verticalmente el tamaño de la máquina virtual.
* **Sí hubo una ligera mejora** en los tiempos individuales de respuesta debido a la mayor velocidad de reloj y mayor memoria RAM disponible (evitando paginación agresiva).
* **Sin embargo**, el consumo de CPU global reflejó limitaciones de concurrencia al seguir operando sobre un esquema monohilo.

---

### 11. Ejecución con mayor concurrencia (4 procesos en paralelo)
Al incrementar la carga paralela, el sistema saturó nuevamente la cola de peticiones. Demostró que una única máquina verticalmente escalada sigue sufriendo cuellos de botella bajo alta demanda concurrente debido a las restricciones de arquitectura de la aplicación.

---

### 12. Evaluación del escenario de calidad
**El modelo de escalabilidad vertical NO cumple satisfactoriamente con el requerimiento de calidad.** Aunque se amplíe el tamaño de la máquina virtual, la aplicación monohilo experimenta fallos por saturación (*ECONNRESET*) y bloqueos en el *Event Loop* bajo condiciones de concurrencia elevada. Se requiere obligatoriamente una estrategia de **escalabilidad horizontal** con balanceo de carga.


## Parte 2 - Escalabilidad horizontal

> **Región:** Chile Central · **Grupo de recursos:** `SCALABILITY_LAB` · **IP pública del balanceador:** `57.156.15.123`
> **VM:** `Standard_B2ats_v2` (2 vCPU, 1 GiB RAM, ≈ 9,64 US$/mes) · **Sistema operativo:** Ubuntu Server 24.04 LTS · **Node.js:** v26.13.0 + `forever`

### 1. Infraestructura creada

#### 1.1 Grupo de recursos y red virtual
Se creó el grupo de recursos `SCALABILITY_LAB` en *Chile Central* y dentro de él la red virtual `SCALABILITY_LAB_VIRTUAL_NETWORK` con espacio de direcciones `10.1.0.0/16` y una subred `SCALABILITY_LAB_SUBNET` `10.1.0.0/24` (251 direcciones utilizables).

![Grupo de recursos](images/part2/p2-01-grupo-recursos.png)
![Espacio de direcciones de la VNet](images/part2/p2-02-vnet-espacio-direcciones.png)
![Revisión de la VNet](images/part2/p2-03-vnet-revision.png)
![Subredes](images/part2/p2-04-vnet-subredes.png)

#### 1.2 Balanceador de carga, Backend Pool, Health Probe y regla
Se creó un balanceador **Standard**, público y regional (`SCALABILITY_LAB_LOAD_BALANCER`), con:

| Componente | Configuración |
|---|---|
| Front-end | `LoadBalancerFrontEnd`, IP pública Standard `57.156.15.123` |
| Backend Pool | `SCALABILITY_LAB_BACKEND_POOL` (VM1, VM2, VM3) |
| Health Probe | `SCALABILITY_LAB_HEALTH_PROBE` – TCP, puerto 3000, intervalo 5 s, umbral 2 |
| Load Balancing Rule | `SCALABILITY_LAB_LOAD_BALANCING_RULE` – TCP, puerto 80 → 3000, persistencia de sesión **Ninguna**, tiempo de inactividad 4 min |

![Revisión del balanceador](images/part2/p2-05-lb-revision.png)
![Overview del balanceador](images/part2/p2-06-lb-overview.png)
![Health Probe](images/part2/p2-07-health-probe.png)
![Regla de balanceo (1)](images/part2/p2-08-lb-regla-1.png)
![Regla de balanceo (2)](images/part2/p2-09-lb-regla-2.png)

#### 1.3 Máquinas virtuales (nodos)
Se crearon tres VM `Standard_B2ats_v2` en tres zonas de disponibilidad distintas (VM1→zona 1, VM2→zona 2, VM3→zona 3), con llave SSH propia cada una (`VM1_key`, `VM2_key`, `VM3_key`), en la VNet y subred anteriores y asociadas al balanceador y a su Backend Pool. Las tres comparten el *Network Security Group* `SCALABILITY_LAB_NETWORK_SECURITY_GROUP`, con las reglas **SSH (22, prioridad 1000)** y **Port_3000 (TCP 3000, prioridad 1010)**.

![Tamaño de la VM](images/part2/p2-10-vm-tamano.png)
![VM1 – zona de disponibilidad 1](images/part2/p2-11-vm1-zona.png)
![VM1 – redes](images/part2/p2-12-vm1-redes.png)
![Network Security Group](images/part2/p2-13-nsg-reglas.png)
![Asociación de la VM al balanceador](images/part2/p2-14-vm-asociar-lb.png)
![VM1 creada](images/part2/p2-15-vm1-overview.png)
![VM2 – revisión](images/part2/p2-16-vm2-revision.png)
![VM2 creada](images/part2/p2-17-vm2-overview.png)
![VM3 – zona de disponibilidad 3](images/part2/p2-18-vm3-zona3.png)

> **Nota sobre las IP públicas:** la suscripción de estudiante permite como máximo **3 IP públicas** por región. Una la consume el balanceador y las otras dos las VM1 y VM2, por lo que la **VM3 se creó sin IP pública**. Se administra por SSH saltando desde la VM1 (`ssh -i ~/VM3_key.pem vm3@10.1.0.6`) y recibe el tráfico normalmente a través del balanceador (IP privada `10.1.0.6`). Para que la VM3 pudiera descargar paquetes (nvm, npm) se utilizó la salida a Internet por defecto.

![Direcciones IP públicas](images/part2/p2-19-ips-publicas.png)

#### 1.4 Backend Pool con las 3 VM
![Backend Pool con VM1, VM2 y VM3](images/part2/p2-20-backend-pool-3vms.png)

#### 1.5 Recursos del grupo (18 en total)
El grupo contiene: balanceador, IP del balanceador, NSG, VNet, 3 VM, 3 discos, 3 interfaces de red, 3 llaves SSH y 2 IP públicas de VM.

![Recursos del grupo (1)](images/part2/p2-21-rg-recursos-1.png)
![Recursos del grupo (2)](images/part2/p2-22-rg-recursos-2.png)
![Recursos del grupo (3)](images/part2/p2-23-rg-recursos-3.png)
![Recursos del grupo (4)](images/part2/p2-24-rg-recursos-4.png)

#### 1.6 Despliegue de la aplicación en cada VM
En cada VM se instaló `git`, `nvm`/Node.js (en Ubuntu 24.04 fue necesario `sudo apt-get install -y libatomic1`), se clonó el repositorio, se ejecutó `npm install` y se levantó la app con `forever start FibonacciApp.js`. Verificación local con `curl localhost:3000/fibonacci/6` → `The answer is 8`:

![VM1](images/part2/p2-25-vm1-forever-curl.png)
![VM2](images/part2/p2-26-vm2-forever-curl.png)
![VM3](images/part2/p2-27-vm3-forever-curl.png)

### 2. Verificación del sistema a través del balanceador

Consumo de los endpoints por la IP pública del balanceador:

* `http://57.156.15.123/` → `Hello World`
* `http://57.156.15.123/fibonacci/6` → `The answer is 8`
* `http://57.156.15.123/fibonacci/1` → `The answer is 1`

![/fibonacci/6](images/part2/p2-28-navegador-fibonacci6.png)
![/](images/part2/p2-29-navegador-hello.png)
![/fibonacci/1](images/part2/p2-30-navegador-fibonacci1.png)

La métrica **Health Probe Status** (dividida por *Backend IP Address*) muestra las tres instancias (`10.1.0.4`, `10.1.0.5`, `10.1.0.6`) pasando a estado saludable (100 %) una vez la aplicación estuvo arriba en cada una; el balanceador solo enruta a nodos saludables.

![Health Probe por IP](images/part2/p2-31-health-probe-split.png)
![Health Probe promedio](images/part2/p2-32-health-probe-total.png)

### 3. Informe de Newman 1 (punto 2): 2 procesos en paralelo

Prueba ejecutada desde el PC local contra el balanceador (`n = 1.000.000`, `-n 10` iteraciones, 2 procesos de Newman simultáneos):

```
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10 &
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10
```

![Newman proceso A](images/part2/p2-33-newman-2proc-a.png)
![Newman proceso B](images/part2/p2-34-newman-2proc-b.png)

| Métrica | Proceso A | Proceso B |
|---|---|---|
| Iteraciones / peticiones | 10 / 10 | 10 / 10 |
| Fallos | **0** | **0** |
| Duración total | ≈ 1 m 6,9 s | ≈ 1 m 4,8 s |
| Tiempo de respuesta promedio | 6,4 s (mín 6,4 – máx 6,8 s) | 6,4 s (mín 6,3 – máx 6,5 s) |
| Datos recibidos | 2,09 MB | 2,09 MB |

**Comportamiento de la CPU.** Con 2 peticiones simultáneas el balanceador las reparte en nodos distintos; en las métricas aparecen **picos de ≈ 100 % de CPU en dos VM a la vez**, mientras la tercera permanece cercana al reposo. Cada petición tiene su propio núcleo/hilo dedicado, por eso no hay cola.

![CPU de VM1](images/part2/p2-35-cpu-vm1.png)
![CPU de las 3 VM (grupo de recursos)](images/part2/p2-36-cpu-3vms-rg.png)

#### Comparación con la Parte 1 (escalado vertical)

| Aspecto | Parte 1 – 1 VM escalada (`B1ls` → `B2ms`/`B2as_v2`) | Parte 2 – 3 VM `B2ats_v2` + balanceador |
|---|---|---|
| Punto único de falla | Sí (1 VM) | No (3 VM en 3 zonas; el balanceador saca del pool a las caídas) |
| Aprovechamiento de CPU | 1 solo hilo de Node.js (los vCPU extra quedan ociosos) | 3 procesos de Node.js independientes |
| Tiempo de inactividad al escalar | Reinicio de la VM al cambiar de tamaño | Ninguno: se agregan nodos sin tocar los demás |
| Costo mensual aproximado (compute) | `B1ls` ≈ 3,8 US$ → `B2ms` ≈ 60 US$ \* | 3 × 9,64 = **≈ 28,9 US$** + balanceador Standard \*\* |

\* Precios de lista aproximados para Linux pay-as-you-go; el valor exacto de la VM de la Parte 1 depende de la región y debe verificarse en la calculadora de Azure.
\*\* El Standard Load Balancer y las IP públicas Standard se facturan aparte (≈ 18 US$/mes la regla/balanceador y ≈ 3,6 US$/mes por IP, valores de referencia). Aun así, la infraestructura horizontal con VM pequeñas es más económica que una VM grande y, además, es la única que mejora con la concurrencia y tolera fallos.

**Conclusión del informe 1:** con 2 peticiones en paralelo, la infraestructura horizontal responde el 100 % de las peticiones y sin degradación de tiempos, porque cada petición CPU-bound se atiende en una VM distinta.

### 4. Informe de Newman 2 (punto 3): 4 procesos en paralelo

#### 4.1 Limitación: no fue posible crear la 4.ª VM
El punto 3 pide agregar una cuarta VM. **No fue posible** por la cuota de la suscripción *Azure for Students*: la región Chile Central permite **6 vCPU regionales totales** y ya estaban en uso las 6 (3 VM × 2 vCPU). Al intentar crear la VM4 Azure respondió que se necesitaban 2 vCPU y solo quedaban 0 (de 6). Se solicitó un aumento de cuota a 8 vCPU, que fue **rechazado**, y los tamaños de 1 vCPU (`B1ls`, `B1s`, `A1_v2`) que aparecen en el selector tampoco pueden usarse por la misma razón (0 vCPU libres). Evidencias:

![Cuota de vCPU 6/6 (100 %)](images/part2/p2-37-cuota-vcpu-1.png)
![Solicitud de aumento de cuota](images/part2/p2-38-cuota-vcpu-2.png)
![Tamaños de 1 vCPU listados pero sin cuota](images/part2/p2-39-tamanos-vm4.png)
![Cuota por familia Basv2 (6 de 10 vCPU)](images/part2/p2-40-cuota-familia-basv2.png)

> Dado esto, la prueba de 4 procesos en paralelo se ejecutó contra **las 3 VM disponibles** (4 peticiones concurrentes > 3 nodos). Es un escenario más exigente que el del enunciado y permite además analizar qué ocurre cuando la concurrencia supera el número de nodos.

#### 4.2 Resultados
```
newman run ... -n 10 &   (×3)
newman run ... -n 10     (4.º, en primer plano)
```

![Newman: 4 procesos en paralelo](images/part2/p2-35b-newman-4proc.png)

| Métrica | Resultado (4 procesos × 10 peticiones) |
|---|---|
| Peticiones con éxito | **33 / 40 (82,5 %)** |
| Fallos | 7 × `read ECONNRESET` |
| Tiempo de respuesta promedio | 8,0 – 10,5 s según proceso |
| Tiempo máximo | 12,2 – 16,8 s |

(Comparar con la Parte 1, donde con 4 procesos sobre una sola VM la mayor parte de las peticiones fallaba o se degradaba fuertemente.)

#### 4.3 Comportamiento de la CPU
La gráfica de CPU por VM (métrica *Percentage CPU* dividida por `ResourceId`) muestra, para la prueba con 4 procesos, **picos simultáneos de ≈ 100 % en las tres VM**, sostenidos durante toda la prueba, frente a los picos en solo dos VM de la prueba con 2 procesos. Es decir, el balanceador distribuyó la carga y todos los nodos trabajaron al límite; ningún nodo quedó ocioso mientras otro se saturaba. Además se verificó que no hubo reinicios de `forever` ni procesos terminados por falta de memoria (uptime continuo de ≈ 43–52 min en cada VM al final de la sesión y sin entradas de *OOM*).

![CPU de las 3 VM durante las pruebas](images/part2/p2-41-cpu-3vms-monitor.png)
![Uptime de forever en VM2](images/part2/p2-42-uptime-vm2.png)
![Uptime de forever en VM1](images/part2/p2-43-uptime-vm1-dmesg.png)

#### 4.4 ¿Por qué aumentó la tasa de éxito con la escalabilidad horizontal?
* Node.js ejecuta el cálculo de Fibonacci de forma **síncrona en un único hilo**: mientras atiende una petición, el *event loop* está bloqueado y no atiende nada más. En una sola VM (por grande que sea) las peticiones concurrentes se encolan detrás de la que se está calculando.
* Con balanceo de carga **cada VM atiende una petición a la vez en paralelo real** (3 procesos independientes, 3 CPU distintas), de modo que con ≤ 3 peticiones simultáneas no hay cola y la tasa de éxito es del 100 % (informe 1).
* Con 4 peticiones simultáneas y 3 nodos, una de ellas debe esperar. Mientras el *event loop* está bloqueado, el servidor no puede atender los sockets y Node cierra las conexiones *keep-alive* inactivas (`keepAliveTimeout` por defecto de 5 s) que el cliente intenta reutilizar, lo que se manifiesta como `read ECONNRESET`. Esto explica los 7 fallos, pero aun así la tasa (82,5 %) es muy superior a la de una única VM, y con una 4.ª VM (una por proceso) se esperaría volver a ≈ 100 %.
* Además, el balanceador deja de enviar tráfico a una instancia que falle el *Health Probe*, aportando disponibilidad.

### 5. Preguntas

**¿Cuáles son los tipos de balanceadores de carga en Azure y en qué se diferencian? ¿Qué es SKU, qué tipos hay y en qué se diferencian? ¿Por qué el balanceador de carga necesita una IP pública?**

* *Por exposición:* **público** (front-end con IP pública; balancea tráfico de Internet hacia las VM) e **interno/privado** (front-end con IP privada de la VNet; balancea tráfico entre capas internas). Por *capa*, el **Azure Load Balancer** trabaja en la capa 4 (TCP/UDP), mientras que **Application Gateway** (capa 7, HTTP/HTTPS, WAF, rutas por URL) y **Front Door / Traffic Manager** (global, DNS/HTTP) son otras opciones de Azure para balanceo de capa 7 o global. El *Load Balancer* también puede ser **regional** o **global (cross-region)**.
* *SKU* (*Stock Keeping Unit*) es el nivel/variante de servicio del recurso: define características, límites, SLA y precio. Para Load Balancer: **Basic** (retirado en septiembre de 2025; sin zonas ni SLA, hasta 300 instancias, abierto por defecto), **Standard** (zonas de disponibilidad, SLA 99,99 %, hasta 1000 instancias, *secure by default*: requiere NSG, soporta reglas de salida y puertos HA) y **Gateway** (para encadenar *network virtual appliances*, como firewalls). Las IP públicas también tienen SKU Basic/Standard y deben coincidir con el del balanceador (aquí, Standard).
* *IP pública:* es el punto de entrada (*front-end*) por el que los clientes de Internet alcanzan el servicio; el balanceador la publica y reenvía el tráfico (DNAT) a las IP privadas del *Backend Pool*. Sin ella, el balanceador solo sería accesible desde dentro de la red (sería un balanceador interno).

**¿Cuál es el propósito del *Backend Pool*?**
Es el conjunto de instancias (interfaces de red de las VM o *scale sets*) que reciben el tráfico balanceado. Define a qué nodos puede enviar peticiones el balanceador; agregar o quitar VM del pool es la forma de escalar horizontalmente sin cambiar el punto de acceso. Aquí contiene VM1, VM2 y VM3.

**¿Cuál es el propósito del *Health Probe*?**
Verifica periódicamente (aquí, TCP al puerto 3000 cada 5 s, con umbral de 2 fallos) si cada instancia del pool puede atender tráfico. Si una instancia falla la sonda, el balanceador deja de enviarle nuevas conexiones hasta que vuelve a responder, lo que da tolerancia a fallos y evita enviar clientes a un nodo caído.

**¿Cuál es el propósito de la *Load Balancing Rule*? ¿Qué tipos de sesión persistente existen, por qué es importante y cómo puede afectar la escalabilidad?**
Define cómo se distribuye el tráfico: asocia un front-end (IP + puerto, aquí 80/TCP) con un Backend Pool y un puerto de destino (3000), usando un *Health Probe*. Por defecto distribuye por *hash* de 5 tuplas (IP origen, puerto origen, IP destino, puerto destino, protocolo).
*Persistencia de sesión (afinidad):* **Ninguna** (hash de 5 tuplas, cada conexión puede ir a un nodo distinto), **IP de cliente** (hash de 2 tuplas: misma IP de origen → mismo nodo) e **IP de cliente y protocolo** (3 tuplas). Es importante cuando la aplicación guarda estado en memoria del servidor (sesiones, carritos), porque el cliente debe volver al mismo nodo. Sin embargo, afecta la escalabilidad: puede dejar el reparto desbalanceado (muchos clientes tras una misma IP/NAT irán a un solo nodo) y complica el escalado y la tolerancia a fallos; por eso se prefiere aplicaciones *stateless* (como esta) con persistencia **Ninguna**, o guardar el estado en un almacén externo.

**¿Qué es una *Virtual Network*? ¿Qué es una *Subnet*? ¿Para qué sirven el *address space* y el *address range*?**
Una **Virtual Network (VNet)** es una red privada y aislada en Azure donde se comunican entre sí los recursos (VM, balanceadores, etc.) y, opcionalmente, con Internet u otras redes. Una **subred** es una subdivisión de la VNet con un rango de direcciones propio que permite segmentar y aplicar políticas (NSG, rutas) por grupos de recursos. El **address space** es el bloque CIDR completo de la VNet (aquí `10.1.0.0/16`, 65.536 direcciones) y el **address range** (rango/prefijo de la subred) es el trozo de ese espacio asignado a cada subred (aquí `10.1.0.0/24`, 256 direcciones, 251 utilizables porque Azure reserva 5). Los rangos de las subredes no deben solaparse y deben caber dentro del espacio de la VNet.

**¿Qué son las *Availability Zone* y por qué seleccionamos 3 diferentes zonas? ¿Qué significa que una IP sea *zone-redundant*?**
Son ubicaciones físicamente separadas dentro de una región (con energía, red y refrigeración independientes). Al repartir VM1, VM2 y VM3 en las zonas 1, 2 y 3, la caída de un centro de datos completo solo afecta a una de las tres VM y el servicio sigue vivo (SLA superior). Una IP pública **zone-redundant** es una IP Standard que existe simultáneamente en las tres zonas: sigue disponible aunque falle una de ellas, a diferencia de una IP *zonal* (atada a una sola zona).

**¿Cuál es el propósito del *Network Security Group*?**
Es un firewall de capa 3/4 con reglas de entrada y salida (por IP, puerto, protocolo, prioridad) que permite o deniega el tráfico hacia las interfaces/subredes. Es obligatorio con el balanceador Standard (cerrado por defecto). Aquí permite SSH (22) para administración y el puerto 3000 de la aplicación.

**Informe de Newman 1 (punto 2):** ver la sección [3](#3-informe-de-newman-1-punto-2-2-procesos-en-paralelo) y la [4](#4-informe-de-newman-2-punto-3-4-procesos-en-paralelo).

### 6. Diagrama de despliegue

```mermaid
flowchart TB
    U["Clientes<br/>(navegador / Newman)"] -->|"HTTP :80"| PIP["IP pública Standard<br/>zone-redundant<br/>57.156.15.123"]

    subgraph AZ["Azure · Chile Central · Grupo de recursos SCALABILITY_LAB"]
        PIP --> LB["Standard Load Balancer (regional)<br/>Regla: TCP 80 → 3000<br/>Health Probe TCP 3000 · persistencia: Ninguna"]
        subgraph VNET["VNet 10.1.0.0/16 · Subnet 10.1.0.0/24 · NSG (22, 3000)"]
            subgraph Z1["Zona de disponibilidad 1"]
                VM1["VM1 · B2ats_v2<br/>10.1.0.4<br/>Node.js + forever :3000"]
            end
            subgraph Z2["Zona de disponibilidad 2"]
                VM2["VM2 · B2ats_v2<br/>10.1.0.5<br/>Node.js + forever :3000"]
            end
            subgraph Z3["Zona de disponibilidad 3"]
                VM3["VM3 · B2ats_v2<br/>10.1.0.6 (sin IP pública)<br/>Node.js + forever :3000"]
            end
        end
        LB -->|"Backend Pool"| VM1
        LB --> VM2
        LB --> VM3
    end
    ADM["Administrador<br/>SSH :22"] -.-> VM1
    ADM -.-> VM2
    VM1 -.->|"salto SSH"| VM3
```

### 7. Costos y limpieza
Los recursos de esta práctica (VM, balanceador Standard e IP públicas Standard) generan costo mientras existan, incluso con las VM apagadas. Al terminar se elimina el grupo de recursos `SCALABILITY_LAB` para detener la facturación.
