as -march=armv6 -o batalla_naval.o batalla_naval.s // Enlazar el archivo objeto para crear el ejecutable
ld -o batalla_naval batalla_naval.o  // Ejecutar el programa
chmod +x batalla_naval // Dar permisos de ejecución al archivo
./batalla_naval // Ejecutar el programa en la terminal