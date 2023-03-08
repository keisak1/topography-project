
# AI4DRR_MOBILE_APP

## AI4DRR

This exploratory project proposes to develop a prototype platform that relies on artificial intelligence to automatically create exposure models suitable for risk assessment. The platform will rely on OSM to identify the footprint of each asset. Then, for each asset, the Google Street View API will be used to collect images from different angles, and a Deep Learning algorithm will be employed to estimate the most likely structural attributes. To train this algorithm, we will develop a database with photography of existing buildings with known structural attributes. 

Finally, the building footprint from OSM, the estimated structural parameters and building height from the satellite imagery will be combined using an Artificial Neural Network to create the digital representation of each asset. This prototype platform will be tested a parish in Lisbon, where ground proof data is available to evaluate the accuracy of the platform. Such results could enable the classification of the built environment for large regions, thus enabling risk assessment studies for a wide variety of hazards. 

## Mobile App

This mobile app is meant to aid the project AI4DRR by sending data (forms and images) with user input to feed the AI.

## To-do list

- [x] Authentication
- [x] Localization
- [x] Homepage (Map)
  - [x] Highlighted areas shown/hidden on Zoom
  - [x] Highlighted markers shown/hidden on Zoom
  - [x] Clickable Markers
  - [x] GPS
    - [x] Rotation
    - [x] Smoothen the animation
- [ ] Offline Map
  - [ ] Map predownloaded to Cache
  - [ ] Markers presaved to Cache
- [ ] API Integration
- [ ] Multiplatform
- [ ] User Roles
- [ ] Save data locally
- [ ] Classify objects


This project has the support from the Humanitarian OpenStreetMap Team and the SimCenter AI group of California.
