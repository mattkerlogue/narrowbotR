# narrowbotR

A twitter bot that publishes information about the UK canal network. This bot is inspired by [Matt Dray](https://github.com/matt-dray/)'s [londonmapbot](https://github.com/matt-dray/londonmapbot) which randomly tweets a location in the rough vicinity of London every 30 minutes. This bot seeks to do something similar: tweeting a random location on the UK canal network every 30 minutes.

To do:

-   [x] Create twitter account
-   [x] Get twitter developer credentials
-   [x] Investigate [CRT open data](http://data-canalrivertrust.opendata.arcgis.com)
-   [x] Write database build functions
-   [ ] Write database maintenance functions
-   [x] Build database of CRT data
-   [x] Investigate Flickr API for geotagged photos
-   [ ] Write tweet functions
-   [ ] Write GitHub automation

### Notes

CRT open data has several .geoJSON files covering the various features on the CRT network. Suggest downloading a set and building a unified database from these that can then be randomly sampled.

Write a maintenance function to check for updates and re-build database as/when.

Write a log file to record all the features tweeted about - can then be mapped.

~~Londonmapbot provides aerial photo and open street map link ... what is best for canals? Investigate if the Flickr API can be used to get photos near the feature (perhaps require feature type/name in metadata)?~~

Functions to search Flickr API written, photos before sunrise and after sunset removed - need to develop a selection algorithm: (i) completely random, (ii) random selection from "golden hour" photos, (iii) score photos based on golden hour and length of title/description, (iv) prefer recent photos??
