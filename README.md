# RedRacingRoadster
WiFi RC Car controller via a RESTful service that runs on a ESP8266 directly on the car.

## Car construction
This controller is meant to be used in a cheap toy RC car, overclocked and pimped. The modifications of the RC car come down to this:
1. Disassemble the toy car
2. Remove the original circuit board and wiring, if the car came with a rechargeable battery, keep it.
3. Install the software into the ESP8266
4. Buy a cheap dual H-Bridge from eBay or BYO, and install it to each motor, connect it to the ESP8266.
4. Boot up and enjoy

__Default pinout:__

|Pin|Action|
|:---:|:---|
|2| steering right|
|3| steering left|
|5| accelerate forward|
|6| accelerate backward|

## Usage
The simplest way to use the car is to connect to its AP and use the web page. Another way is to consume the API from your custom software.


## API
Parameters are sent to the API methods in the request body, as a json containing the required parameters

### /move [PUT | POST]

Moves the car in the indicated direction with the indicated intensity in the acceleration and steering.

#### Parameters
|Name|Minimum | Maximum|
|---|:---:|:---:|
|acceleration|-128|127|
|steering|-128|127|

#### Example
A request containing these parameters would slowly accelerate while steering left in a circle.
```json
{
  "acceleration":30,
  "steering": -200
}
```


## TODO:
- [*] Write better docs
- [*] Create a more flexible web server
- [*] Migrate to a proper Json-POST based RESTful service
- [*] Support better control for both axis
- [ ] Document the http server and give it away
- [ ] Add touch controls to the website for use in smarthpones
- [ ] Get more resilient (aka, test with a monkey)
- [ ] Support some network discovery
- [ ] configuration via a smartphone, and maybe a mic
- [ ] add some sort of auth
