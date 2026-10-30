@echo off
echo ========================================================
echo   Lanzando 4 procesos Newman en paralelo contra el LB
echo ========================================================
start "Newman Proceso 1" cmd /k "newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10"
start "Newman Proceso 2" cmd /k "newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10"
start "Newman Proceso 3" cmd /k "newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10"
start "Newman Proceso 4" cmd /k "newman run ARSW_LOAD-BALANCING_AZURE.postman_collection.json -e [ARSW_LOAD-BALANCING_AZURE].postman_environment.json -n 10"
