/* a ouvrir dans processing 2.0.3 */


import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;  
AudioInput in;
AudioInput in2;
FFT fftLin;
FFT fftLog;

float height3;
float height23;
float spectrumScale = .1;

int bufferSizeSmall=512;
int fftRatio=16; // how many times bigger is the big buffer for detailed analisis
int bufferSizeBig=bufferSizeSmall*fftRatio;

PImage frame;

import processing.pdf.*;

PFont font;

boolean gorecord = false;

void setup()
{
  size(512, 480);
  height3 = height/3;
  height23 = 2*height/3;

  minim = new Minim(this);

  in = minim.getLineIn(Minim.STEREO, bufferSizeBig);  
  fftLin = new FFT(in.bufferSize(), in.sampleRate());
  
  // calculate the averages by grouping frequency bands linearly. use 30 averages.
  fftLin.linAverages( 30 );
  
  // create an FFT object for calculating logarithmically spaced averages
  fftLog = new FFT( in.bufferSize(), in.sampleRate() );
  
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fftLog.logAverages( 22, 3 );

  strokeJoin(BEVEL);  
  rectMode(CORNERS);
  font = createFont("Georgia", 32);
  background(241);
  frameRate(30);
  stroke(255);
  noFill();
  smooth();
  
  frame = get();
}

void draw()
{

  nextFrame();
  
  spectrumScale = 3.4;  
  
  textFont(font);
  textSize( 18 );
 
  float centerFrequency = 0;
  
  // perform a forward FFT on the samples in jingle's mix buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.left or jingle.right
  fftLin.forward(in.mix);
  fftLog.forward(in.mix);
  
  if (gorecord) {
    beginRecord(PDF, "trace.pdf");
  }
  
  // draw the logarithmic averages
  {
    // since logarithmically spaced averages are not equally spaced
    // we can't precompute the width for all averages
    
    stroke(0,110);
    strokeWeight(1);
    noFill();
    
    translate(80, 0);
    
         

    stroke(50);
         
            
    for (int j = 0; j < 2; j++) {
 
      stroke( j * 50);
      beginShape();
  
      vertex( 0, height/2 );
  
      float fftLogPrecedent = 0;
      
      for(int i = 0; i < 16; i++)
      {
        centerFrequency = fftLog.getAverageCenterFrequency(i);
        // how wide is this average in Hz?
        float averageWidth = fftLog.getAverageBandWidth(i);   
        
        // we calculate the lowest and highest frequencies
        // contained in this average using the center frequency
        // and bandwidth of this average.
        float lowFreq  = centerFrequency - averageWidth/2;
        float highFreq = centerFrequency + averageWidth/2;
        
        // freqToIndex converts a frequency in Hz to a spectrum band index
        // that can be passed to getBand. in this case, we simply use the 
        // index as coordinates for the rectangle we draw to represent
        // the average.
        int xl = (int)fftLog.freqToIndex(lowFreq);
        int xr = (int)fftLog.freqToIndex(highFreq);
     
        // draw a rectangle for each average, multiply the value by spectrumScale so we can see it better
          vertex( xr*2, height/2 + fftLog.getAvg(i)*spectrumScale );
        
        fftLogPrecedent = fftLog.getAvg(i);
        //rect( xl, height, xr, height - fftLog.getAvg(i)*spectrumScale );
   
      }
  
      vertex( 362, height/2 );
      endShape(CLOSE);
    }
    
  }
  
  if (gorecord) {
    endRecord();
    gorecord = false;
   
  }
    
}

void mouseReleased() {
   gorecord = true; 
}

void nextFrame() {

  pushMatrix();
  tint(255, 250);
  image(frame, width/2, height/2);
  popMatrix();
  frame = get();
  
}
