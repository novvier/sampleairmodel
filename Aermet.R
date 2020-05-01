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
pkg <- c("dplyr", "openair")
for(i in 1:length(pkg)){ pkgTest(pkg[i]) }   
rm(pkgTest, pkg)

# Ubicación del ejecutale AERMET
aermet_ubicacion <- "C:/DOS/AERMOD/aermet.exe"

# Ejecutar STAGE 1
system(paste(aermet_ubicacion, "STAGE1.INP"))

# Ejecutar STAGE 2
system(paste(aermet_ubicacion, "STAGE2.INP"))

# Ejecutar STAGE 3
system(paste(aermet_ubicacion, "STAGE3.INP"))

# Importar resultados de superficie (*.SFC)
sfc <- read.table("SURFACE.SFC", header = FALSE, skip = 1, fill = TRUE)
names(sfc) <- c("YR"  , "MO"  , "DY"  , "JDAY", "HR"  , "HFLX", "USTR",       
                "WSTR", "DTDZ", "Z_IC", "Z_IM", "L_MO", "Z0_R", "BWNR",       
                "ALBD", "WSPD", "WDIR", "WHGT", "TEMP", "THGT", "PRCD",       
                "PRCP", "RHUM", "PRES", "CLDC", "WSADJ", "FLAG") 
### Corregir el formato de hora. De 1-24 a 0-23                                 
sfc$HR <- sfc$HR - 1                                                          
date <- paste(sfc$YR, sfc$MO, sfc$DY, sfc$HR, sep = "-")                      
date <- as.POSIXct(strptime(date, format = "%y-%m-%d-%H"))                    
sfc <- sfc[, 6:27]                                                            
sfc <- cbind(date, sfc)
print(head(sfc))

# Importar resultados de perfil (*.PFL) (en desarrollo)

# Gráficos resumen

### Rosa de vientos
windRose(mutate(sfc, WSPD = ifelse(WSPD < 0.5, 0, WSPD)), 
         wd = "WDIR", ws = "WSPD", angle = 22.5, paddle = F, type = "daylight")

### Variación de la temperatura
timePlot(sfc, "TEMP")

### Variación de la altura de la capa límite
sfc$Z_IC <- ifelse(sfc$Z_IC == -999, NA, sfc$Z_IC)
timePlot(sfc[1:48,], c("Z_IC", "Z_IM"), date.pad = F, group = T)


