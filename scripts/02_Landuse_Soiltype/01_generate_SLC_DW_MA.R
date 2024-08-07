library('raster')
library('sf')

#read the landuse raster
landuse <- raster('/home/paulc600/scratch/land_soil/landsat/landsat_repro.tif')
#read the soil texture raster
soiltex <- raster('/home/paulc600/scratch/land_soil/soil/soil_soil_classes.tif')

#resample landuse to match soil resolution
landuse <- resample(landuse, soiltex, method='ngb')
#overlay both rasters to get SLCs

SLC_ras <- landuse*100+soiltex

nSLC <- length(unique(getValues(SLC_ras)))
slc_val <- as.numeric(na.omit(unique(getValues(SLC_ras))))
#get SLC per subbasin
#read subbasin shp

# catchments polygon
cat_poly <- read_sf('/home/paulc600/github/StMaryMilk2023-UofC/modified_TGF/smm_tgf_modified/smm_cat.shp')

# Shapefile reprojection
cat_poly <- st_transform(cat_poly, crs(SLC_ras))

#create empty data.frame with slc_val and hru_nhm
slc_frac <- matrix(data = 0, nrow = length(cat_poly$hru_nhm),
                   ncol = length(slc_val))
colnames(slc_frac) <- slc_val
rownames(slc_frac) <- cat_poly$hru_nhm

for (i in 1:length(cat_poly$hru_nhm)) {
  print(i)
  maski <- cat_poly[i,]
  
  ## crop and mask extraction
  slc_ras_i <- crop(SLC_ras, maski)
  slc_ras_i <- mask(slc_ras_i,maski)
  
  # getvalues of the cropped raster
  vali <- unlist(getValues(slc_ras_i))
  #remove pixel values of 0,2,4 because they have no LC data no_data
  vali[vali %in% c(0)] <- NA
  # combine SLCs with no ST info into the water class
  #combine water class with different ST into one class
  vali <- vali[!is.na(vali)] #remove na
  
  ncells <- length(vali)
  
  for (j in 1:length(slc_val)) {
    
    ncell_j <- length(which(vali == slc_val[j]))
    fracj <- ncell_j/ncells
    slc_frac[i,j] <- fracj
    
  }
}

write.csv(x = slc_frac, file = 'HYPE_landsat.csv', quote = F)
# # Plot them, one layer after another
# plot(slc_ras_i)
# plot(maski, add=TRUE)

