/* a ouvrir dans processing 2.0.3 */


import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.*;

Minim minim;  
AudioInput in;
AudioInput in2;
FFT fftLin;
FFT fftLog;

float spectrumScale = 100;

int bufferSizeSmall=512;
int fftRatio=16; // how many times bigger is the big buffer for detailed analisis
int bufferSizeBig=bufferSizeSmall*fftRatio;

PImage frame;

import processing.pdf.*;
import peasy.*;

PeasyCam cam;

boolean gorecord = false;

int n = 80;
int m = 16;
float[][] xr = new float[n][m]; 
float[][] getAvg = new float[n][m];

int largeurMotif = 300;

void setup()
{
  size(1200, 800, P3D);

  cam = new PeasyCam(this, -largeurMotif);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(350);

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
  background(241);
  stroke(255);
  noFill();

  frameRate(60);
    
  for(int j=n-1; j>0; j--){
    for(int i = 0; i < m; i++) {
      xr[j][i] = 0;
      getAvg[j][i] = 0; 
    }
  }

}

void draw()
{

  background(255);
  
  //nextFrame();
  
  spectrumScale = 5;  
     
  // perform a forward FFT on the samples in jingle's mix buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.left or jingle.right
  fftLin.forward(in.mix);
  fftLog.forward(in.mix);
  
  // draw the logarithmic averages
  {
    // since logarithmically spaced averages are not equally spaced
    // we can't precompute the width for all averages
    
    noStroke();
    noFill();
    
    translate(0, 0);
    
    stroke(50);
 
    if ( fftLog.getAvg(0) != getAvg[0][0] ) {
        
      for(int j=n-1; j>0; j--){
        for(int i = 0; i < m; i++) {
          xr[j][i] = xr[j-1][i];
          getAvg[j][i] = getAvg[j-1][i]; 
        }
      }
      
      for(int i = 0; i < m; i++) {
    
        float centerFrequency = fftLog.getAverageCenterFrequency(i);
        float averageWidth = fftLog.getAverageBandWidth(i);
        
        float lowFreq  = centerFrequency - averageWidth/2;
        float highFreq = centerFrequency + averageWidth/2;
                 
        xr[0][i] = (float)fftLog.freqToIndex(highFreq);
        
        getAvg[0][i] = ( 9*getAvg[1][i] + 1*fftLog.getAvg(i) )  / 10;
        
      }
   
      for(int j=0; j<n; j++){      
        for(int i = 0; i < m; i++) {
          //print( "getAvg[" + j + "]" + "[" + i + "]" + getAvg[j][i] );
        }
      } 
                
    } else {
       println("none"); 
    }

    goDraw();

  }
  
  if (keyPressed) {
    if ( key == 'p' ) {
      saveFrame("output/frames####.png");
    }
  }

   
}

void keyPressed() {
     
  if (key == 's' || key == 'S') {
    Date d = new Date();
    long current=d.getTime()/1000;
  
    PGraphics pdf = createGraphics(largeurMotif + 20, 3000, PDF, "output-" + current + ".pdf");
    pdf.beginDraw();
    
    pdf.translate(10,10);
    
    for(int j=0; j<n; j+=5){      
       
      pdf.beginShape();
      pdf.vertex( 0, 0);
       
      for(int i = 0; i < m; i++)
      {
        pdf.vertex( xr[j][i], getAvg[j][i] * spectrumScale);
      }
      
      pdf.vertex( largeurMotif, 0);
      pdf.endShape(CLOSE);
      pdf.translate(0,160);
  
    }
     
    pdf.dispose();
    pdf.endDraw();
    
  }
}

void nextFrame() {

  pushMatrix();
  tint(255, 250);
  image(frame, width/2, height/2);
  popMatrix();
  frame = get();
  
}

void goDraw() {
  
  pushMatrix();
  translate(0, 0, 0);
  
   for(int j=0; j<n; j++){      

    noFill();
    fill( 0, 0, 0, map(j, 0,n,0,255) );
    beginShape();
    vertex( 0, 0, 0 );
 
    // on supprime la dernière valeur
    for(int i = 0; i < m-1; i++)
    {           
      int xpos = (int)((largeurMotif * xr[j][i]) / xr[j][m-1]);
      
      //float xpos = map(xr[j][i], 0, xr[j][m-1], 0, largeurMotif);
      vertex( xpos, getAvg[j][i] * spectrumScale, 0);
    }
    
    // et on lui met ,0,0 just because
    vertex( largeurMotif, 0, 0);

    translate(0,0,-1);
    
    endShape(CLOSE);

  }
 
 popMatrix();
}
