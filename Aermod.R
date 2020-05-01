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
pkg <- c("tidyverse", "openair", "raster", "fields", "RStoolbox", "metR")
for(i in 1:length(pkg)){ pkgTest(pkg[i]) }   

# Ubicación del ejecutale AERMET
aermod_ubicacion <- "C:/DOS/AERMOD/aermod.exe"

# Ejecutar AERMOD para ploteo
system(paste(aermod_ubicacion, "PLOTEO.INP"))

# Ejecutar AERMOD para serie de tiempo
system(paste(aermod_ubicacion, "TSERIES.INP"))

# Importar resultados de ploteo
CO_01HR_PLOT <- read.fortran("CO_01HR.PLT", rep(c("1X", "F13"), 3), skip = 8, 
                        header = FALSE)
names(CO_01HR_PLOT) <- c("X", "Y", "CONC")

CO_08HR_PLOT <- read.fortran("CO_08HR.PLT", rep(c("1X", "F13"), 3), skip = 8, 
                        header = FALSE)
names(CO_08HR_PLOT) <- c("X", "Y", "CONC")

# Importar resultados para series de tiempo
### 1 HORA
CO_01HR_TSER <- read.fortran("CO_01HR.DAT", 
                             c(rep(c("1X", "F13"), 3), "47X", "A8"), 
                             skip = 8, header = FALSE)
names(CO_01HR_TSER) <- c("X", "Y", "CONC", "date")
head(CO_01HR_TSER, 25)

CO_01HR_TSER <- CO_01HR_TSER %>% 
  dplyr::mutate(date = as.POSIXct(strptime(date, format = "%y%m%d%H")),
                date = date - 3600,
                punto = rep(c("BAR", "SOT"), nrow(CO_01HR_TSER)/2)) %>% 
  dplyr::select(-X, -Y) %>% 
  tidyr::spread(key = "punto", value = "CONC")
head(CO_01HR_TSER, 25)

### 8 HORAS
CO_08HR_TSER <- read.fortran("CO_08HR.DAT", 
                             c(rep(c("1X", "F13"), 3), "47X", "A8"), 
                             skip = 8, header = FALSE)
names(CO_08HR_TSER) <- c("X", "Y", "CONC", "date")
head(CO_08HR_TSER, 25)

CO_08HR_TSER <- CO_08HR_TSER %>% 
  dplyr::mutate(date = as.POSIXct(strptime(date, format = "%y%m%d%H")),
                date = date - 3600,
                punto = rep(c("BAR", "SOT"), nrow(CO_08HR_TSER)/2)) %>% 
  dplyr::select(-X, -Y) %>% 
  tidyr::spread(key = "punto", value = "CONC")
head(CO_08HR_TSER, 25)

# Interpolación
### Proyección en formato PROJ4 (https://epsg.io/32718)
proyUTM18 <- "+proj=utm +zone=18 +south +datum=WGS84 +units=m +no_defs"

intSpline <- function(x, res, proj4){
  # res: resolución en metros
  # proj: Projección en PROJ4 (https://epsg.io)
  coordinates(x) <- ~X+Y
  crs(x) <- crs(proj4)
  rst <- raster(x, resolution = res)
  m <- fields::Tps(coordinates(x), x$CONC)
  tps <- raster::interpolate(rst, m)
  cat(paste("Finished spline interpolation\n"))
  values(tps) <- ifelse(values(tps) < 0 , 0, values(tps))
  return(tps)
}

CO_01HR_RST <- intSpline(CO_01HR_PLOT, 5, proyUTM18)
plot(CO_01HR_RST)

CO_08HR_RST <- intSpline(CO_08HR_PLOT, 5, proyUTM18)
plot(CO_08HR_RST)

# Graficos de distribución espacial
colores <- c("#8CDAF2", "#12087C", "#034D5B", "#03A72D", "#25E70C",
             "#71FF00", "#C6F100", "#F6BE00", "#FF6300", "#FF0000")
ug_m3 <- bquote(paste("(", mu, g, "/", m^3, ")"))

postPlot <- function(x){
  ggR(img = x) +
    geom_contour_fill(data = x, aes(x = x, y = y, z = layer),
                      alpha = 0.4, na.fill = TRUE) +
    scale_fill_gradientn(colours = colorRampPalette(colores)(10)) +
    geom_contour(data = x, color = "white", aes(x, y, z = layer),
                 size = 0.01) +
    geom_text_contour(data = x, aes(x, y, z = layer), min.size = 5, 
                      check_overlap = TRUE, stroke = 0.1, size = 3) +
    labs(x = "Este", y = "Norte", size = NULL, fill = ug_m3) +
    theme_bw() +
    theme(legend.key.height = unit(1, "cm"))
}

CO_01_GRAF <- postPlot(CO_01HR_RST)
plot(CO_01_GRAF)

CO_01_GRAF <- postPlot(CO_08HR_RST)
plot(CO_01_GRAF)

# Graficos de sereie de tiempo
timePlot(dplyr::mutate(CO_01HR_TSER, BAR = ifelse(BAR == 0, NA, BAR),
                       SOT = ifelse(SOT == 0, NA, SOT)),
                       c("BAR", "SOT"), group = T)

