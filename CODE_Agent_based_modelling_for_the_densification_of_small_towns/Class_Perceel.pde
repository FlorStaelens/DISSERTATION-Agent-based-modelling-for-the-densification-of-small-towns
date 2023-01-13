class Perceel {
  int i, shapeid, fid, typeId, zoneId;
  float oppPerceel, oppBebouwd, hoogte, vol, volVerhouding, oppVerhouding, mobi;
  Boolean uitbreidingsgebied, woongebied, woonvernieuwingsgebied, landbouwgebied, bedrijventerrein, buitenwoongebied;
  String type, zone, categorie;

  FloatList vertX = new FloatList();
  FloatList vertY = new FloatList();
  PVector zwaartepunt = new PVector(0, 0);
  Float zwaartepuntX, zwaartepuntY;
  PShape vorm, blok;

  color colPunt = color(255), colStroke = color(255), colFill = color(100);

  float straal;
  IntList percelenOmgeving = new IntList();
  int omgevingBebouwd = 0;
  FloatList hoogtesOmgeving = new FloatList(), hoogtesOmgevingT = new FloatList();
  FloatList volOmgeving = new FloatList(), volOmgevingT = new FloatList();
  FloatList volVerhoudingOmgeving = new FloatList(), volVerhoudingOmgevingT = new FloatList();
  FloatList oppVerhoudingOmgeving = new FloatList(), oppVerhoudingOmgevingT = new FloatList();
  FloatList mobiOmgeving = new FloatList();

  float gemHoogteOmgeving, verschilHoogte;
  float gemOppVerhoudingOmgeving, verschilOppVerhouding;
  float gemVolVerhoudingOmgeving, verschilVolVerhouding;
  float gemMobiOmgeving, verschilMobi;

  String CATtype, CATOppVerh, CATmobi, CAThoogte, CATopp;
  String CAT2type, CAT2opp, CAT2oppBebouwd, CAT2verschilHoogteOmg;

  float kansVergroten, kansVerkleinen;
  float volToegevoegd, volNieuwGem;
  float dVolVergroot, dVolVerkleind;
  Boolean vergroot = false, verkleind = false;
  FloatList lijstVolNieuw = new FloatList();


  //________________________________________importing data____________________________________________//


  Perceel(int NUMMER, float OPPPERC, float HOOG, float OPPBEB, float MOBI, String VERNIEUWG, String WOONG, String LANDB, String BEDRIJVENT, String UITBR, int ZONEID, String ZONE, Float X, Float Y, String municipality ) {
    shapeid = NUMMER;
    i = NUMMER;
    oppPerceel = OPPPERC;
    hoogte =HOOG;
    if (hoogte > 0 == false) {
      hoogte = 0;
    }
    oppBebouwd =OPPBEB;
    mobi =MOBI;
    vol = oppBebouwd*hoogte;
    volVerhouding = vol/oppPerceel;
    oppVerhouding = oppBebouwd/oppPerceel;
    zone = ZONE;
    zoneId = ZONEID;
    if (municipality == "Eeklo") {
      zwaartepuntX = (X-89000)/10;
      zwaartepuntY= -(Y-204000)/10+1000;
    } else {
      zwaartepuntX = (X-121000)/10;
      zwaartepuntY= -(Y-190000)/10+1000;
    }
    zwaartepunt.set(zwaartepuntX, zwaartepuntY);

    //________________________________________assigning function____________________________________________//

    if (BEDRIJVENT.isEmpty() == false) {
      type = "bedrijventerrein";
      categorie = "industrie";
      typeId = 4;
      straal = 40;
    } else if (UITBR.isEmpty() == false) {
      type = "woonuitbreidingsgebied";
      categorie = "wonen";
      typeId = 3;
      straal = 10;
    } else if (VERNIEUWG.isEmpty() == false) {
      type = "woonvernieuwingsgebied";
      categorie = "wonen";
      typeId = 2;
      straal = 10;
    } else if (WOONG.isEmpty() == false) {
      type = "woongebied";
      categorie = "wonen";
      typeId = 1;
      straal = 10;
    } else if (LANDB.isEmpty() == false) {
      type = "landbouwgebied";
      categorie = "buiten";
      typeId = 5;
      straal = 40;
    } else {
      type = "buitengebied";
      categorie = "buiten";
      typeId = 6;
      straal = 40;
    }
  }

  //________________________________________defining geometry____________________________________________//

  void geoData(float X, float Y, int j, String municipality) {
    float x, y;
    if (municipality == "Eeklo") {
      x= (X-89000)/10;
      y= -(Y-204000)/10+1000;
    } else {
      x= (X-121000)/10;
      y= -(Y-190000)/10+1000;
    }
    vertX.append(x);
    vertY.append(y);
  }

  void vorm() {
    vorm = createShape();
    vorm.beginShape();
    vorm.fill(color(colFill));
    vorm.noStroke();
    for (int k=0; k<vertX.size(); k++) {
      vorm.vertex( vertX.get(k), vertY.get(k));
    }
    vorm.endShape();
  }

  void blok() {
    pushMatrix();
    blok = createShape(BOX, sqrt(oppBebouwd/100), sqrt(oppBebouwd/100), hoogte/10);
    popMatrix();
  }


  //________________________________________definging neighbourhood______________________________________//


  void addToOmgeving(int shapeid) {
    percelenOmgeving.append(shapeid);
    if (percelen[shapeid].hoogte > 1) {
      omgevingBebouwd++;
    }
  }


  //________________________________________data from neighbourhood______________________________________//



  void verwerken(FloatList hoogtesO, FloatList oppVerhoudingO, FloatList volVerhoudingO) {
    hoogtesOmgeving = hoogtesO;
    oppVerhoudingOmgeving = oppVerhoudingO;
    volVerhoudingOmgeving = volVerhoudingO;


    float sumHoogte =0;
    float sumOppVerhouding =0;
    float sumVolVerhouding =0;
    int totaalHoogte=0;
    int totaalOppVerhouding =0;
    int totaalVolVerhouding =0;

    for (int k=0; k<hoogtesOmgeving.size(); k++) {
      if (hoogtesOmgeving.get(k)>0) {
        sumHoogte +=hoogtesOmgeving.get(k) ;
        totaalHoogte++;
      }
      if (oppVerhoudingOmgeving.get(k) > 0) {
        sumOppVerhouding += oppVerhoudingOmgeving.get(k);
        totaalOppVerhouding++;
      }
      if (volVerhoudingOmgeving.get(k) > 0) {
        sumVolVerhouding += volVerhoudingOmgeving.get(k);
        totaalVolVerhouding++;
      }
    }
    if (sumHoogte > 0) {
      gemHoogteOmgeving = sumHoogte/totaalHoogte;
      verschilHoogte = gemHoogteOmgeving - hoogte;
    } else {
      gemHoogteOmgeving = 0;
      verschilHoogte = 0;
    }
    gemOppVerhoudingOmgeving = sumOppVerhouding/totaalOppVerhouding;
    verschilOppVerhouding = gemOppVerhoudingOmgeving - oppVerhouding;
    gemVolVerhoudingOmgeving = sumVolVerhouding/totaalVolVerhouding;
    verschilVolVerhouding = gemVolVerhoudingOmgeving - oppVerhouding;
    //println(shapeid + "  " + oppPerceel + "  gemHoogteOmgeving: " + gemHoogteOmgeving + "  gemOppverhoudingOmgeving: " + gemOppVerhoudingOmgeving);
  }

  //________________________________________update probability____________________________________________//

  void CAT_kans() {

    //-------------------TYPE--------------//
    if (type == "landbouwgebied" ) {
      CATtype = "1_landbouw";
    } else if (type == "woonuitbreidingsgebied") {
      CATtype = "2_uitbreidingsgebied";
    } else if (type == "bedrijventerrein" || type == "buitengebied" || type == "woongebied" || type == "woonvernieuwingsgebied") {
      CATtype = "3_ander";
    } else {
      println("ERROR CAT TYPE");
    }

    //-------------OPPVERHOUDING----------//
    if (oppVerhouding == 0) {
      CATOppVerh = "1_onbebouwd";
    } else if (oppVerhouding > 0) {
      CATOppVerh = "2_bebouwd";
    } else {
      println("ERROR CAT OPPVERHOUDING");
    }

    //-------------------MOBI--------------//
    if (mobi < 6500) {
      CATmobi = "1_zeer laag";
    } else if (mobi >= 6500 && mobi < 7200) {
      CATmobi = "2_laag";
    } else if (mobi >= 7200 && mobi < 7700) {
      CATmobi = "3_middel";
    } else if (mobi >= 7700 && mobi < 7900) {
      CATmobi = "4_hoog";
    } else if (mobi >= 7900) {
      CATmobi = "5_heel hoog";
    } else {
      println("ERROR CAT MOBI");
    }

    //-------------------HOOGTE--------------//
    if (hoogte == 0) {
      CAThoogte = "1_heel laag";
    } else if (hoogte > 0 && hoogte < 5) {
      CAThoogte = "2_laag";
    } else if (hoogte >= 5 && hoogte <8) {
      CAThoogte = "3_middel";
    } else if (hoogte >= 8) {
      CAThoogte = "4_hoog";
    } else {
      println("ERROR CAT HOOGTE");
    }

    //---------------PERCEEL OPP--------------//
    if (oppPerceel < 250) {
      CATopp = "1_heel klein";
    } else if (oppPerceel >= 250 && oppPerceel < 500) {
      CATopp = "2_klein";
    } else if (oppPerceel >= 500 && oppPerceel < 1500) {
      CATopp = "3_middel";
    } else if (oppPerceel >= 1500 && oppPerceel < 5000) {
      CATopp = "4_groot";
    } else if (oppPerceel >= 5000) {
      CATopp = "5_heel groot";
    } else {
      println("ERROR CAT PERCEELOPP");
    }
  }


  //---------------RESULT----------------//

  void kansUpdate(int Ttotaal, int Tvergroten, int Tverkleinen, int Tneutraal) {
    float totaal = Ttotaal, vergroten = Tvergroten, verkleinen = Tverkleinen, neutraal = Tneutraal;
    kansVergroten = vergroten/totaal;
    kansVerkleinen = verkleinen/totaal;
  }


  //__________________________________________  update  ________________________________________//

  float hoogteNieuw;
  float oppVerhoudingNieuw;
  float oppBebouwdNieuw;
  float volNieuw;
  float volVerhoudingNieuw;

  //-------------------DECISION--------------//
  void update() {
    vergroot = false;
    verkleind = false;
    float kans = random(0, 1);
    if (kans <= kansVergroten) {
      vergroot = true;
    } else if (kans >= 1-kansVerkleinen) {
      verkleind = true;
    }
  }

  void CAT_volume() {

    //-------------------TYPE--------------//
    if (type == "bedrijventerrein") {
      CAT2type = "bedrijventerrein";
    } else if (type == "landbouwgebied") {
      CAT2type = "landbouwgebied";
    } else if (type == "woongebied") {
      CAT2type = "woongebied";
    } else if (type == "woonvernieuwingsgebied") {
      CAT2type = "woonvernieuwingsgebied";
    } else if (type == "woonuitbreidingsgebied") {
      CAT2type = "uitbreidingsgebied";
    } else if (type == "buitengebied") {
      CAT2type = "buitengebied";
    } else {
      println("ERROR CAT2 TYPE");
    }

    //--------------PERCEEL OPP------------//
    if (oppPerceel < 250) {
      CAT2opp = "1_heel klein";
    } else if (oppPerceel >= 250 && oppPerceel < 500) {
      CAT2opp = "2_klein";
    } else if (oppPerceel >= 500 && oppPerceel < 1500) {
      CAT2opp = "3_middel";
    } else if (oppPerceel >= 1500 && oppPerceel < 5000) {
      CAT2opp = "4_groot";
    } else if (oppPerceel >= 5000) {
      CAT2opp = "5_heel groot";
    } else {
      println("ERROR CAT2 PERCEELOPP");
    }

    //-------------OPP BEBOUWD-------------//
    if (oppBebouwd == 0) {
      CAT2oppBebouwd = "1_zeer klein";
    } else if (oppBebouwd > 0 && oppBebouwd < 100) {
      CAT2oppBebouwd = "2_klein";
    } else if (oppBebouwd >= 100 && oppBebouwd < 250) {
      CAT2oppBebouwd = "3_middel";
    } else if (oppBebouwd >= 250 && oppBebouwd < 400) {
      CAT2oppBebouwd = "4_groot";
    } else if (oppBebouwd >= 400) {
      CAT2oppBebouwd = "5_zeer groot";
    } else {
      println("ERROR CAT2 OPPBEBOUWD");
    }
  }

  //---------ASSIGNING NEW VOLUME----------//
  void vergroten(float dVolVG) {
    dVolVergroot = dVolVG;
    if (vergroot) {
      volNieuw = vol + dVolVergroot;
    }
  }

  void verkleinen(float dVolVK) {
    dVolVerkleind = dVolVK;
    if (verkleind) {
      volNieuw = vol + dVolVerkleind;
    }
  }

  void neutraal() {
    volNieuw = vol;
  }

  //---------------VOLUME LIST--------------//
  void lijstVolNieuw() {
    lijstVolNieuw.append(volNieuw);
  }

  void gemVolNieuw() {
    float volNieuwTotaal = 0;
    for (int k =0; k < lijstVolNieuw.size(); k++) {
      volNieuwTotaal += lijstVolNieuw.get(k);
    }
    volNieuwGem = volNieuwTotaal / lijstVolNieuw.size();
  }

  //____________________________________________colors___________________________________________//


  void kleurenUpdated() {
    if (vergroot) {
      vorm.setFill ( color(0, 128, 128));
    } else if (verkleind) {
      vorm.setFill( color(208, 88, 126));
    } else {
      vorm.setFill( color(230));
    }
  }

  void kleurenkansVergroten() {
    if (kansVergroten >= 0.4 && kansVergroten <= 1) {
      vorm.setFill( color(0, 128, 128));
    } else if (kansVergroten >= 0.2 && kansVergroten < 0.4) {
      vorm.setFill( color(112, 164, 148));
    } else if (kansVergroten >= 0.1 && kansVergroten < 0.2) {
      vorm.setFill( color(180, 200, 168));
    } else if (kansVergroten >= 0 && kansVergroten < 0.1) {
      vorm.setFill( color(230));
    }
  }

  void kleurenkansVerkleinen() {
    if (kansVerkleinen >= 0 && kansVerkleinen < 0.1) {
      vorm.setFill(color(230));
    } else if (kansVerkleinen >= 0.1 && kansVerkleinen < 0.2) {
      vorm.setFill(color(229, 185, 173));
    } else if (kansVerkleinen >= 0.2 && kansVerkleinen < 0.4) {
      vorm.setFill(color(217, 137, 148));
    } else if (kansVerkleinen >= 0.4 && kansVerkleinen <= 1) {
      vorm.setFill(color(208, 88, 126));
    }
  }

  void kleurenHoogte() {
    if (hoogte == 0) {
      vorm.setFill(color(230));
    } else if (hoogte > 0 && hoogte <= 2) {
      vorm.setFill(color(0, 128, 128));
    } else if (hoogte > 2 && hoogte <= 3) {
      vorm.setFill(color(112, 164, 148));
    } else if (hoogte > 3 && hoogte <= 4) {
      vorm.setFill(color(180, 200, 168));
    } else if (hoogte > 4 && hoogte <= 6) {
      vorm.setFill(color(246, 237, 189));
    } else if (hoogte > 6 && hoogte <= 8) {
      vorm.setFill(color(237, 187, 138));
    } else if (hoogte > 8 && hoogte <= 12) {
      vorm.setFill(color(222, 138, 90));
    } else if (hoogte > 12) {
      vorm.setFill(color(202, 86, 44));
    }
  }



  //____________________________________________drawing___________________________________________//


  void tekenPercelen() {
    shape(vorm);
  }

  void tekenBlokken() {
    pushMatrix();
    translate(zwaartepunt.x, zwaartepunt.y, hoogte/10);
    blok.setFill(color(255));
    blok.setStrokeWeight(1);
    shape(blok);
    popMatrix();
  }



  void tekenPunten() {
    stroke(0);
    strokeWeight(5);
    fill(0);
    point(zwaartepunt.x, zwaartepunt.y);
  }
}
