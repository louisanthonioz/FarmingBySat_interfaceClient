""" A partir de l'image ndvi.tif, et de quatre paramètres indiquant
les coordonnées d'un rectangle contenant les parcelles du fermier
(selon la nomenclature UTM_C1_X UTM_C1_Y UTM_C2_X UTM_C2_Y),
le script réalise un découpage de ce rectangle, et le stocke à la
racine sous le nom de carteNDVIFinale """
import rasterio, os, sys
import matplotlib.pyplot as plt
import numpy as np
from scipy import misc

"""if len(sys.argv) > 2:
     x1,y1,x2,y2 = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
     stopProg = 0
else:
    print('Le script ne peut pas se lancer, il faut lui donner 4 coordonnées')
    stopProg = 1
"""
x1=374453
y1=5587986
x2=378986
y2=5584458

if(1==1):#stopProg==0):
    """Récupération des paramètres  nécessaires à la géolocalisation
    Le fichier ndvi.tif est la carte sentinel transformée en NDVI"""
    with rasterio.open('ndvi.tif') as src:
        monImage = src.read()
        epsg = (int(str(rasterio._crs.UserDict(src.crs))[15:20]))
        taille = np.zeros(2,dtype=np.int16)
        largeur, hauteur = src.width, src.height
        matriceConfiguration = (src.transform)

    ## Coordonnées WGS84 haut droit de l'image monImage
    UTM_NDVI_X = matriceConfiguration[2]
    UTM_NDVI_Y = matriceConfiguration[5]
    UTM_NDVI_Zone = epsg%100
    if (str(epsg)[2]=='6'):
        UTM_NDVI_Hemisphère = 'N'
    else:
        UTM_NDVI_Hemisphère = 'S'

    ## Coordonnées C1 et C2 en WGS84, rectangle demandé par l'agriculteur
    UTM_C1_X = int(x1)
    UTM_C1_Y = int(y1)
    UTM_C2_X = int(x2)
    UTM_C2_Y = int(y2)

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
    outfile = r'.\carteNDVIFinale.tif'

    with rasterio.open(outfile, 'w', driver='GTiff', height=hauteur,
                              width=largeur, count=1, dtype=np.float32,
                              crs=src.crs, transform=matriceConfiguration.from_gdal(UTM_C1_X, 10, 0, UTM_C1_Y, 0, -10)) as dst:
        dst.write(imageCoupee.astype(np.float32))
