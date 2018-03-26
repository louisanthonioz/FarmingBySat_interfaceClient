"""  Ce fichier Python permet de générer une image NDVI
     A partir de 2 images Sentinel de format jp2, il retourne un
     fichier image de format tif où chaque pixel (10*10m) présente
     une valeur de NDVI entre 0 et 255
     On lui a ajouté le script permettant de découper l'image par la site
     ARGS : url_B4 url_B8 UTM_C1_X UTM_C1_Y UTM_C2_X UTM_C2_Y """
import os, rasterio, sys
import matplotlib.pyplot as plt
import numpy as np
from scipy import misc

firstName = sys.argv[7]
name = sys.argv[8]
phoneNumber = sys.argv[9]

if len(sys.argv) > 2:
     x,y = sys.argv[1], sys.argv[2]
     stopProg = 0
else:
    print('Le script ne peut pas se lancer, il faut lui donner 2 urls image')
    stopProg = 1

if(stopProg==0):
    outfile = r'./Ressources/farmingData/'+firstName+'_'+name+'_'+phoneNumber+'/ndviGlobal.tif'
    #url to the bands
    b4 = x
    b8 = y

    #open the bands (I can't believe how easy is this with rasterio!)
    with rasterio.open(b4) as red:
        RED = red.read()
    with rasterio.open(b8) as nir:
        NIR = nir.read()

    #compute the ndvi
    ndvi = (NIR.astype(float) - RED.astype(float)) / (NIR+RED)
    #print(ndvi.min(), ndvi.max()) The problem is alredy here

    profile = red.meta
    profile.update(driver='GTiff')
    profile.update(dtype=rasterio.float32)

    with rasterio.open(outfile, 'w', **profile) as dst:
        dst.write(ndvi.astype(rasterio.float32))


""" A partir de l'image ndvi.tif, et de quatre paramètres indiquant
les coordonnées d'un rectangle contenant les parcelles du fermier
(selon la nomenclature UTM_C1_X UTM_C1_Y UTM_C2_X UTM_C2_Y),
le script réalise un découpage de ce rectangle, et le stocke à la
racine sous le nom de carteNDVIFinale """


if len(sys.argv) > 6:
     x1,y1,x2,y2 = sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
     stopProg = 0
else:
    print('Le script ne peut pas se lancer, il faut lui donner 4 coordonnées')
    stopProg = 1

if(stopProg==0):
    """Récupération des paramètres  nécessaires à la géolocalisation
    Le fichier ndvi.tif est la carte sentinel transformée en NDVI"""
    with rasterio.open('./Ressources/farmingData/'+firstName+'_'+name+'_'+phoneNumber+'/ndviGlobal.tif') as src:
        monImage = src.read()
        epsg = (int(str(rasterio._crs.UserDict(src.crs))[15:20]))
        taille = np.zeros(2,dtype=np.int16)
        largeur, hauteur = src.width, src.height
        matriceConfiguration = (src.transform)

    ## Coordonnées WGS84 haut gauche de l'image monImage
    UTM_NDVI_X = matriceConfiguration[0]
    UTM_NDVI_Y = matriceConfiguration[3]
    UTM_NDVI_Zone = epsg%100
    if (str(epsg)[2]=='6'):
        UTM_NDVI_Hemisphère = 'N'
    else:
        UTM_NDVI_Hemisphère = 'S'

    ## Coordonnées C1 et C2 en WGS84, rectangle demandé par l'agriculteur
    ## Et on remet dans l'ordre les points
    if(x1<=x2):
        UTM_C1_X = int(float(x1))
        UTM_C1_Y = int(float(y1))
        UTM_C2_X = int(float(x2))
        UTM_C2_Y = int(float(y2))
    else:
        UTM_C1_X = int(float(x2))
        UTM_C1_Y = int(float(y2))
        UTM_C2_X = int(float(x1))
        UTM_C2_Y = int(float(y1))


    ## Calcul de la Zone à conserve (coordonnées relatives 0,0)
    ## Attention aux signes, on descend en coordonnées selon Y
    ## On divise par 10 car l'image a une résolution de 10m
    IMAGE_X_C1 = int((UTM_C1_X - UTM_NDVI_X)/10);
    IMAGE_Y_C1 = int((UTM_C1_Y - UTM_NDVI_Y)/10);
    IMAGE_X_C2 = int((UTM_C2_X - UTM_NDVI_X)/10);
    IMAGE_Y_C2 = int((UTM_C2_Y - UTM_NDVI_Y)/10);
    largeur = abs(IMAGE_X_C2 - IMAGE_X_C1)#Nouvelle largeur rectangle
    hauteur = abs(IMAGE_Y_C2 - IMAGE_Y_C1)#Nouvelle hauteur rectangle

    ## On envoie les données dans une nouvelle matrice réduite, et on change les données de matriceTransformation
    imageCoupee = np.zeros((1, hauteur, largeur),dtype=np.float32)
    for i in range (0,largeur):
        for j in range (0,hauteur):
            imageCoupee[0][j][i] = monImage[0][j-IMAGE_Y_C1][i+IMAGE_X_C1]

    ## On sauvegarde cette matrice en tif avec ces nvelles coordonnées
    outfile = r'./Ressources/farmingData/'+firstName+'_'+name+'_'+phoneNumber+'/carteNDVIFinale.tif'

    with rasterio.open(outfile, 'w', driver='GTiff', height=hauteur,
                              width=largeur, count=1, dtype=np.float32,
                              crs=src.crs, transform=[UTM_C1_X,10,0,UTM_C1_Y,0,-10]) as dst:
        dst.write(imageCoupee.astype(np.float32))
#transform=matriceConfiguration.from_gdal(UTM_C1_X, 10, 0, UTM_C1_Y, 0, -10)
