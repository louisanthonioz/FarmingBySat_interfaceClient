""" Script python permettant de réaliser une carte NDVI à partir de 2 images jp2
de types B4 et B8. Il faut lui passer l'url de ces deux cartes en paramètres,
et il retourne à la racine un fichier ndvi.tif """
import os, rasterio
import matplotlib.pyplot as plt
import numpy as np
import sys
from scipy import misc

#url to the bands
b4 = sys.argv[1]
b8 = sys.argv[2]
name = sys.argv[3]

outfile = r'farmingData/'+name+'.tif'

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

monImage = misc.imread(name+".tif")
#monImageReelle = misc.imread("L2A_T32ULA_20171020T104051_TCI_10m.jp2")
#couvertureNuageuse = misc.imread("L2A_T32ULA_20171020T104051_AOT_10m.jp2")
#plt.figure(1)
#plt.imshow(monImage)
##plt.figure(2)
##plt.imshow(monImageReelle)
##plt.figure(3)
##plt.imshow(couvertureNuageuse)
#plt.show()
