context("Test st_crs2")

# convenience function to compare non-null CRSs
# without using EPSG (so usable with rgdal >= 1.5)
expect_equal_crs <- function(crs1, crs2) {
  ref_vec <- st_geometry(st_read(
    system.file("extdata/vector/barbellino.geojson", package = "sen2r"), 
    quiet = TRUE
  ))
  testthat::expect_equal(
    as.integer(sf::st_coordinates(sf::st_transform(ref_vec, crs1))[,c("X","Y")]),
    as.integer(sf::st_coordinates(sf::st_transform(ref_vec, crs2))[,c("X","Y")])
  )
}


testthat::test_that(
  "st_crs2, input EPSG", {
    expect_equal_crs(st_crs2(9), 32609)
    expect_equal_crs(st_crs2("EPSG:32609"), 32609)
    expect_equal_crs(st_crs2("9N"), 32609)
    expect_equal_crs(st_crs2("9S"), 32709)
  }
)

testthat::test_that(
  "st_crs2, input raster file [path]", {
    raster_path <- system.file(
      "extdata/out/S2A2A_20190723_022_Barbellino_BOA_10.tif", 
      package="sen2r"
    )
    expect_equal_crs(st_crs2(raster_path), 32632)
    # This test was skipped while stars is being incompatible with sf >= 0.9,
    # and will be restored after stars will have been fixed (#295).
    if (packageVersion("sf") < 0.9) {
      expect_equal_crs(st_crs2(stars::read_stars(raster_path)), 32632)
    }
    # This test was skipped while raster is reading PROJ.4 instead than WKT,
    # and so the EPSG is being lost (#295).
    # testthat::expect_equal(st_crs2(raster::raster(raster_path))$epsg, 32632)
  }
)

testthat::test_that(
  "st_crs2, input vector file [path]", {
    raster_path <- system.file(
      "extdata/out/S2A2A_20190723_022_Barbellino_BOA_10.tif", 
      package="sen2r"
    )
    vector_path <- system.file(
      "extdata/vector/barbellino.geojson", 
      package="sen2r"
    )
    # 
    if (packageVersion("sf") < 0.9) {
      expect_equal_crs(st_crs2(raster_path), 32632)
      expect_equal_crs(st_crs2(stars::read_stars(raster_path)), 32632)
    }
    # testthat::expect_equal(st_crs2(raster::raster(raster_path))$epsg, 32632)
    expect_equal_crs(st_crs2(vector_path), 32632)
    expect_equal_crs(st_crs2(sf::read_sf(vector_path)), 32632)
    expect_equal_crs(st_crs2(as(sf::read_sf(vector_path), "Spatial")), 32632)
  }
)

testthat::test_that(
  "st_crs2, generics and errors", {
    testthat::expect_error(st_crs2("wrong"), "invalid crs\\: wrong")
    testthat::expect_equal(st_crs2(NULL), sf::st_crs(NA))
    testthat::expect_equal(st_crs2(NA), sf::st_crs(NA))
    testthat::expect_equal(st_crs2(), sf::st_crs(NA))
  }
)


testthat::skip_on_cran()
testthat::skip_on_travis()

testthat::test_that(
  "st_crs2, input WKT", {
    wkt_32n <- st_as_text_2(st_crs(32609))
    writeLines(wkt_32n, wkt_32n_path <- tempfile())
    expect_equal_crs(st_crs2(wkt_32n), 32609)
    expect_equal_crs(st_crs2(wkt_32n_path), 32609)
  }
)

testthat::test_that(
  "st_crs2, input PROJ.4", {
    expect_equal_crs(st_crs2("+init=epsg:32609"), 32609)
    gdal_version <- package_version(gsub(
      "^.*GDAL ([0-9\\.]+)[^0-9].*$", "\\1",
      system(paste0(load_binpaths("gdal")$gdalinfo," --version"), intern = TRUE)
    )) # checking GDAL >=3 instead than PROJ >= 6 for simplicity
    if (any(gdal_version >= 3, packageVersion("sf") >= 0.9)) {
      testthat::expect_warning(
        st_crs2("+proj=utm +zone=9 +datum=WGS84 +units=m +no_defs"),
        "Using PROJ\\.4 strings is deprecated with"
      )
    } else {
      expect_equal_crs(
        st_crs2("+proj=utm +zone=9 +datum=WGS84 +units=m +no_defs"),
        32609
      )
    }
  }
)
