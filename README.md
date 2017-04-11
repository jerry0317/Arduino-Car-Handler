# Arduino Car Handler

*By Jerry Yan, April 2017*

## Hardware Look

![The hardware of the Arduino Car](https://github.com/jerry0317/Arduino-Car-Handler/blob/master/readme_resources/1.jpg)

## Software Look

![The interface of the macOS App of the Arduino Car Handler](https://github.com/jerry0317/Arduino-Car-Handler/blob/master/readme_resources/2.png)

## System Requirements

- macOS Sierra or later (10.12+)
- Bluetooth 2.1

## A Glance

### Connect with the Car

1. Pair the Arduino car with your Mac on Bluetooth.
2. Select your Bluetooth Serial Port on the "Port" in the menu bar.
3. Click "Connect", the status will change to "Connected" if it succeeds.

### Operate the Car

You can operate the car with any of the following ways:

#### I. Use the Keyboard

You can use the arrow keys on the keyboard to operate the car. When the key's down, the car starts to move; when the key's up, the car ceases to move.

#### II. Use the Buttons on the Window

Just click on "Forward," "Left," "Right," "Backward," or "Stop" to operate the car.

### Monitoring the Car

When the car is connected, the app will show the realtime distance in front of the car. The car also alerts when there's obstacle less than 25cm in front of it.

### Get the Trace of the Car (Realtime)

#### Auto Recording

- **Start:** When the car is connected, start the Auto Recording to get the realtime trace of the car.
- **Pause: ** The trace recording will be paused, and you may click the start button to restart it. The previous trace will not be erased.
- **Stop:**  The trace recording will be stopped, and you may click the start button to restart it. The previous trace **will be** erased.

#### Manual Input

Enter the JSON data like this, and then click the "try" button to stimulate the realtime trace recording.

```json
{"a_x":"0.27", "a_y":"0.12", "a_z":"-10.04", "USDistance":"228"}
{"a_x":"0.31", "a_y":"0.08", "a_z":"-10.08", "USDistance":"36"}
{"a_x":"0.16", "a_y":"0.12", "a_z":"-10.08", "USDistance":"37"}
{"a_x":"0.16", "a_y":"0.04", "a_z":"-10.04", "USDistance":"38"}
{"a_x":"0.24", "a_y":"0.16", "a_z":"-10.12", "USDistance":"36"}
{"a_x":"0.27", "a_y":"0.04", "a_z":"-10.08", "USDistance":"36"}
{"a_x":"0.31", "a_y":"0.16", "a_z":"-10.08", "USDistance":"35"}
{"a_x":"0.31", "a_y":"0.08", "a_z":"-10.08", "USDistance":"36"}
{"a_x":"0.24", "a_y":"0.12", "a_z":"-10.04", "USDistance":"40"}
```

- **a_x**: the instantaneous acceleration on the x-Axis (in $m/s^2$)
- **a_y**: the instantaneous acceleration on the y-Axis (in $m/s^2$)
- **a_z**: the instantaneous acceleration on the z-Axis (in $m/s^2$)
- **USDistance**: the ultra-sonic distance in front of the car (in $cm$)

#### Reset Button

You may reset the image area anytime using the reset button.

## Arduino Code

You can access the Arduino Code [here](https://github.com/jerry0317/Arduino-Car-Handler/blob/master/Bluetooth_Arduino_Motor_Code/Bluetooth_Arduino_Motor_Code.ino).

## Credit

[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

[ORSSerialPort](https://github.com/armadsen/ORSSerialPort)