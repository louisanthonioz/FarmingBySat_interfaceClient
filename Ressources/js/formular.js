
var map;
var markers = [];
var counter = 0;

// Variables to store in databeses, First and second Step
var name;
var firstname;
var number;
var adress;
var postalCode;
var city;
var mail;
var coordinates = [];

// Variables to store in databeses, Third Step
var pacDone = false;
var pacFile;
var nbh2;
var nbparcelles;
var typeOfSol = [];

// Variables to store in databeses, fourthStep
var parcCount = 0;

// Varaibles for last Step, with Parcelles
var allDatasParc = [];
var fumureName;
var fertFarmStarName;
var anaSolName;
var bilanNames = [];
var cartoRdtName;
var finalParc = false;

console.log('hello');

function hideElements(){
  //document.getElementById('secondStep').style.display = "none";
  document.getElementById('thirdStep').style.display = "none";
  document.getElementById('fourthStep').style.display = "none";
}

function goSecondStep(){

  name = document.getElementById("name").value;
  firstname = document.getElementById("firstname").value;
  number = document.getElementById("phone").value;
  adress = document.getElementById("adress").value;
  postalCode = document.getElementById("postalCode").value;
  city = document.getElementById("city").value;
  mail = document.getElementById("mail").value;

  if(name.length >= 2 && name.length <= 20){
    if(firstname.length >= 2 && firstname.length <= 20){
      if(number.length == 10 && isNaN(number) == false){
        if(adress.length > 3){
          if(postalCode.length == 5 && isNaN(postalCode) == false){
            if(city.length > 0){
              var regmail = /^[a-zA-Z0-9._-]+@[a-z0-9._-]{2,}\.[a-z]{2,4}$/;
              if(regmail.test(mail)){
                document.getElementById('firstStep').style.display = "none";
                document.getElementById('explainImages').style.display = "none";
                document.getElementById('secondStep').style.display = "block";
                document.getElementById('secondStepMap').style.display = "block";
                document.getElementById('secondStepText').style.display = "block";
                initMap();
              }else{
                alert("Champ mail invalide!");
              }
            }else{
              alert("Le champ de Ville n'est pas bien rempli!");
            }
          }else{
            alert("Le code postal n'est pas bien rempli!");
          }
        }else{
          alert("L'adresse n'est pas bien saisie!");
        }
      }else{
        alert("Le numéro n'est pas valide!");
      }
    }else{
      alert("Le prénom est invalide");
    }
  }else{
    alert("Le nom est invalide");
  }
}

function initMap() {
  var lat_lng = {lat: 50.63, lng: 3.06};

  map = new google.maps.Map(document.getElementById('secondStepMap'), {
    zoom: 7,
    center: lat_lng,
    mapTypeId: google.maps.MapTypeId.TERRAIN
  });

  // This event listener will call addMarker() when the map is clicked.
  map.addListener('click', function(event) {
    if(counter < 2){
      coordinates.push(event.latLng.lat());
      coordinates.push(event.latLng.lng());
      //coordinates.push(event.latLng.long());
      addMarker(event.latLng);
      counter++;
    }
    if(counter >= 2){
      setTimeout(goThirdStep,1000);
      var myDatas = [];

      myDatas.push(name);
      myDatas.push(firstname);
      myDatas.push(number);
      myDatas.push(adress);
      myDatas.push(postalCode);
      myDatas.push(city);
      myDatas.push(mail);
      myDatas.push(coordinates);

      sendUserData(myDatas);
    }
  });
}

// Adds a marker to the map and push to the array.
function addMarker(location) {
  var marker = new google.maps.Marker({
    position: location,
    map: map
  });
  markers.push(marker);
}

function goThirdStep(){
    document.getElementById("secondStep").style.display = "none";
    document.getElementById("thirdStep").style.display = "block";

    $('#pac').on('change', function(){
      var files = $(this).get(0).files;

      if (files.length > 0){

        pacFile = files[0].name;
        // create a FormData object which will be sent as the data payload in the
        // AJAX request
        var formData = new FormData();

        // loop through all the selected files and add them to the formData object
        for (var i = 0; i < files.length; i++) {
          var file = files[i];

          // add the files to formData object for the data payload
          formData.append('uploads[]', file, file.name);
        }
        console.log(pacDone + "Test event");
        $.ajax({
          url: '/upload',
          type: 'POST',
          data: formData,
          processData: false,
          contentType: false,
          success: function(data){
          },
          xhr: function() {
            console.log(pacDone + "Test event2");
            // create an XMLHttpRequest
            var xhr = new XMLHttpRequest();

            // listen to the 'progress' event
            xhr.upload.addEventListener('progress', function(evt) {

              if (evt.lengthComputable) {
                pacDone = true;
                console.log(pacDone + "Test event");
              }
            }, false);
            return xhr;
          }
        });
      }
    });
}

// Check user's answers for third step before go to the fourth and last step of formular.
function goFourthStep(){

  nbh2 = document.getElementById('nbH2').value;
  nbparcelles = document.getElementById('nbParc').value;
  typeOfSol = [];

  typeOfSol.push(document.getElementById('zoneVulnerableIn').checked);
  typeOfSol.push(document.getElementById('zoneProtegeeIn').checked);
  typeOfSol.push(document.getElementById('natura2000In').checked);

  console.log(pacDone);
  console.log(nbh2);
  console.log(nbparcelles);
  console.log(typeOfSol);
  console.log(pacFile);
  console.log("Le pacdone est de:"+ pacDone);

  if(pacDone == true){
    if(isNaN(nbh2) == false){
      if(isNaN(nbparcelles) == false){
        document.getElementById('thirdStep').style.display = 'none';
        proceedFourthStep();
      }else{
        alert("Vous n'avez pas renseigné votre nombre de parcelles!");
      }
    }else{
      alert("Vous n'avez pas renseigné votre nombre d'hectares");
    }
  }else{
    alert("Vous n'avez pas renseigné votre déclaration PAC!");
  }

}

function proceedFourthStep(){
  console.log('in fourth step');
  parcCount++;
  if(parcCount == nbparcelles){
    document.getElementById('finalizeForm').style.display = 'block';
    document.getElementById('NextParc').style.display = 'none';
    finalParc = true;
  }

  
     

  document.getElementById('emptyTitleParc').innerHTML = "Parcelle n°"+parcCount;

  document.getElementById('fertFarmStar').value = '';
  document.getElementById('anaSol').value = '';
  document.getElementById('bilan').value = '';
  document.getElementById('cartoRdt').value = '';

  document.getElementById('fumure').value = '';
  document.getElementById('rdt').value = '';
  document.getElementById('advdis').value = '';
  document.getElementById('daterecolte').value = '';
  document.getElementById('semoirs').value = '';
  document.getElementById('modeDestruction').value = '';
  document.getElementById('remParcelle').value ='';
  document.getElementById('compactions').value ='';
  document.getElementById('adventices').value ='';
  document.getElementById('maladies').value ='';
  document.getElementById('ravageurs').value ='';

  addEventInputList('fertFarmStar');
  addEventInputList('anaSol');
  addEventInputList('bilan');
  addEventInputList('cartoRdt');
  addEventInputList('fumure');

  var tempDatas = [];
  tempDatas.push(name);
  tempDatas.push(firstname);
  tempDatas.push(number);
  tempDatas.push(parcCount);

  console.log(tempDatas);

  sendUserDataParc(tempDatas);

  document.getElementById('fourthStep').style.display = 'block';
}

     function myFunction(){

    if (document.getElementById('compactionProbleme').checked == true){
       document.getElementById('compactions').style.display = 'block';
    }
    else{
      document.getElementById('compactions').style.display = 'none';
    }

     if (document.getElementById('adventicesProbleme').checked == true){
       document.getElementById('adventices').style.display = 'block';
    }
    else {
      document.getElementById('adventices').style.display = 'none';
    }

     if (document.getElementById('maladiesProbleme').checked == true){
       document.getElementById('maladies').style.display = 'block';
    }
    else {
      document.getElementById('maladies').style.display = 'none';
    }

      if (document.getElementById('ravageursProbleme').checked == true){
       document.getElementById('ravageurs').style.display = 'block';
    }
    else{
      document.getElementById('ravageurs').style.display = 'none';
    }

    
 }


function nextInFourthStep(){
  var dataParc = [];
  var e = document.getElementById("precRot");
  var precRot = e.options[e.selectedIndex].value;
  e = document.getElementById("precRot");
  var nextRot = e.options[e.selectedIndex].value;
  var rdt = document.getElementById('rdt').value;
  var avis = document.getElementById('advdis').value;
  var daterecolte = document.getElementById('daterecolte').value;
  var semoirs= document.getElementById('semoirs').value;
  var modeDestruction= document.getElementById('modeDestruction').value;
  var remParcelle = document.getElementById('remParcelle').value;
  var compactions = document.getElementById('compactions').value;
  var adventices = document.getElementById('adventices').value;
  var maladies = document.getElementById('maladies').value;
  var ravageurs = document.getElementById('ravageurs').value;
   

    if(rdt != '' && rdt != null){
      dataParc.push(precRot);
      dataParc.push(nextRot);
      dataParc.push(fumureName);
      dataParc.push(rdt);
      dataParc.push(avis);
      dataParc.push(fertFarmStarName);
      dataParc.push(anaSolName);
      dataParc.push(bilanNames);
      dataParc.push(cartoRdtName);
      dataParc.push(daterecolte);
      dataParc.push(semoirs);
      dataParc.push(modeDestruction);
      dataParc.push(remParcelle);
      dataParc.push(compactions);
      dataParc.push(adventices);
      dataParc.push(maladies);
      dataParc.push(ravageurs);

      allDatasParc.push(dataParc);


      if(finalParc){
        document.getElementById('fourthStep').style.display = 'none';
        document.getElementById('FinalStep').style.display = 'block';
        ///// TODO, SEND DATAS TO SERVOR
      }else{
        proceedFourthStep();
      }
    }else{
      alert("Vous n'avez pas renseigné vos rendements par h2 sur cette parcelle!");
    }
  }




function addEventInputList(id){
  $('#'+id).on('change', function(){
    var files = $(this).get(0).files;
    if (files.length > 0){
      // create a FormData object which will be sent as the data payload in the
      // AJAX request
      var formData = new FormData();

       if(id == 'fumure'){
        fumure = files[0].name;
      } 
		 if(id == 'fertFarmStar'){
        fertFarmStarName = files[0].name;
      } 
		
       if(id == 'anaSol'){
        anaSolName = files[0].name;
      } else if(id == 'bilan'){
        bilanNames.push(files[0].name);
        if(files.length > 1){
          bilanNames.push(files[1].name);
        }
      } else if(id == 'cartoRdt'){
        cartoRdtName = files[0].name;
      }

      // loop through all the selected files and add them to the formData object
      for (var i = 0; i < files.length; i++) {
        var file = files[i];

        // add the files to formData object for the data payload
        formData.append('uploads[]', file, file.name);
      }

      $.ajax({
        url: '/upload',
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        success: function(data){
        },
        xhr: function() {
          // create an XMLHttpRequest
          var xhr = new XMLHttpRequest();

          // listen to the 'progress' event
          xhr.upload.addEventListener('progress', function(evt) {

            if (evt.lengthComputable) {
              pacDone = true;
            }
          }, false);
          return xhr;
        }
      });
    }
  });
}



