library(terra)

pts <- vect("data/raw/sites.gpkg")
buffer_size <- 30
pts_30 <- buffer(pts, buffer_size)

# Kralovehradecky
kves_path_kr <- "data/raw/KVES_Kralovehradecky.zip" 
kves_kr <- vect(file.path("/vsizip",kves_path_kr,"KVES_Kralovehradecky.shp"))
kves_kr <- intersect(kves_kr, pts_30)
kves_kr <- kves_kr[, "KATEGORIE"]

# Liberecky
kves_path_lib <- "data/raw/KVES_Liberecky.zip"
kves_lib <- vect(file.path("/vsizip",kves_path_lib,"KVES_Liberecky.shp"))
kves_lib <- intersect(kves_lib, pts_30)
kves_lib <- kves_lib[, "KATEGORIE"]

# merge, and dissolve on merged boundary
kves <- rbind(kves_kr, kves_lib)
kves <- aggregate(kves, by = "KATEGORIE")
kves <- disagg(kves)
kves$agg_n <- NULL

# separete to sites, and disaggregate patches
kves <- intersect(kves, pts_30)
kves <- disagg(kves)


#rename to codes
x <- read.csv("metadata/es_meta.csv")
kves$KATEGORIE <- x$code[match(kves$KATEGORIE, x$cat_cs)]

site_es <- as.data.frame(pts[,"site_id"])
site_es[,unique(kves$KATEGORIE)] <- 0
site_es[,c("es_np","es_lpi")] <- NA

kves$Shape_Leng <- NULL
kves$Shape_Area <- NULL

kves$area <- expanse(kves,"m")

kves$area <- as.integer(ceiling(kves$area)) 
kves <- as.data.frame(kves)

for (i in unique(site_es$site_id)) {
    print(i)
    for (cat in unique(kves[kves$site_id == i,]$KATEGORIE)) {
        site_es[site_es$site_id == i,cat] <- sum(kves[kves$site_id == i & kves$KATEGORIE == cat,]$area)/sum(kves[kves$site_id == i,]$area)
        site_es[site_es$site_id == i,cat] <- ceiling(site_es[site_es$site_id == i,cat]*1000)/1000
    }
    site_es[site_es$site_id == i,]$es_np <- nrow(kves[kves$site_id == i,])
    site_es[site_es$site_id == i,]$es_lpi <- max(kves[kves$site_id == i,]$area)/sum(kves[kves$site_id == i,]$area)
    site_es[site_es$site_id == i,]$es_lpi <- ceiling(site_es[site_es$site_id == i,]$es_lpi*1000)/1000
}

# export
dir.create("data/raw/processed", showWarnings = FALSE)

write.csv(site_es, "data/processed/sites_es.csv", row.names = FALSE, na = "")
