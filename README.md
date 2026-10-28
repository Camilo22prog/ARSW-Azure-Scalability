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

### Parte 2 - Escalabilidad horizontal

#### Crear el Balanceador de Carga

Antes de continuar puede eliminar el grupo de recursos anterior para evitar gastos adicionales y realizar la actividad en un grupo de recursos totalmente limpio.

1. El Balanceador de Carga es un recurso fundamental para habilitar la escalabilidad horizontal de nuestro sistema, por eso en este paso cree un balanceador de carga dentro de Azure tal cual como se muestra en la imágen adjunta.

![](images/part2/part2-lb-create.png)

2. A continuación cree un *Backend Pool*, guiese con la siguiente imágen.

![](images/part2/part2-lb-bp-create.png)

3. A continuación cree un *Health Probe*, guiese con la siguiente imágen.

![](images/part2/part2-lb-hp-create.png)

4. A continuación cree un *Load Balancing Rule*, guiese con la siguiente imágen.

![](images/part2/part2-lb-lbr-create.png)

5. Cree una *Virtual Network* dentro del grupo de recursos, guiese con la siguiente imágen.

![](images/part2/part2-vn-create.png)

#### Crear las maquinas virtuales (Nodos)

Ahora vamos a crear 3 VMs (VM1, VM2 y VM3) con direcciones IP públicas standar en 3 diferentes zonas de disponibilidad. Después las agregaremos al balanceador de carga.

1. En la configuración básica de la VM guíese por la siguiente imágen. Es importante que se fije en la "Avaiability Zone", donde la VM1 será 1, la VM2 será 2 y la VM3 será 3.

![](images/part2/part2-vm-create1.png)

2. En la configuración de networking, verifique que se ha seleccionado la *Virtual Network*  y la *Subnet* creadas anteriormente. Adicionalmente asigne una IP pública y no olvide habilitar la redundancia de zona.

![](images/part2/part2-vm-create2.png)

3. Para el Network Security Group seleccione "avanzado" y realice la siguiente configuración. No olvide crear un *Inbound Rule*, en el cual habilite el tráfico por el puerto 3000. Cuando cree la VM2 y la VM3, no necesita volver a crear el *Network Security Group*, sino que puede seleccionar el anteriormente creado.

![](images/part2/part2-vm-create3.png)

4. Ahora asignaremos esta VM a nuestro balanceador de carga, para ello siga la configuración de la siguiente imágen.

![](images/part2/part2-vm-create4.png)

5. Finalmente debemos instalar la aplicación de Fibonacci en la VM. para ello puede ejecutar el conjunto de los siguientes comandos, cambiando el nombre de la VM por el correcto

```
git clone https://github.com/daprieto1/ARSW_LOAD-BALANCING_AZURE.git

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
source /home/vm1/.bashrc
nvm install node

cd ARSW_LOAD-BALANCING_AZURE/FibonacciApp
npm install

npm install forever -g
forever start FibonacciApp.js
```

Realice este proceso para las 3 VMs, por ahora lo haremos a mano una por una, sin embargo es importante que usted sepa que existen herramientas para aumatizar este proceso, entre ellas encontramos Azure Resource Manager, OsDisk Images, Terraform con Vagrant y Paker, Puppet, Ansible entre otras.

#### Probar el resultado final de nuestra infraestructura

1. Porsupuesto el endpoint de acceso a nuestro sistema será la IP pública del balanceador de carga, primero verifiquemos que los servicios básicos están funcionando, consuma los siguientes recursos:

```
http://52.155.223.248/
http://52.155.223.248/fibonacci/1
```

2. Realice las pruebas de carga con `newman` que se realizaron en la parte 1 y haga un informe comparativo donde contraste: tiempos de respuesta, cantidad de peticiones respondidas con éxito, costos de las 2 infraestrucruras, es decir, la que desarrollamos con balanceo de carga horizontal y la que se hizo con una maquina virtual escalada.

3. Agregue una 4 maquina virtual y realice las pruebas de newman, pero esta vez no lance 2 peticiones en paralelo, sino que incrementelo a 4. Haga un informe donde presente el comportamiento de la CPU de las 4 VM y explique porque la tasa de éxito de las peticiones aumento con este estilo de escalabilidad.

```
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10 &
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10 &
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10 &
newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10
```

**Preguntas**

* ¿Cuáles son los tipos de balanceadores de carga en Azure y en qué se diferencian?, ¿Qué es SKU, qué tipos hay y en qué se diferencian?, ¿Por qué el balanceador de carga necesita una IP pública?
* ¿Cuál es el propósito del *Backend Pool*?
* ¿Cuál es el propósito del *Health Probe*?
* ¿Cuál es el propósito de la *Load Balancing Rule*? ¿Qué tipos de sesión persistente existen, por qué esto es importante y cómo puede afectar la escalabilidad del sistema?.
* ¿Qué es una *Virtual Network*? ¿Qué es una *Subnet*? ¿Para qué sirven los *address space* y *address range*?
* ¿Qué son las *Availability Zone* y por qué seleccionamos 3 diferentes zonas?. ¿Qué significa que una IP sea *zone-redundant*?
* ¿Cuál es el propósito del *Network Security Group*?
* Informe de newman 1 (Punto 2)
* Presente el Diagrama de Despliegue de la solución.
