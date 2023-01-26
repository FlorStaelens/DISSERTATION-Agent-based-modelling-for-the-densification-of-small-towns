
//  DISSERTATION - Agent-based modelling for the densification of small towns                                  |
//  Flor Staelens, 2022-2023                                                                                   |
//                                                                                                             |
//  Simulation model for the built volume of a small town, published 05/01/2023                                |
//                                                                                                             |
//  Ctrl + R to run                                                                                            |
//                                                                                                             |
//                                                                                                             |
//  CONTROLS:   MOUSE   left    :   select functions                                                           |
//                      middle  :   camera pan / zoom                                                          |
//                      right   :   simulate                                                                   |
//                                                                                                             |
//                                                                                                             |
//_____________________________________________________________________________________________________________|


//__________________________________________declarations________________________________________//


//camera
import peasy.*;
PeasyCam cam;
PeasyDragHandler handler;
float scale=1;
float xPan=500, yPan=500;
boolean zoomIn = false, zoomOut= false, panUp= false, panDown = false, panLeft= false, panRight= false;
float panSpeed = 50, zoomSpeed = 2;

//setup
Perceel[] percelen;
boolean decision = false, simsChosen = false;
String municipality;
int NumberOfSimulations = 1;

//simulation metrics
int aantalPercelen =0, simulationsDone = 0;
int APVG = 0, APVK = 0;
double volVergrootTotaal = 0, volVerkleindTotaal = 0;

//interface
PFont myFont;
String displayText = "";
color coloru = 230, colorh = 230, colori = 230, coloro = 230, colorP = 230, colorv = 230, colore = 230, colorExit = 255;
color colorText = color(0);
boolean blokken = false, info = false;


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////___________________SETUP____________________////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

void setup() {
  myFont = createFont("Laksaman Bold", 100, true);
  textFont(myFont);

  //__________________________________________defining camera________________________________________//

  fullScreen(P3D);
  cam = new PeasyCam(this, 750);
  cam.setMinimumDistance(2);
  cam.setMaximumDistance(1000);
  cam.setSuppressRollRotationMode();
  cam.setLeftDragHandler(handler);
  cam.lookAt(500, 500, 0);
  float fov = PI/3;
  float cameraZ = (height/2)/ tan(fov/2);
  perspective(fov, float(width)/float(height), 1, cameraZ*10);

  //________________________________________setting up decision______________________________________//

  //translate(-width/2, -height/2, 0);
  background(255);
  cam.beginHUD();
  stroke(0);
  strokeWeight(3);
  textSize(100);
  fill(230);
  rectMode(CENTER);
  rect(1*width/4, height/2, 600, 300);
  rect(3*width/4, height/2, 600, 300);
  fill(0);
  textAlign(CENTER, CENTER);
  text("Zele", 1*width/4, height/2);
  text("Eeklo", 3*width/4, height/2);
  text("choose municipality to load", width/2, 1*height/5);
  textSize(50);
  text("[changing municipality later will require restarting]", width/2, 2*height/7);
  cam.endHUD();
}




//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////___________________DECISION____________________//////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
void mousePressed() {
  if (mouseButton == LEFT) {
    if (decision == false) {
      //_____________________________________________ decision ___________________________________________//
      //rect(3*width/8, height/2, 300, 150);
      if ( (mouseX > (1*width/4)-300 && mouseX < (1*width/4) + 300 && mouseY > (height/2)-150 && mouseY < (height/2)+150)||(mouseX > (3*width/4) - 300 && mouseX < (3*width/4) + 300 && mouseY > (height/2)-150 && mouseY < (height/2)+150)) {
        if (mouseX > (1*width/4)-300 && mouseX < (1*width/4) + 300 && mouseY > (height/2)-150 && mouseY < (height/2)+150) municipality = "Zele";
        if (mouseX > (3*width/4)-300 && mouseX < (3*width/4) + 300 && mouseY > (height/2)-150 && mouseY < (height/2)+150) municipality = "Eeklo";

        cam.beginHUD();
        background(255);
        text("LOADING...", width/2, height/2);
        cam.endHUD();
        redraw();
        String eigFile = municipality + " 2004R eig.csv";
        String geoFile = municipality + " 2004R geo.csv";

        //____________________________________________loading data__________________________________________//
        println("1/3 loading data");
        Table geo = loadTable(geoFile, "header");
        Table eig = loadTable(eigFile, "header");
        aantalPercelen = eig.getRowCount();
        percelen = new Perceel[aantalPercelen];
        for (int i=0; i<aantalPercelen; i++) {
          if (municipality == "Eeklo") {
            Perceel perceel = new Perceel(eig.getInt(i, "shapeid"), eig.getFloat(i, "oppPerceel"),
              eig.getFloat(i, "hoogte"),
              eig.getFloat(i, "oppBebouwd"), eig.getFloat(i, "Mobiscore"),
              eig.getString(i, "woonvernie"), eig.getString(i, "woongebied"),
              eig.getString(i, "landbouw"), eig.getString (i, "industrie"),
              eig.getString(i, "woonuitbre"), eig.getInt(i, "zoneId"),
              eig.getString(i, "zone"), eig.getFloat(i, "X"), eig.getFloat(i, "Y"), municipality);
            percelen[i] = perceel;
          } else {
            Perceel perceel = new Perceel(eig.getInt(i, "shapeid"), eig.getFloat(i, "oppPerceel"),
              eig.getFloat(i, "hoogte"),
              eig.getFloat(i, "oppBebouwd"), eig.getFloat(i, "Mobiscore"),
              eig.getString(i, "woonvernieuwingsgebied"), eig.getString(i, "woongebied"),
              eig.getString(i, "landbouw"), eig.getString (i, "industrie"),
              eig.getString(i, "woonuitbreidingsgebied"), eig.getInt(i, "zoneId"),
              eig.getString(i, "zone"), eig.getFloat(i, "X"), eig.getFloat(i, "Y"), municipality);
            percelen[i] = perceel;
          }
        }

        for (int j=0; j<geo.getRowCount(); j++) {
          percelen[geo.getInt(j, "shapeid")].geoData(geo.getFloat(j, "x"), geo.getFloat(j, "y"), j, municipality);
        }

        for (Perceel perceel : percelen) {
          perceel.vorm();
          perceel.blok();
        }


        //__________________________________________defining neighbourhoods________________________________________//

        println("2/3 defining neighbourhoods");
        for (Perceel perceel : percelen) {
          for (Perceel perceelVergelijk : percelen) {
            float d = dist(perceel.zwaartepunt.x, perceel.zwaartepunt.y, perceelVergelijk.zwaartepunt.x, perceelVergelijk.zwaartepunt.y);
            if (perceel!=perceelVergelijk && d<perceel.straal && perceel.categorie == perceelVergelijk.categorie && (perceelVergelijk.oppPerceel < 3* perceel.oppPerceel && perceelVergelijk.oppPerceel > perceel.oppPerceel / 3)) {
              perceel.addToOmgeving(perceelVergelijk.shapeid);
            }
          }
        }

        //________________________________________    update probabilities    ______________________________________//
        println("3/3 calculating update probabilities");
        Table CATkans1 = loadTable("CAT kans1.csv", "header"),
          CATkans2 = loadTable("CAT kans2.csv", "header"),
          CATkans3 = loadTable("CAT kans3.csv", "header");

        //------------------------------------------------------------------- parameters neighbourhood
        for (Perceel perceel : percelen) {
          FloatList hoogtesOmgeving = new FloatList(), oppVerhoudingOmgeving = new FloatList(), volVerhoudingOmgeving = new FloatList();

          for (int k=0; k<perceel.percelenOmgeving.size(); k++) {
            hoogtesOmgeving.append(percelen[k].hoogte);
            oppVerhoudingOmgeving.append(percelen[k].oppVerhouding);
            volVerhoudingOmgeving.append(percelen[k].volVerhouding);
          }
          perceel.verwerken(hoogtesOmgeving, oppVerhoudingOmgeving, volVerhoudingOmgeving);

          //----------------------------------------------------------------- categories probability
          perceel.CAT_kans();

          String CATtype    = perceel.CATtype;
          String CATOppVerh = perceel.CATOppVerh;
          String CATmobi    = perceel.CATmobi;
          String CAThoogte  = perceel.CAThoogte;
          String CATopp     = perceel.CATopp;

          //----------------------------------------------------------------- retreiving probabilities from table
          int rijCat = 99999;

          for (int k = 0; k < CATkans1.getRowCount(); k++) {
            if (CATkans1.getString(k, "CAT2 type").equals(CATtype) == true
              && CATkans1.getString(k, "CAT2 OppVerhouding").equals(CATOppVerh)
              && CATkans1.getString(k, "CAT mobi").equals(CATmobi) == true
              && CATkans1.getString(k, "CAT hoogte").equals(CAThoogte) == true
              && CATkans1.getString(k, "CAT perceelopp").equals(CATopp) == true ) {
              rijCat = k;
            }
          }
          if (rijCat < 99999) {
            int Ttotaal     = CATkans1.getInt(rijCat, "Count of id");
            int Tvergroten  = CATkans1.getInt(rijCat, "vergroot20");
            int Tverkleinen = CATkans1.getInt(rijCat, "verkleind20");
            int Tneutraal   = CATkans1.getInt(rijCat, "neutraal20");
            perceel.kansUpdate(Ttotaal, Tvergroten, Tverkleinen, Tneutraal);
          } else {
            for (int k = 0; k < CATkans2.getRowCount(); k++) {
              if (CATkans2.getString(k, "CAT2 type").equals(CATtype) == true
                && CATkans2.getString(k, "CAT2 OppVerhouding").equals(CATOppVerh)
                && CATkans2.getString(k, "CAT hoogte").equals(CAThoogte) == true
                && CATkans2.getString(k, "CAT perceelopp").equals(CATopp) == true) {
                rijCat = k;
              }
            }
            if (rijCat < 99999) {
              int Ttotaal     = CATkans2.getInt(rijCat, "Count of id");
              int Tvergroten  = CATkans2.getInt(rijCat, "vergroot20");
              int Tverkleinen = CATkans2.getInt(rijCat, "verkleind20");
              int Tneutraal   = CATkans2.getInt(rijCat, "neutraal20");
              perceel.kansUpdate(Ttotaal, Tvergroten, Tverkleinen, Tneutraal);
            } else {
              for (int k = 0; k < CATkans3.getRowCount(); k++) {
                if (CATkans3.getString(k, "CAT2 type").equals(CATtype) == true
                  && CATkans3.getString(k, "CAT2 OppVerhouding").equals(CATOppVerh)
                  && CATkans3.getString(k, "CAT hoogte").equals(CAThoogte) == true) {
                  rijCat = k;
                }
              }
              if (rijCat < 99999) {
                int Ttotaal     = CATkans3.getInt(rijCat, "Count of id");
                int Tvergroten  = CATkans3.getInt(rijCat, "vergroot20");
                int Tverkleinen = CATkans3.getInt(rijCat, "verkleind20");
                int Tneutraal   = CATkans3.getInt(rijCat, "neutraal20");
                perceel.kansUpdate(Ttotaal, Tvergroten, Tverkleinen, Tneutraal);
              } else {
                println("ERROR KANS");
              }
            }
          }
          perceel.kleurenUpdated();
        }
        println("SETUP COMPLETE");
        decision = true;
        rectMode(CORNER);
        fill(255);
        noStroke();
      }
    }


    if (decision == true) {
      if (mouseX > 4*width/7 && mouseX <5* width/7 && mouseY > height-100) {
        if (blokken == false) {
          blokken = true;
          colorv = color(200);
          displayText = "3D-blocks: ON, click again to turn off, slows performance!";
        } else {
          blokken = false;
          colorv = color(230);
          displayText = "3D-blocks: OFF";
        }
      }
      if (mouseX > 5*width/7 && mouseX <6* width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
        if (info == false) {
          info = true;
          colorP = color(200);
          displayText = "centroids: ON, click again to turn off, slows performance!";
        } else {
          info = false;
          colorP = color(230);
          displayText = "centroids: OFF";
        }
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////___________________SIMULATION____________________/////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////

  if (mouseButton == RIGHT && decision == true) {
    Table CATvergroot1  = loadTable("CAT vergroot1.csv", "header"),
      CATvergroot2  = loadTable("CAT vergroot2.csv", "header"),
      CATverkleind1 = loadTable("CAT verkleind1.csv", "header"),
      CATverkleind2 = loadTable("CAT verkleind2.csv", "header");
    for (int j = 0; j < NumberOfSimulations; j++) {
      APVK = 0;
      APVG = 0;
      float volVergrootTot = 0, volVerkleindTot = 0, volVergrootGem = 0, volVerkleindGem = 0;

      //--------------------------------------------------------- deciding update
      for (Perceel perceel : percelen) {
        perceel.update();

        //------------------------------------------------------- categories change in volume

        perceel.CAT_volume();

        String CAT2type = perceel.CAT2type,
          CAT2opp  = perceel.CAT2opp,
          CAT2oppBebouwd = perceel.CAT2oppBebouwd;
        float dVolVergroot, dVolVerkleind;

        //------------------------------------------------------- assigning increase
        if (perceel.vergroot == true) {
          int rijCat = 99999;
          for (int k = 0; k < CATvergroot1.getRowCount(); k++) {
            if (CATvergroot1.getString(k, "type").equals(CAT2type) == true
              && CATvergroot1.getString(k, "CAT perceelopp").equals(CAT2opp) == true
              && CATvergroot1.getString(k, "CAT OppBebouwd").equals(CAT2oppBebouwd) == true ) {
              rijCat = k;
            }
          }

          if (rijCat < 99999) {
            dVolVergroot  = CATvergroot1.getFloat(rijCat, "Average of dVolumeR (2)") * 1.11083;
          } else {
            for (int k = 0; k < CATvergroot2.getRowCount(); k++) {
              if (CATvergroot2.getString(k, "type").equals(CAT2type) == true
                && CATvergroot2.getString(k, "CAT perceelopp").equals(CAT2opp) == true) {
                rijCat = k;
              }
            }
            dVolVergroot = CATvergroot2.getFloat(rijCat, "Average of dVolumeR (2)") * 1.11083;
          }
          perceel.vergroten(dVolVergroot);
          volVergrootTotaal += dVolVergroot;
        }


        //------------------------------------------------------ assigning decrease
        if (perceel.verkleind == true) {
          int rijCat = 99999;
          for (int k = 0; k < CATverkleind1.getRowCount(); k++) {
            if (CATverkleind1.getString(k, "type").equals(CAT2type) == true
              && CATverkleind1.getString(k, "CAT perceelopp").equals(CAT2opp) == true
              && CATverkleind1.getString(k, "CAT OppBebouwd").equals(CAT2oppBebouwd) == true ) {
              rijCat = k;
            }
          }

          if (rijCat < 99999) {
            dVolVerkleind  = CATverkleind1.getFloat(rijCat, "Average of dVolumeR (2)") * 1.29299;
          } else {
            for (int k = 0; k < CATverkleind2.getRowCount(); k++) {
              if (CATverkleind2.getString(k, "type").equals(CAT2type) == true
                && CATverkleind2.getString(k, "CAT perceelopp").equals(CAT2opp) == true) {
                rijCat = k;
              }
            }
            dVolVerkleind = CATverkleind2.getFloat(rijCat, "Average of dVolumeR (2)") * 1.29299;
          }
          perceel.verkleinen(dVolVerkleind);
          volVerkleindTotaal += dVolVerkleind;
        }

        //------------------------------------------------------ assigning neutral
        if (perceel.vergroot == false && perceel.verkleind == false) {
          perceel.neutraal();
        }

        //------------------------------------------------------ results
        if (perceel.vergroot == true) {
          APVG++;
          volVergrootTot += perceel.dVolVergroot;
        }
        if (perceel.verkleind == true) {
          APVK++;
          volVerkleindTot += perceel.dVolVerkleind;
        }
        perceel.lijstVolNieuw();
        perceel.kleurenUpdated();
        coloru = color(200);
        colorh = colori = coloro = color(230);
      }

      simulationsDone++;
      volVergrootGem = volVergrootTot/APVG;
      volVerkleindGem = volVerkleindTot/APVK;
      displayText = ENTER + "# simulations done: " + simulationsDone + "/" + NumberOfSimulations + ENTER + "parcels increased: " + APVG + "    parcels decreased: " + APVK + ENTER
        + "total added volume: " + int(volVergrootTot) + "  total removed volume: " + int(volVerkleindTot) + "    sum: " + int(volVergrootTot+volVerkleindTot) + ENTER
        + "average addition: " + int(volVergrootGem) + "    average removal: " + int(volVerkleindGem) + ENTER + ENTER
        + "average total added volume over all simulations  : " + int((float)volVergrootTotaal/simulationsDone) + ENTER
        + "average total removed volume over all simulations: " + int((float)volVerkleindTotaal/simulationsDone) + ENTER
        + "SUM: " + ((volVergrootTotaal/simulationsDone)+(volVerkleindTotaal/simulationsDone));
    }
  }
}



void mouseReleased() {
  loop();
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////___________________DRAW____________________/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

void draw() {
  if (decision == true) {
    //_______________________________________background & camera_____________________________________//

    rotateX(0);
    rotateY(0);
    background(255);
    fill(255, 0, 0);

    //__________________________________________drawing map_________________________________________//

    for (Perceel perceel : percelen) {
      perceel.tekenPercelen();
      if (blokken == true) {
        perceel.tekenBlokken();
      }
    }
    for (Perceel perceel : percelen) {
      if (info == true) {
        perceel.tekenPunten();
      }
    }

    //__________________________________________drawing HUD_________________________________________//

    cam.beginHUD();
    //color coloru = 200, colorh = 200, colori = 200, coloro = 200, colorP = 200, colorp = 200, colorv = 200, colorb = 200, colore = 200;
    //boolean blokken = false, info = false;
    stroke(0);
    strokeWeight(3);
    textSize(30);
    textAlign(CENTER, CENTER);

    //-----------------------------------------------------------------------------------------------------u
    if (mouseX > 0 && mouseX < width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
      for (Perceel perceel : percelen) {
        perceel.kleurenUpdated();
      }
      displayText = "colors: updated parcels (green: increased, red: decreased)";
      coloru = color(200);
      colorh = colori = coloro = color(230);
    }
    fill(coloru);
    rect(0, height-100, width/7, 100);
    fill(colorText);
    text("updated parcels", width/14, height-60);

    //-----------------------------------------------------------------------------------------------------h
    if (mouseX > width/7 && mouseX <2* width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
      for (Perceel perceel : percelen) {
        perceel.kleurenHoogte();
      }
      displayText = "colors: building heights (red = higher, gray = empty)";
      colorh = color(200);
      coloru = colori = coloro = color(230);
    }
    fill(colorh);
    rect(width/7, height-100, width/7, 100);
    fill(colorText);
    text("building heights", 3*(width/14), height-60);

    ////-----------------------------------------------------------------------------------------------------i
    if (mouseX > 2*width/7 && mouseX <3* width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
      for (Perceel perceel : percelen) {
        perceel.kleurenkansVergroten();
      }
      displayText = "colors: probability of increasing (darker = higher)";
      colori = color(200);
      coloru = colorh = coloro = color(230);
    }
    fill(colori);
    rect(2*width/7, height-100, width/7, 100);
    fill(colorText);
    text("probability increase", 5*(width/14), height-60);

    //-----------------------------------------------------------------------------------------------------o
    if (mouseX > 3*width/7 && mouseX <4* width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
      for (Perceel perceel : percelen) {
        perceel.kleurenkansVerkleinen();
      }
      displayText = "colors: probability of decreasing (darker = higher)";
      coloro = color(200);
      coloru = colorh = colori = color(230);
    }
    fill(coloro);
    rect(3*width/7, height-100, width/7, 100);
    fill(colorText);
    text("probability decrease", 7*(width/14), height-60);

    //-----------------------------------------------------------------------------------------------------v
    fill(colorv);
    rect(4*width/7, height-100, width/7, 100);
    fill(colorText);
    text("3D-blocks", 9*(width/14), height-60);

    //-----------------------------------------------------------------------------------------------------P
    fill(colorP);
    rect(5*width/7, height-100, width/7, 100);
    fill(colorText);
    text("centroids", 11*(width/14), height-60);

    //-----------------------------------------------------------------------------------------------------e
    if (mouseX > 6*width/7 && mouseX <7* width/7 && mouseY > height-100 && mousePressed && mouseButton == LEFT) {
      for (Perceel perceel : percelen) {
        perceel.gemVolNieuw();
      }
      String naamExport = municipality + " 2014S EXPORT.csv";
      //------------------------------------------------------ defining export table
      Table export = new Table();
      export.addColumn("id", Table.INT);
      export.addColumn("opp", Table.FLOAT);
      export.addColumn("oppBebouwd", Table.FLOAT);
      export.addColumn("hoogte", Table.FLOAT);
      export.addColumn("oppVerhouding", Table.FLOAT);
      export.addColumn("volVerhouding", Table.FLOAT);
      //export.addColumn("zone", Table.STRING);
      //export.addColumn("zoneId", Table.INT);
      //export.addColumn("type", Table.STRING);
      //export.addColumn("typeId", Table.INT);
      //export.addColumn("mobi", Table.FLOAT);
      export.addColumn("volNieuw", Table.FLOAT);
      export.addColumn("volNieuwGem", Table.FLOAT);
      //------------------------------------------------------ filling export table
      for (Perceel perceel : percelen) {
        export.setInt(perceel.shapeid, "id", perceel.shapeid  );
        export.setFloat(perceel.shapeid, "opp", perceel.oppPerceel  );
        export.setFloat(perceel.shapeid, "oppBebouwd", perceel.oppBebouwd  );
        export.setFloat(perceel.shapeid, "oppVerhouding", perceel.oppVerhouding  );
        export.setFloat(perceel.shapeid, "volVerhouding", perceel.volVerhouding  );
        export.setFloat(perceel.shapeid, "hoogte", perceel.hoogte );
        //export.setString(perceel.shapeid, "zone", perceel.zone  );
        //export.setInt(perceel.shapeid, "zoneId", perceel.zoneId  );
        //export.setString(perceel.shapeid, "type", perceel.type  );
        //export.setInt(perceel.shapeid, "typeId", perceel.typeId  );
        //export.setFloat(perceel.shapeid, "mobi", perceel.mobi  );
        export.setFloat(perceel.shapeid, "volNieuw", perceel.volNieuw  );
        export.setFloat(perceel.shapeid, "volNieuwGem", perceel.volNieuwGem  );
      }
      //------------------------------------------------------ saving export table
      saveTable(export, naamExport);
      displayText = "SIMULATIONS SAVED AS: | " + naamExport + " |      SIMULATIONS DONE: " + simulationsDone  + "      |      restart application to make new simulations";
      colore = color(250, 50, 50);
      noLoop();
    }
    fill(colore);
    rect(6*width/7, height-100, width/7, 100);
    fill(colorText);
    text("EXPORT", 13*(width/14), height-60);

    //------------------------------------------------------ exit
    if (mouseX < width && mouseX > width-100 && mouseY < 100 && mouseY > 0) {
      colorExit = color(250, 50, 50);
      fill(colorExit);
      stroke(255);
      if (mousePressed && mouseButton == LEFT) {
        exit();
      }
    } else {
      colorExit = color(255);
      stroke(0);
      noFill();
    }
    line(width -80, 20, width-20, 80);
    line(width-80, 80, width-20, 20);
    noStroke();
    rect(width-100, 0, 100, 100);

    //------------------------------------------------------ sims
    if (mouseX > width-100 && mouseX < width && mouseY > height -160 && mouseY < height-100) {
      fill(230);
      rect(width-100, height-160, 100, 60);
      if (mousePressed) {
        NumberOfSimulations *= 10;
        if (NumberOfSimulations > 10000) NumberOfSimulations = 1;
        simsChosen = true;
        noLoop();
      }
    }
    textAlign(RIGHT);
    fill(colorText);
    if (simsChosen == true && NumberOfSimulations < 1000) text("amount of sims per click:", width-100, height-120);
    if (simsChosen == true && NumberOfSimulations > 100)  text("amount of sims per click (high amounts will require loading time)", width-100, height-120);
    if (simsChosen == false) text("amount of sims per click [click number to change]", width-100, height-120);

    textAlign(CENTER);
    text(NumberOfSimulations, width-50, height-120);




    //------------------------------------------------------ running
    textAlign(LEFT, BOTTOM);
    fill(colorText);
    text(displayText, 10, height-120);



    //------------------------------------------------------ update hint
    if (simulationsDone <= 0) {
      textAlign(CENTER, BOTTOM);
      text("[right click to make a simulation]", width/2, height-120);
    }
    cam.endHUD();
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////___________________KEYS____________________/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


void keyPressed() {
  //              KEY   u       :   updated parcels, increased volume in green, decreased in red
  //                    i       :   probability of volume increase
  //                    o       :   probability of volume decrease
  //                    h       :   building height
  //                    P       :   show centroids & height
  //                    p       :   hide centroids & height
  //                    b       :   show 3D-blocks
  //                    v       :   hide 3D-blocks
  //                    e       :   export simulation results

  //------------------------------------------------------ colors: updated parcels
  if (key == 'u') {
    for (Perceel perceel : percelen) {
      perceel.kleurenUpdated();
    }
    println("colors: updated parcels");
  }
  //------------------------------------------------------ colors: probability of volume increase
  if (key == 'i') {
    for (Perceel perceel : percelen) {
      perceel.kleurenkansVergroten();
    }
    println("colors: probability of volume increase");
  }
  //------------------------------------------------------ colors: probability of volume decrease
  if (key == 'o') {
    for (Perceel perceel : percelen) {
      perceel.kleurenkansVerkleinen();
    }
    println("colors: probability of volume decrease");
  }
  //------------------------------------------------------ colors: building height
  if (key == 'h') {
    for (Perceel perceel : percelen) {
      perceel.kleurenHoogte();
    }
    println("colors: building height");
  }
  //------------------------------------------------------ show 3D-blocks
  if (key == 'b') {
    blokken = true;
    println("show 3D-blocks");
  }
  //------------------------------------------------------ hide 3D-blocks
  if (key == 'v') {
    blokken = false;
    println("hide 3D-blocks");
  }
  //------------------------------------------------------ show centroids & height
  if (key == 'P') {
    info = true;
    println("info");
  }
  //------------------------------------------------------ hide centroids & height
  if (key == 'p') {
    if (info == false) {
      info = true;
    } else {
      info = false;
    }
    println("geen info");
  }


  //__________________________________________    EXPORT    ________________________________________//

  if (key == 'e') {
    for (Perceel perceel : percelen) {
      perceel.gemVolNieuw();
    }
    String naamExport = municipality + " 2014S EXPORT.csv";
    //------------------------------------------------------ defining export table
    Table export = new Table();
    export.addColumn("id", Table.INT);
    export.addColumn("opp", Table.FLOAT);
    export.addColumn("oppBebouwd", Table.FLOAT);
    export.addColumn("hoogte", Table.FLOAT);
    export.addColumn("oppVerhouding", Table.FLOAT);
    export.addColumn("volVerhouding", Table.FLOAT);
    //export.addColumn("zone", Table.STRING);
    //export.addColumn("zoneId", Table.INT);
    //export.addColumn("type", Table.STRING);
    //export.addColumn("typeId", Table.INT);
    //export.addColumn("mobi", Table.FLOAT);
    export.addColumn("volNieuw", Table.FLOAT);
    export.addColumn("volNieuwGem", Table.FLOAT);
    //------------------------------------------------------ filling export table
    for (Perceel perceel : percelen) {
      export.setInt(perceel.shapeid, "id", perceel.shapeid  );
      export.setFloat(perceel.shapeid, "opp", perceel.oppPerceel  );
      export.setFloat(perceel.shapeid, "oppBebouwd", perceel.oppBebouwd  );
      export.setFloat(perceel.shapeid, "oppVerhouding", perceel.oppVerhouding  );
      export.setFloat(perceel.shapeid, "volVerhouding", perceel.volVerhouding  );
      export.setFloat(perceel.shapeid, "hoogte", perceel.hoogte );
      //export.setString(perceel.shapeid, "zone", perceel.zone  );
      //export.setInt(perceel.shapeid, "zoneId", perceel.zoneId  );
      //export.setString(perceel.shapeid, "type", perceel.type  );
      //export.setInt(perceel.shapeid, "typeId", perceel.typeId  );
      //export.setFloat(perceel.shapeid, "mobi", perceel.mobi  );
      export.setFloat(perceel.shapeid, "volNieuw", perceel.volNieuw  );
      export.setFloat(perceel.shapeid, "volNieuwGem", perceel.volNieuwGem  );
    }
    //------------------------------------------------------ saving export table
    saveTable(export, naamExport);
    //saveTable(metrics, "metrics.csv");
    println(ENTER + "SIMULATIONS SAVED AS:  " + naamExport + "     |      SIMULATIONS DONE: " + simulationsDone + ENTER);
  }
}
