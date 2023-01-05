
//  DISSERTATION - Agent-based modelling for the densification of small towns
//  Flor Staelens, 2022-2023
//
//  Simulation model for the built volume of a small town, published 05/01/2023
//
//
//  CONTROLS:   MOUSE left    :   camera rotate 
//                    middle  :   camera pan     
//                    right   :   simulate
//              KEY   u       :   updated parcels, increased volume in green, decreased in red
//                    i       :   probability of volume increase
//                    o       :   probability of volume decrease
//                    h       :   building height
//                    P       :   show centroids & height
//                    p       :   hide centroids & height
//                    b       :   show 3D-blocks
//                    v       :   hide 3D-blocks
//                    e       :   export simulation results
//
//  MUNICIPALITY TO SIMULATE ("Zele" / "Eeklo"):
//
String municipality = "Zele";
//
//  AMOUNT OF SIMULATIONS PER CLICK (individual results will not be displayed):
//
int NumberOfSimulations = 1;
//
//
//__________________________________________declarations________________________________________//
//camera
import peasy.*;
PeasyCam cam;
float scale=1;
float xPan=500, yPan=500;
boolean zoomIn = false, zoomOut= false, panUp= false, panDown = false, panLeft= false, panRight= false;
float panSpeed = 50, zoomSpeed = 2;

//3D-blocks
boolean blokken = false, info = false;

//class parcels
Perceel[] percelen;

//simulation metrics
int aantalPercelen =0, simulationsDone = 0;
int APVG = 0, APVK = 0;
double volVergrootTotaal = 0, volVerkleindTotaal = 0;

//miscelaneous
PFont myFont;

//data-files
String eigFile = municipality + " 2004R eig.csv";
String geoFile = municipality + " 2004R geo.csv";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////___________________SETUP____________________////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

void setup() {
  myFont = createFont("Laksaman Bold", 100, true);
  textFont(myFont);

  //__________________________________________defining camera________________________________________//

  size(1200, 1200, P3D);
  cam = new PeasyCam(this, 750);
  cam.setMinimumDistance(2);
  cam.setMaximumDistance(1000);
  cam.setSuppressRollRotationMode();
  cam.lookAt(500, 500, 0);
  float fov = PI/3;
  float cameraZ = (height/2)/ tan(fov/2);
  perspective(fov, float(width)/float(height), 1, cameraZ*10);
  background(0);

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
        eig.getString(i, "zone"), eig.getFloat(i, "X"), eig.getFloat(i, "Y"));
      percelen[i] = perceel;
    } else {
      Perceel perceel = new Perceel(eig.getInt(i, "shapeid"), eig.getFloat(i, "oppPerceel"),
        eig.getFloat(i, "hoogte"),
        eig.getFloat(i, "oppBebouwd"), eig.getFloat(i, "Mobiscore"),
        eig.getString(i, "woonvernieuwingsgebied"), eig.getString(i, "woongebied"),
        eig.getString(i, "landbouw"), eig.getString (i, "industrie"),
        eig.getString(i, "woonuitbreidingsgebied"), eig.getInt(i, "zoneId"),
        eig.getString(i, "zone"), eig.getFloat(i, "X"), eig.getFloat(i, "Y"));
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
      perceel.kleurenkansVergroten();
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
        perceel.kleurenkansVergroten();
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
          perceel.kleurenkansVergroten();
        } else {
          println("ERROR KANS");
        }
      }
    }
  }
  println("SETUP COMPLETE");
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////___________________SIMULATION____________________/////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

void mousePressed() {
  if (mouseButton == RIGHT) {
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
      }

      simulationsDone++;
      volVergrootGem = volVergrootTot/APVG;
      volVerkleindGem = volVerkleindTot/APVK;
      println(ENTER + "# simulations done: " + simulationsDone + "/" + NumberOfSimulations + ENTER + "parcels increased: " + APVG + "    parcels decreased: " + APVK + ENTER
        + "total added volume: " + volVergrootTot + "  total removed volume: " + volVerkleindTot + "    sum: " + (volVergrootTot+volVerkleindTot) + ENTER
        + "average addition: " + volVergrootGem + "    average removal: " + volVerkleindGem + ENTER
        + "    average total added volume over all simulations  : " + volVergrootTotaal/simulationsDone + ENTER
        + "    average total removed volume over all simulations: " + volVerkleindTotaal/simulationsDone + ENTER
        + "    SUM: " + ((volVergrootTotaal/simulationsDone)+(volVerkleindTotaal/simulationsDone)));
    }
  }
}






//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////___________________DRAW____________________/////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

void draw() {

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
    info = false;
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
    println(ENTER + "SIMULATIONS SAVED AS: | " + naamExport + " |      SIMULATIONS DONE: " + simulationsDone + ENTER);
  }
}
