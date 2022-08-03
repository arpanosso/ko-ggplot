#############
# Script Aula 5 - Krigagem Ordinária com criação do grid expandido
#############
# Instalando o pacote gstat
#############

#install.packages("gstat")
#install.packages("sp")
#install.packages("maptools")
#install.packages("raster")

library(sp)       # pacote para chamar shapes
library(maptools) # pacote para editar mapas
library(raster)   # pacote para chamar rasteres
library(gstat)    # pacote geoestatística
library(graphics) # pacote gráfico
library(lattice)  # pacote lattice

#############
# Duas opções 
# 1ª) determine o caminho de procura do arquivo de dados acionando as abas no RStudio:
# Session/Set Working Directory/Choose Directory/..., ou
# 2ª) pela área de trabalho (clipboard)

#############
dados.Broom<-read.table("C:/Users/renat/Desktop/KO ggplot/BroomBarnFarm.txt",h=T) # lendo o arquivo de dados pelo caminho indicado
head(dados.Broom)                        #  imprimindo as 6 primeiras linhas do arquivo
attach(dados.Broom)

coordinates(dados.Broom) <- c("X","Y") # definindo as coordenadas do arquivo

###################
#    Variograma da váriavel alvo
###################

(v.pH<-variogram(pH~1,dados.Broom)) # calculando e imprimindo o arquivo do variograma experimental 

x11()
plot(v.pH,pl=F,pch=16,col=1,   # gráfico do variograma 
     xlab="Distância",
     ylab="Semivariância")   

# modelagem do variograma experimental com os valores iniciais
(m.pH <- fit.variogram(v.pH,vgm(0.35,"Sph",6,0)))

# calculando e imprimindo a soma de quadrados do erro (SQErro)
(sqr.pH<-attr(m.pH, "SSErr"))

# Gráfico do variograma experimental com o modelo ajustado
x11()
plot(v.pH,model=m.pH, col=1,pl=F,pch=16,
     xlab="Distância",
     ylab="Semivariância",
     main =" Variável pH\n esf(0,0165; 0,339; 4.9291; 0.2149)")

######################################
#Criando GRID
######################################

dist <- 0.1 #  Distancia entre pontos
grid.Broom <- expand.grid(X=seq(min(dados.Broom$X),max(dados.Broom$X),dist), Y=seq(min(dados.Broom$Y),max(dados.Broom$Y),dist))
coordinates(grid.Broom) <- ~ X + Y

grid.Broom<-as(grid.Broom,"SpatialPixelsDataFrame")
######################################
#1ª) opção - criar o Contorno com o script a seguir
######################################
#x11()
#plot(dados.Broom, pch=16)
#coords <- locator(type="l", col='red') # Desenhando contorno
#coords <- as.data.frame(coords) # display list
#coords = rbind(coords, coords[1,]) # igualando primeiro e ultimo ponto
#contorno =SpatialPolygons( list(Polygons(list(Polygon(coords)), 1))) #Trasnformação do arquivo contorno em poligono
#X11() 
#plot(contorno,lwd=2) # imprimindo o contorno

#################
#2ª) opçao - leitura do arquivo contorno (Atenção!! É necessário estabelecer o caminho de leitura )

coords<-read.table("C:/Users/renat/Desktop/KO ggplot/contornoBroomBarnFarm1.txt",h=T)
head(coords)

# Trasnformação do contorno em arquivo poligono espacial
contorno = SpatialPolygons( list(Polygons(list(Polygon(coords)), 1))) 

x11()
plot(X,Y,pch=16,cex=0.2) # gráfico da malha amostral
plot(contorno,add=T)     # adicionando o poligono do contorno

#################
#  KRIGAGEM
#################

ko.pH <- krige(pH~1, 
               dados.Broom,   # especificando o arquivo de dados
               grid.Broom,       # especificando o arquivo grid expandidos para receber as estimativas 
               m.pH,             # especificando o modelo ajustado
               nmin=7,           # número mínimo de vizinhos
               nmax=25,          # número máximo de vizinhos
               #              block=c(4,4),     # opção por krigagem por bloco
               na.action=na.pass,# função que determina o deve ser feito com missing values
               debug.level=-1, # mostra o progresso em porcentagem do procedimento
)

library(tidyverse) # carregando o pacote
# imprimindo o mapa da variabilidade espacial com o comando spplot()
names(ko.pH)<-c("pH","Variância")
as.tibble(ko.pH) %>% # data.frame
  ggplot(aes(x=X,y=Y)) + # definindo as coordenadas
  geom_tile(aes(fill = pH )) + # definindo o pixel (tile)
  ggplot2::scale_fill_gradient(low = "yellow", high = "blue") +# gradiente de cor
  ggplot2::coord_equal() # talvez seja dispensável...


# conversões dos arquivos
ko.pH <- as.data.frame(ko.pH)  # convertendo o arquivo da krigagem em data.frame (linhas e colunas)
coordinates(ko.pH)=~X+Y        # estabelcendo as coordenadas
gridded(ko.pH)=TRUE            # diz se o objeto é gridded ou não
ko.pH <- raster(ko.pH)         # converções

#Recortando com o contorno
ko.pH <- mask(ko.pH, contorno, inverse=FALSE)
#x11()
#plot(ko.pH,main="Mapa espacial\n Modelagem isotropica")
#plot(contorno, add=T)
#contour(ko.pH, add=T, nlevels = 6)

# gráfico pela função spplot()
x11()
spplot(ko.pH,scales=list(draw=T),key.space="rigth",
       colorkey=T,main="Mapa espacial: pH (KO))")
