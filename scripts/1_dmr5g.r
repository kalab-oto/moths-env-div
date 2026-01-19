library(terra)
library(lidR)
library(sf)
library(spatialEco) #hli, #vrm

# modified lidR:::kriging for kriging variance
kriging_var = function(model = gstat::vgm(.59, "Sph", 874), k = 10L) {
    lidR:::assert_package_is_installed("gstat")

    f = function(las, where){
        lidR:::assert_is_valid_context("rasterize_terrain", "kriging_var")
        return(interpolate_kriging_var(las, where, model, k))
    }
    f <- plugin_dtm(f)
    return(f)
}

interpolate_kriging_var = function(points, coord, model, k) {
    X <- Y <- Z <- NULL
    if (!getOption("lidR.verbose")) sink(tempfile())
    if (inherits(points, "LAS")) points <- points@data
    x  <- gstat::krige(Z~X+Y, location = ~X+Y, data = points, newdata = coord, model, nmax = k)
    sink()
    return(x$var1.var)
}

# modified spatialEco::vrm based on Dilts et al. (2023)
vrml <- function(dem) {
    dem_3 <- focal(dem, w = matrix(1, 3, 3), fun = mean, na.policy = "omit")
    ldd <- dem - dem_3
    r_vrml <- vrm(ldd)
    return(r_vrml)
}

# load data
pts <- vect("data/raw/sites.gpkg")
buffer_size <- 30

pts_30 <- buffer(pts, buffer_size)
pts_40 <- buffer(pts, buffer_size + 10)
pts_40 <- st_as_sf(pts_40)

site_t <- as.data.frame(pts[,"site_id"])
pcl_krig_report <- as.data.frame(pts[,"site_id"])

map_lists <- st_read("data/processed/DMR5G_map_list.gpkg")
map_lists <- st_transform(map_lists, 5514)

las_list <- vector("list", nrow(pts_40))

metrics <- list(
    mean = mean,
    sd = sd,
    p01 = function(x, ...) quantile(x, probs = 0.01, na.rm = TRUE),
    p99 = function(x, ...) quantile(x, probs = 0.99, na.rm = TRUE)
)

for (i in seq(nrow(site_t))) {
    las_names <- gsub(".zip",".laz",basename(map_lists[pts_40[i,],]$link_zip))

    las <- readLAS(file.path("data/raw","DMR5G",las_names))

    crs(las) <- crs("EPSG:5514")

    las <- clip_roi(las, pts_40[i,])
    las@data$Classification[las@data$Classification == 8] <- 2

    las <- filter_ground(las)

    
    dem <- rasterize_terrain(las, algorithm = kriging(k = 10), res = 0.5)

    dem_se <- app(rasterize_terrain(las, algorithm = kriging_var(k = 10), res = 0.5),sqrt)

    slope <- terrain(dem, v = "slope")
    r_vrml <- vrml(dem)  
    r_hli <- hli(dem)
    aspect <- terrain(dem, v = "aspect")
    
    r_list <- list(
        t_elev = dem,
        t_slope = slope,
        t_vrml = r_vrml,
        t_hli = r_hli
    )

    for (r_name in names(r_list)) {
        r <- r_list[[r_name]]

        for (m_name in names(metrics)) {
            fun <- metrics[[m_name]]
            colname <- paste0(r_name, "_", m_name)
            site_t[i, colname] <- extract(r, pts_30[i,], fun = fun, na.rm = TRUE)[2]
        }
    }
  
    aspect[slope == 0] <- -1

    r_aspect <- classify(aspect, rcl = matrix(c(-1.5, -0.5, 0,
                                               0, 22.5, 1,
                                               22.5, 67.5, 2,
                                               67.5, 112.5, 3,
                                               112.5, 157.5, 4,
                                               157.5, 202.5, 5,
                                               202.5, 247.5, 6,
                                               247.5, 292.5, 7,
                                               292.5, 337.5, 8,
                                               337.5, 360, 1), ncol = 3, byrow = TRUE)
                                            )
    
    
    
    aspect_df <- data.frame(matrix(ncol = 9, nrow = 1))
    names(aspect_df) <- 0:8
    aspect_df[1,] <- 0
            
  
  
    aspect_t <- table(extract(r_aspect, pts_30[i,])[,2])
    aspect_t <- prop.table(aspect_t) *100 # convert to percentage, comment this for keeping result as pixel counts
    aspect_df[names(aspect_t)] <- aspect_t
    
    asp_names <- paste0("t_aspect_", c("flat","N","NE","E","SE","S","SW","W","NW"))
    names(aspect_df) <- asp_names
    
    site_t[i, names(aspect_df)] <- ceiling(as.numeric(aspect_df) * 100) / 100
    
  
    pcl_krig_report[i, "t_krig_se_mean"] <- extract(dem_se, pts_30[i,], fun = mean, na.rm = TRUE)[2]
    pcl_krig_report[i, "t_pcl_dens"] <- las@header$`Number of point records` / st_area(pts_40[i,])
}


round_2_cols <- c("t_elev_mean", "t_elev_p01", "t_elev_p99", "t_slope_mean", "t_slope_p01", "t_slope_p99")

site_t[round_2_cols] <- lapply(site_t[round_2_cols], function(x) round(x, 2))

round_4_cols <- c("t_elev_sd","t_slope_sd", "t_hli_mean", "t_hli_p01", "t_hli_p99")

site_t[round_4_cols] <- lapply(site_t[round_4_cols], function(x) round(x, 4))

round_6_cols <- c("t_hli_sd")
site_t[round_6_cols] <- lapply(site_t[round_6_cols], function(x) round(x, 6))

round_10_cols <- c("t_vrml_mean", "t_vrml_sd", "t_vrml_p01", "t_vrml_p99")
site_t[round_10_cols] <- lapply(site_t[round_10_cols], function(x) round(x, 10))

dir.create("data/raw/processed", showWarnings = FALSE)

write.csv(site_t, "data/processed/site_t.csv", row.names = FALSE, na = "")
write.csv(pcl_krig_report, "data/processed/pcl_krig_report.csv", row.names = FALSE, na = "")

# report
min(pcl_krig_report$t_krig_se_mean,na.rm=TRUE)
max(pcl_krig_report$t_krig_se_mean,na.rm=TRUE)
mean(pcl_krig_report$t_krig_se_mean,na.rm=TRUE)
sd(pcl_krig_report$t_krig_se_mean,na.rm=TRUE)

min(pcl_krig_report$t_pcl_dens,na.rm=TRUE)
max(pcl_krig_report$t_pcl_dens,na.rm=TRUE)
mean(pcl_krig_report$t_pcl_dens,na.rm=TRUE)
sd(pcl_krig_report$t_pcl_dens,na.rm=TRUE)
