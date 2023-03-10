
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
  - [x] Map predownloaded to Cache
  - [ ] Markers presaved to Cache
- [ ] API Integration
- [ ] Multiplatform
- [ ] Classify objects
  - [ ] Saving that classification locally in case there's no internet connection.

## Packages
  ### Localization
  We used the flutter_localizations package to create a multi-language App
  
    flutter_localizations:
      sdk: flutter
  
  ### Map
  Since updating the user marker in the map every millisecond would require a lot of computational power and would be threatning to the app's performance,
  we opted to use a packaage that smoothens the animation between the new Marker position and the old Marker position, giving it a sense of movement
  
      flutter_map_animated_marker: ^1.0.1

  ### Offline Map
  
  ### API Integration
  For the API side of the app we used the HTTP package to send requests such as the log in and the classification of the objects through the forms. Our forms are also   dynamically generated because of the GET requests we make to the API.
  
      http: 0.13.5
  
This project has the support from the Humanitarian OpenStreetMap Team and the SimCenter AI group of California.
