// Necessary modules for server
var http = require('http');
var fs = require('fs');
var path = require('path');
var express = require('express');
var formidable = require('formidable');
var app = express();

// Names to send to the NDVI python script
var name4;
var name8;

// UTM coordinates for python script cut
var xUtmFirst
var yUtmFirst
var xUtmSecond
var yUtmSecond

// New user Datas to store
var userDatas;
var userParCreate;
var nbParcNames = [];

// Detect step of user
var wichStep;

// Detect if we delete the user
var isFinish;

// Creation of the server
var server = require('http').createServer(app);

// Init of express, to point our Ressources
app.use(express.static(__dirname + '/Ressources/'));

// Define the view, so index.html
app.get('/', function(req, res,next) {
    res.sendFile(__dirname + '/Views/index.html');
});

// Event to handle uploads files
app.post('/upload', function(req, res){

  // create an incoming form object
  var form = new formidable.IncomingForm();

  // specify that we want to allow the user to upload multiple files in a single request
  form.multiples = true;
  if(wichStep == 0){
    var dir = "/Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2] + "/";
  }else{
    var dir = "/Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2] + "/Parcelle" + wichStep + "/";
  }


  // store all uploads in the /uploads directory
  form.uploadDir = path.join(__dirname, dir);

  // every time a file has been uploaded successfully,
  // rename it to it's orignal name
  form.on('file', function(field, file) {
    fs.rename(file.path, path.join(form.uploadDir, file.name));
  });

  // log any errors that occur
  form.on('error', function(err) {
    console.log('An error has occured: \n' + err);
  });

  // once all the files have been uploaded, send a response to the client
  form.on('end', function() {
    res.end('success');
  });

  // parse the incoming request containing the form data
  form.parse(req);

});

/* Chargement de socket.io */
var io = require('socket.io').listen(server);

/* Begin of synchronous listening of server */
io.sockets.on('connection', function (socket) {

    // Send a temp message to the client to confirm his connection
    socket.emit('message', 'Vous êtes bien connecté ! ');

    // Alert the server
    console.log("Un client s'est connecté");

    // Create a new folder to store a parcelle data
    socket.on('messageParcelle', function (message) {
      userParCreate = message;
      wichStep = userParCreate[3];
      var dir = "/Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2] + "/Parcelle" + wichStep + "/";
      if (!fs.existsSync(dir)){
        fs.mkdir( __dirname + dir, err => {})
      }
    });

    // Receive new user's datas.
    socket.on('message', function (message) {
      var utm = require('utm')
      userDatas = message;
      wichStep = 0;

      // wichStep prend la valeur de numéro parcelle
      var dir = "/Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2] + "/";
      if (!fs.existsSync(dir)){
        fs.mkdir( __dirname + dir, err => {})
      }
      var test = utm.fromLatLon(userDatas[7][0], userDatas[7][1]);
      var test1 = utm.fromLatLon(userDatas[7][2], userDatas[7][3]);
      xUtmFirst = test.easting;
      yUtmFirst = test.northing;
      xUtmSecond = test1.easting;
      yUtmSecond = test1.northing;
      socket.emit('beginProcedureDown', 'Procédure à lancer!');
    });

    /* Download a package from copernicus */
    socket.on('coordinates', function (message) {
      console.log("Une requete de téléchargement! Il veut les coordonnées suivantes: ");
      console.log(userDatas[7]);
      /*  Begin Download thanks to sh file  */
      const exec = require('child_process').exec; // Module nodejs pour exécuter le fichier bash
      const testscript = exec('"./Ressources/recupDonnees.sh" -c '+userDatas[7][1]+','+userDatas[7][0]+':'+userDatas[7][3]+','+userDatas[7][2]); // Longitude et lattitude
      console.log("Téléchargement lancé?");
      testscript.stdout.on('data', function(data){
         //TODO: When Download is finished, call extract, then call delete
          console.log(""+data);
      });
      testscript.stderr.on('data', function(data){ // En cas d'erreur
          console.log(data);
      });
      testscript.on('close', function(data){ //Quand le téléchargement est fini
          console.log('end');
          socket.emit('dataDownloaded', 'Téléchargement terminé!');
      });
      console.log("ALLO!");
    });

/* Extract only images from the download zip and delete this archive */
    socket.on('extractFile', function (message) {
      var fs = require('fs');
      var parse = require('csv-parse');
      var myName = [];
      fs.createReadStream("Ressources/product-list.csv") // Charge le csv contenant les noms des archives téléchargées
        .pipe(parse({delimiter: ','}))
        .on('data', function(csvrow) {
        myName.push(csvrow[0]);
      })
      .on('end',function() { // Quand on a chargé le csv
        var Zip = require('adm-zip');
        for (var i = 0; i < myName.length; i++) {
          if(fs.existsSync("Ressources/farmingData/"+myName[i]+".zip")){ // Si l'archive existe
            var myzip = new Zip("Ressources/farmingData/"+myName[i]+".zip");
            /*  Extract Only IMG_DATA  */
            var zipEntries = myzip.getEntries();
            zipEntries.forEach(function(zipEntry) { // On extrait chaque élément de IMG Data
              var myString = "IMG_DATA/";
              var position = zipEntry.entryName.indexOf(myString);
    		      if (position != -1) {
                var total = position + myString.length;
                if( total == zipEntry.entryName.length){
                  myzip.extractEntryTo( zipEntry.entryName,"Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2] + "/", false, true);
                }
    		      }
    	      });
            deleteFile('Ressources/farmingData/'+myName[i]+'.zip'); // On supprime l'archive
            console.log("Extraction of " + myName[i] + " is finished!");
            socket.emit('extractFinished', 'Extraction terminée!');
          }
        }
      });
    });

    /* Function wich delete raws files and folders from data download  */
    socket.on('deleteData', function (message) {
      deleteFile('./OSquery-result.xml');
      deleteFile('./Ressources/product_list.xml');
      deleteFolder('./logs/');
      deleteFolder('./MANIFEST/');
      console.log('files deleted successfully!');
      socket.emit('deleteFinished', 'Suppression terminée');
    });

    /*  Find images name to send them to pythonn script */
    socket.on('findImagesName', function(data){
      var fs = require('fs');
      var dir = "./Ressources/farmingData/"+userDatas[0]+"_"+userDatas[1]+"_"+userDatas[2];
      // Gestion des différents cas de précisions de Copernicus, de base on préfère le 10m, et sinon on regarde aux étapes supérieurs
        if(fs.existsSync(dir)){
          console.log("Coucou tout le monde!");
        }
        if( fs.existsSync(dir + "/R10m") ) {
          console.log("Folder 10 exist!");
          var myPath = dir + "/R10m";
          fs.readdirSync(myPath).forEach(function(file) {
            findNames("B04", "B08", myPath, file);
          });
          console.log(name4 + " and " + name8);
        }else if(fs.existsSync(dir + "/R20m")){
          var myPath = dir + "/R20m";
          fs.readdirSync(myPath).forEach(function(file) {
            findNames("B04", "B8A", myPath, file);
          });
          console.log(name4 + " and " + name8);
        }else if(fs.existsSync(dir + "/R60m")  ){
          var myPath = dir + "/R60m";
          fs.readdirSync(myPath).forEach(function(file) {
            findNames("B04", "B8A", myPath, file);
          });
          console.log(name4 + " and " + name8);
        }else {
          console.log("Just take images!");
          var myPath = dir;
          fs.readdirSync(myPath).forEach(function(file) {
            findNames("B04", "B08", myPath, file);
          });
          console.log(name4 + " and " + name8);
        }

        // Execution du script Python
        var PythonShell = require('python-shell');
        console.log(xUtmFirst+' '+yUtmFirst+' '+xUtmSecond+' '+yUtmSecond);
        var options = {
          pythonPath: 'python3',
          args: [name4, name8, xUtmFirst, yUtmFirst, xUtmSecond, yUtmSecond, userDatas[0], userDatas[1], userDatas[2]]
        }
        PythonShell.run('./Ressources/imageNDVITotal.py', options, function (err,results){
          //if (err) throw err;
              // results is an array consisting of messages collected during execution
              console.log('results: %j', results);
        });

    });

});

/* Allow server to delete one file to a passing path */
function deleteFile(path) {
  fs.stat(path, function (err, stats) {
    if (err) {
      return console.error(err);
    }
    fs.unlink(path,function(err){
      if(err) return console.log(err);
    });
  });
  console.log("File deleted!" + path);
}

/*  Allow server to recursively delete a folder and it content by passing it path */
function deleteFolder(path) {
  if( fs.existsSync(path) ) {
    fs.readdirSync(path).forEach(function(file) {
      var curPath = path + "/" + file;
        if(fs.statSync(curPath).isDirectory()) { // recurse
          deleteFolderRecursive(curPath);
        } else { // delete file
          fs.unlinkSync(curPath);
        }
    });
    fs.rmdirSync(path);
  }
}

/*  For later, in final version, to reduce my code  */
function findNames(myString4, myString8, myPath, file){
  var curPath = myPath + "/" + file;
  var position4 = file.indexOf(myString4);
  var position8 = file.indexOf(myString8);
  if(position4 != -1){
    name4 = curPath;
  }else if(position8 != -1){
    name8 = curPath;
  }
}

// Port sur lequel écoute le serveur, s'y connecter avec localhost:8080 dans votre navigateur
server.listen(8080);
