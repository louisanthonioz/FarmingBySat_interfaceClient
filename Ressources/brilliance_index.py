import os,rasterio
import matplotlib.pyplot as plt
import numpy as np
import sys
from scipy import misc

b2 = sys.argv[1]
b3 = sys.argv[2]
b4 = sys.argv[3]
b8 = sys.argv[4]
b10 = sys.argv[5]
b12 = sys.argv[6]
name = sys.argv[7]

outfile = r'farmingData/'+name+'.tif'

with rasterio.open(b2) as b2:
    B2 = b2.read()
with rasterio.open(b3) as b3:
    B3 = b3.read()
with rasterio.open(b4) as b4:
    B4 = b4.read()
with rasterio.open(b8) as b8:
    B8 = b8.read()
with rasterio.open(b10) as b10:
    B10 = b10.read()
with rasterio.open(b12) as b12:
    B12 = b12.read()

bi = ((0.3037*B2.astype(float))+(0.2793*B3.astype(float))+(0.4743*B4.astype(float))+(0.5585*B8.astype(float))+(0.5082*B10.astype(float))+(0.1863*B12.astype(float)))

profile = b2.meta
profile.update(driver='GTiff')
profile.update(dtype=rasterio.float32)

with rasterio.open(outfile,'w', **profile) as dst:
    dst.write(bi.astype(rasterio.float32))
