/**
 *Submitted for verification at Etherscan.io on 2019-02-19
*/

pragma solidity ^0.5.1; 
pragma experimental ABIEncoderV2;

contract MediChain {

struct Hosp { 
    
string hospName;
string hospLocAddress; 
uint id;

}

struct Patient { 
    
string patientName;
uint id;
uint hospId;
uint doctorId;

}


struct Doctor{
    
string doctorName;
uint id;
uint hospId;

}



mapping (uint => Hosp) hosp; 
mapping (uint => Patient) patients;
mapping (uint => Doctor) doctors;

uint[] public hospIds; 
uint[] public patientIds;
uint[] public doctIds;

uint _patientAutoId=0;
uint _hospAutoId=0;
uint _doctsAutoId=0;

string[] pName;


//set hospital
function setHosp( string memory _hospName, string memory _hospLocAddress) public {
    
    _hospAutoId+=1;
    
    hosp[_hospAutoId].hospName=_hospName;
    hosp[_hospAutoId].hospLocAddress=_hospLocAddress;
    hosp[_hospAutoId].id=_hospAutoId;
    
    hospIds.push(_hospAutoId); 

} 

//set patient
 function setPatient( uint _hospId, string memory _patientName) public {
    
    _patientAutoId+=1;
    
    patients[_patientAutoId].patientName=_patientName;
    patients[_patientAutoId].hospId=_hospId;
    patients[_patientAutoId].id=_patientAutoId;
    
    patientIds.push(_patientAutoId); 

}

//set Doctor

function setDoctor(uint _hospId, string memory _doctName) public {
    
    _doctsAutoId+=1;
    
    doctors[_doctsAutoId].doctorName=_doctName;
    doctors[_doctsAutoId].hospId=_hospId;
    doctors[_doctsAutoId].id=_doctsAutoId;
    
    doctIds.push(_doctsAutoId); 

}


//get single patient (id,patientNam,hospID)
function getPatient(uint _id) view public returns(string memory,uint,uint){
    
    return (patients[_id].patientName,patients[_id].hospId,patients[_id].id);
    
}

//get single hospital (hospName,hospAddress,hospID)
function getHospital(uint _id) view public returns(string memory,string memory,uint){ 
    
return (hosp[_id].hospName,hosp[_id].hospLocAddress,hosp[_id].id); 

} 

//get single doctor  (doctorName,doctId,hospId)

function getDoctor(uint _id) view public returns(string memory,uint,uint){ 
    
return (doctors[_id].doctorName,doctors[_id].id,doctors[_id].hospId); 

} 



function getHospitalPatients(uint _id) public returns(string[] memory pNamee){
    
    
     for(uint i =1; i<=patientIds.length; i++){
         
        if(patients[i].hospId==_id){
            
            pName.push(patients[i].patientName);
            
             
         }
           
       }
       
       if(pName.length<=0){
                  revert('Patient not found');

       }else{
    
                return pName;           
       }
    

}



//get total hospital
function getHospitalCount() view public returns(uint) { 
    
return hospIds.length;

} 

//get total Patient
function getPatientCount() view public returns(uint) { 
    
return patientIds.length;

}

//get Total doctors

function getDoctorCount() view public returns(uint) { 
    
return doctIds.length;

} 



}
