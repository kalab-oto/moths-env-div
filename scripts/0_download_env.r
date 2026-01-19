library(xml2)
library(httr)
library(sf)

# DMR5G
polygon_to_sf <- function(coords_str) {
    if (is.na(coords_str)) return(st_sfc())
    
    coords <- as.numeric(unlist(strsplit(coords_str, " ")))
    mat <- matrix(coords, ncol = 2, byrow = TRUE)[, 2:1]
    st_polygon(list(mat))
}

atom_url <- "https://atom.cuzk.gov.cz/DMR5G-SJTSK/DMR5G-SJTSK.xml"

doc <- read_xml(atom_url)

m_ns <- xml_ns(doc)
m_entries <- xml_find_all(doc, ".//d1:entry", m_ns)

xml_links  <- xml_attr(xml_find_all(m_entries, "d1:link", m_ns), "href")
xml_links <- xml_links[grepl(".xml", xml_links)]

polygons  <- xml_text(xml_find_all(m_entries, "georss:polygon", m_ns))
titles <- xml_text(xml_find_all(m_entries, "d1:title", m_ns))

sf_polygons <- st_sfc(lapply(polygons, polygon_to_sf), crs = 4326)

entry_sf <- st_sf(
    title = titles,
    link = xml_links,
    geometry = sf_polygons
)

sites <- st_read("data/raw/sites.gpkg")

sites_4326 <- st_transform(sites, 4326)

sites_buffer <- st_buffer(sites, 40)
sites_buffer <- st_union(sites_buffer)
sites_buffer <- st_transform(sites_buffer, 4326)

map_lists <- entry_sf[sites_buffer,]

plot(map_lists$geometry)
plot(sites_buffer, add = TRUE)

get_zip_link <- function(link_url) {
    doc_i <- read_xml(link_url)
    ns_i <- xml_ns(doc_i)
    entry <- xml_find_all(doc_i, ".//d1:entry", ns_i)
    
    zip_link  <- xml_attr(xml_find_all(entry, "d1:link", ns_i), "href")

    return(zip_link)
}

links_zip <- lapply(map_lists$link, get_zip_link)
links_zip <- unlist(links_zip)

map_lists$link_zip <- links_zip

dir.create("data/processed", showWarnings = FALSE)

st_write(map_lists, "data/processed/DMR5G_map_list.gpkg", append = FALSE)

dir.create("data/raw/DMR5G", showWarnings = FALSE)

for (i in seq(links_zip)) {
    download.file(links_zip[i], file.path("data/raw","DMR5G", basename(links_zip[i])))  
    unzip(file.path("data/raw","DMR5G", basename(links_zip[i])), exdir = file.path("data/raw","DMR5G"))
    unlink(file.path("data/raw","DMR5G", basename(links_zip[i])))
}


# KVES 2021

# These datasets are publicly available under CC BY 4.0 llicence, but require login and dwonload to ISOP system of NCA CR. The registraion is free and can be done at https://idm.nature.cz/idm/#/egistration

# download  https://data.nature.cz/ds/101/download/kraj/KVES_Liberecky.zip
# to data/raw/KVES_Liberecky.zip

# download https://data.nature.cz/ds/101/download/kraj/KVES_Kralovehradecky.zip
# to data/raw/KVES_Kralovehradecky.zip
