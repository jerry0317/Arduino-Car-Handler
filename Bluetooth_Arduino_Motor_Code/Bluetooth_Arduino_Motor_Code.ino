#include <Wire.h>

#include <ADXL345.h>

#include <SR04.h>

ADXL345 accelerometer;

void showRange(void)
{
  Serial.print("Selected measurement range: "); 

  switch(accelerometer.getRange())
  {
    case ADXL345_RANGE_16G: Serial.println("+/- 16 g"); break;
    case ADXL345_RANGE_8G:  Serial.println("+/- 8 g");  break;
    case ADXL345_RANGE_4G:  Serial.println("+/- 4 g");  break;
    case ADXL345_RANGE_2G:  Serial.println("+/- 2 g");  break;
    default: Serial.println("Bad range"); break;
  }
}

void showDataRate(void)
{
  Serial.print("Selected data rate: "); 

  switch(accelerometer.getDataRate())
  {
    case ADXL345_DATARATE_3200HZ: Serial.println("3200 Hz"); break;
    case ADXL345_DATARATE_1600HZ: Serial.println("1600 Hz"); break;
    case ADXL345_DATARATE_800HZ:  Serial.println("800 Hz");  break;
    case ADXL345_DATARATE_400HZ:  Serial.println("400 Hz");  break;
    case ADXL345_DATARATE_200HZ:  Serial.println("200 Hz");  break;
    case ADXL345_DATARATE_100HZ:  Serial.println("100 Hz");  break;
    case ADXL345_DATARATE_50HZ:   Serial.println("50 Hz");   break;
    case ADXL345_DATARATE_25HZ:   Serial.println("25 Hz");   break;
    case ADXL345_DATARATE_12_5HZ: Serial.println("12.5 Hz"); break;
    case ADXL345_DATARATE_6_25HZ: Serial.println("6.25 Hz"); break;
    case ADXL345_DATARATE_3_13HZ: Serial.println("3.13 Hz"); break;
    case ADXL345_DATARATE_1_56HZ: Serial.println("1.56 Hz"); break;
    case ADXL345_DATARATE_0_78HZ: Serial.println("0.78 Hz"); break;
    case ADXL345_DATARATE_0_39HZ: Serial.println("0.39 Hz"); break;
    case ADXL345_DATARATE_0_20HZ: Serial.println("0.20 Hz"); break;
    case ADXL345_DATARATE_0_10HZ: Serial.println("0.10 Hz"); break;
    default: Serial.println("Bad data rate"); break;
  }
}


#define TRIG_PIN 2
#define ECHO_PIN 3
SR04 sr04 = SR04(ECHO_PIN,TRIG_PIN);
long a;
int izqA = 5; 
int izqB = 6; 
int derA = 9; 
int derB = 10; 
int vel = 255; // Velocidad de los motores (0-255)
int estado = 'g'; // inicia detenido

void setup(void) { 
Serial.begin(9600);

  // Initialize ADXL345
  Serial.println("Initialize ADXL345");
  if (!accelerometer.begin())
  {
    Serial.println("Could not find a valid ADXL345 sensor, check wiring!");
    delay(500);
  }

  // Set measurement range
  // +/-  2G: ADXL345_RANGE_2G
  // +/-  4G: ADXL345_RANGE_4G
  // +/-  8G: ADXL345_RANGE_8G
  // +/- 16G: ADXL345_RANGE_16G
  accelerometer.setRange(ADXL345_RANGE_16G);

  // Show current setting
  showRange();
  showDataRate();

  
Serial.println("Example written by Coloz From Arduino.CN");
delay(1000);

Serial.begin(9600); // inicia el puerto serial para comunicacion con el Bluetooth
pinMode(derA, OUTPUT);
pinMode(derB, OUTPUT);
pinMode(izqA, OUTPUT);
pinMode(izqB, OUTPUT);
} 

void loop(void) { 

  
  // Read normalized values
  Vector raw = accelerometer.readRaw();

  // Read normalized values
  Vector norm = accelerometer.readNormalize();

  // Output raw
  /*Serial.print(" Xraw = ");
  Serial.print(raw.XAxis); 
  Serial.print(" Yraw = ");
  Serial.print(raw.YAxis);
  Serial.print(" Zraw: ");
  Serial.print(raw.ZAxis); */

  // Output normalized m/s^2
  /*Serial.print(" Xnorm = ");
  Serial.print(norm.XAxis);
  Serial.print(" Ynorm = ");
  Serial.print(norm.YAxis);
  Serial.print(" Znorm = ");
  Serial.print(norm.ZAxis);*/

a=sr04.Distance();
  Serial.print("{\"a_x\":\"");
  Serial.print(norm.XAxis);
  Serial.print("\", \"a_y\":\"");
  Serial.print(norm.YAxis);
  Serial.print("\", \"a_z\":\"");
  Serial.print(norm.ZAxis);
  Serial.print(", \"USDistance\":\"");
  Serial.print(a);
  Serial.print("\"}");

  Serial.println();
  
  delay(100);

//Serial.print(a);
//Serial.println("cm");
//delay(1000);

if(Serial.available()>0){ // lee el bluetooth y almacena en estado
estado = Serial.read();
}
if(estado=='a'){ // Forward
  //Serial.println(estado);
analogWrite(derB, 0); 
analogWrite(izqB, 0); 
analogWrite(derA, vel); 
analogWrite(izqA, vel); 
}
if(estado=='d'){ // right
    //Serial.println(estado);
analogWrite(derB, vel); 
analogWrite(izqB, 0); 
analogWrite(derA, 0); 
analogWrite(izqA, vel); 
}
if(estado=='c'){ // Stop
    //Serial.println(estado);
analogWrite(derB, 0); 
analogWrite(izqB, 0); 
analogWrite(derA, 0); 
analogWrite(izqA, 0); 
}
if(estado=='b'){ // left
    //Serial.println(estado);
analogWrite(derB, 0); 
analogWrite(izqB, vel);
analogWrite(izqA, 0);
analogWrite(derA, vel); 
} 

if(estado=='e'){ // Reverse
   // Serial.println(estado);
analogWrite(derA, 0); 
analogWrite(izqA, 0);
analogWrite(derB, vel); 
analogWrite(izqB, vel); 
}
if (estado =='f'){ // Boton ON se mueve sensando distancia 
digitalWrite(11, HIGH);
}
if (estado=='g'){ // Boton OFF, detiene los motores no hace nada 
}
}


