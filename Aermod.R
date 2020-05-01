#------------------------------------------------------------------------------#
#                                                                              #
#                             EJEMPLO DE EJECUCIÓN AEREMT                      #
#                                                                              #
#------------------------------------------------------------------------------#

# Carga / Instalación de librerias
pkgTest <- function(x) {                                                        
  if (!require(x,character.only = TRUE)) {                                      
    install.packages(x,dep = TRUE)                                              
    if(!require(x,character.only = TRUE))                                       
      stop("Package not found") } }                                             
pkg <- c("tidyverse", "openair")
for(i in 1:length(pkg)){ pkgTest(pkg[i]) }   
rm(pkgTest, pkg)

# Ubicación del ejecutale AERMET
aermod_ubicacion <- "C:/DOS/AERMOD/aermod.exe"

# Ejecutar AERMOD para ploteo
system(paste(aermet_ubicacion, "PLOTEO.INP"))

# Ejecutar AERMOD para serie de tiempo
system(paste(aermet_ubicacion, "TSERIES.INP"))

# Importar resultados para ploteo


# Importar resultados para serie te tiempo


# Gráficos resumen