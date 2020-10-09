# narrowbotR [WIP]

[narrowbotR](https://twitter.com/narrowbotR) (pronounced "narrow-boater") is a Twitter bot written in R that publishes information about the UK canal network. This bot is inspired by [Matt Dray](https://github.com/matt-dray/)'s [londonmapbot](https://github.com/matt-dray/londonmapbot) which randomly tweets a location in the rough vicinity of London every 30 minutes. This bot seeks to do something similar: tweeting a random location on the UK canal network at a regular interval. It is a work in progress. At present it only publishes information about the English and Welsh canal network.

The bot works as follows:

* The data from [Canal and River Trust's open data](http://data-canalrivertrust.opendata.arcgis.com) feeds has been downloaded and aggregated into a single file, only the point-based data at this stage, let's call each item in this data a "feature"
* A feature at random will be selected from the dataset
* A search of publicly available photos on Flickr, licensed for sharing, in the vicinity of the feature's position is made
* The photo metadata is scored and the top-scoring photo selected
* If there are only a small number of photos returned then an aerial photo of the location sourced from Mapbox will be used
* A tweet is constructed to provide the feature's name, the feature's type, an open-street map link to the location, and citation of the author a link to the Flickr page of the photo if a Flickr photo is being used.
* The tweet is then posted using a custom version of the `rtweet::post_tweet()` function that has been extended to embed location data in the tweet's metadata.
* The feature dataset is created only occasionally and stored in `data/all_points.RDS` for efficiency

---

### Dev notes

To do:

-   [x] Create twitter account
-   [x] Get twitter developer credentials
-   [x] Investigate [CRT open data](http://data-canalrivertrust.opendata.arcgis.com)
-   [x] Write database build functions
-   [ ] Write database maintenance functions
-   [x] Build database of CRT data
-   [x] Investigate Flickr API for geotagged photos
-   [x] Write tweet functions
-   [x] Write GitHub automation
-   [ ] Future: investigate data for Scottish/Irish canals

Need to decide on a maintenance schedule for updating the database

For testing purposes use the following lat/long pairs (these are popular features that should have nearby photos):

* `list(long = -2.03219634864333, lat = 51.3520732144106)`: Lock 29, Devizes Lock (bottom of Caen Hill flight)
* `list(long = -1.18474539433226, lat = 52.2845877855651)`: Braunston Tunnel West Portal
* `list(long = -3.08780897790795, lat = 52.9704074998854)`: Pontcysyllte aqueduct
