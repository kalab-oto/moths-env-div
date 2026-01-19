library(terra)

sites <- vect("data/raw/sites.gpkg")
sites <- project(sites, "epsg:4326")

lon_lat <- as.data.frame(crds(sites))
lon_lat <- round(lon_lat, 5)

names(lon_lat) <- c("lon", "lat")
df_sites <- as.data.frame(sites)
df_sites <- cbind(df_sites, lon_lat)

df_sites <- df_sites[, c("site_id", "lon", "lat","type", "v_min", "v_max", "v_mean", "v_sparse", "v_n_avail", "v_n_div", "m_no", "m_mow", "m_sheep", "m_cattle", "m_horse")]

es <- read.csv("data/processed/sites_es.csv")
t <- read.csv("data/processed/site_t.csv")

sites_env <- merge(df_sites, t, by = "site_id")
sites_env <- merge(sites_env, es, by = "site_id")

dir.create("outputs", showWarnings = FALSE)

write.csv(sites_env, "outputs/sites_env.csv", row.names = FALSE, na = "")
