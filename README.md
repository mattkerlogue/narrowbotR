# narrowbotR 

[![GitHub](https://img.shields.io/github/license/mattkerlogue/narrowbotr)](https://github.com/mattkerlogue/narrowbotR/blob/main/LICENSE) [![Repo Status: work in progress](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip) [![lapsedgeographer blog post](https://img.shields.io/badge/lapsedgeographer-post-78e2a0?labelColor=1f222a&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAw0lEQVR4Ae3VAQTCQBiG4WEIASDAMECAASBgGAIEgBBCgAGGABCGABBCgCFACCEMQ4BDAAghDOtF4G+pzZ9ie3mAu/sAZzWjoihszJEhQaA9MIVspjmQQZZqDlwh22sOrCAbaQ50EcLgggXsOg8ZHLDBGL0P7rgIkeAE8/pweWu4JWcH2OGpagNEOSLY6GAJWb0B0RZHkP6ArB1oB3404KCPIWKc8S6DGAE8OFaVHmMpZCl8zS8zQo4bJt/6m3141j91B9VY1sFu/yC6AAAAAElFTkSuQmCC)](https://lapsedgeographer.london/2020-10/virtual-gongoozling/)

[narrowbotR](https://botsin.space/@narrowbotr) (pronounced "narrow-boater") is a Mastodon bot written in R that publishes information about the UK canal network. This bot is inspired by [Matt Dray](https://github.com/matt-dray/)'s [londonmapbot](https://github.com/matt-dray/londonmapbot) which randomly posts a location in the rough vicinity of London every 30 minutes. This bot seeks to do something similar: posting a random location on the UK canal network at a regular interval. It is a work in progress. At present it only publishes information about the English and Welsh canal network.

The bot also used to run on [Twitter](https://twitter.com/narrowbotR), but as of 15 April 2023 I have decommissioned the Twitter bot due to changes in Twitter's Terms of Service.

The bot works as follows:

* The data from [Canal and River Trust's open data](http://data-canalrivertrust.opendata.arcgis.com) feeds has been downloaded and aggregated into a single file, only the point-based data at this stage, let's call each item in this data a "feature"
* A feature at random will be selected from the dataset
* A search of publicly available photos on Flickr, licensed for sharing, in the vicinity of the feature's position is made
* The photo metadata is scored and the top-scoring photo selected
* If there are only a small number of photos returned then an aerial photo of the location sourced from Mapbox will be used
* A post is constructed to provide the feature's name, the feature's type, an open-street map link to the location, and citation of the author a link to the Flickr page of the photo if a Flickr photo is being used.
* If the flickr photo has tags then these are re-used to add to the standard hashtags included in the post
* The tweet is then posted using a custom version of the `rtoot::post_toot()` function that has been extended to embed location data in the tweet's metadata.
* The feature dataset is created only occasionally and stored in `data/all_points.RDS` for efficiency

You can read a more detailed explanation of how the bot works in this [blog post](https://lapsedgeographer.london/2020-10/virtual-gongoozling/).

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
