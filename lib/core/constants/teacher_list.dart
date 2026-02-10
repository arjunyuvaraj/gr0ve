// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// Map<String, String> absenceList = {};
// final teacherList = {
//   "Downey, Lindsay": {
//     "name": "Downey, Lindsay",
//     "department": "Biology",
//     "email": "lindow@bergen.org",
//   },
//   "Gomes,  Giselle": {
//     "name": "Gomes,  Giselle",
//     "department": "Biology",
//     "email": "gisgom@bergen.org",
//   },
//   "Pinto, Judith": {
//     "name": "Pinto, Judith",
//     "department": "Biology",
//     "email": "judpin@bergen.org",
//   },
//   "Sabio, German": {
//     "name": "Sabio, German",
//     "department": "Biology",
//     "email": "gersab@bergen.org",
//   },
//   "Smith, Ericka": {
//     "name": "Smith, Ericka",
//     "department": "Biology",
//     "email": "erismi@bergen.org",
//   },
//   "Vollenweider, Daniel": {
//     "name": "Vollenweider, Daniel",
//     "department": "Biology",
//     "email": "danvol@bergen.org",
//   },
//   "Waldron, Alyssa": {
//     "name": "Waldron, Alyssa",
//     "department": "Biology",
//     "email": "alywal@bergen.org",
//   },
//   "Zhang, Eric": {
//     "name": "Zhang, Eric",
//     "department": "Biology",
//     "email": "erizha@bergen.org",
//   },
//   "Gutierrez, Joseph": {
//     "name": "Gutierrez, Joseph",
//     "department": "Business",
//     "email": "josgut@bergen.org",
//   },
//   "Sawhney, Puneet": {
//     "name": "Sawhney, Puneet",
//     "department": "Business",
//     "email": "punsaw@bergen.org",
//   },
//   "Fogg, Fred": {
//     "name": "Fogg, Fred",
//     "department": "Business",
//     "email": "frefog@bergen.org",
//   },
//   // TODO: Crane Edge Case
//   "Crane, Laura": {
//     "name": "Crane, Laura",
//     "department": "Chemistry",
//     "email": "laucra@bergen.org",
//   },
//   "Crane, Todd": {
//     "name": "Crane, Todd",
//     "department": "Chemistry",
//     "email": "todcra@bergen.org",
//   },
//   "Dobrich, Oliver": {
//     "name": "Dobrich, Oliver",
//     "department": "Chemistry",
//     "email": "olidob@bergen.org",
//   },
//   "Feuss, Danielle": {
//     "name": "Feuss, Danielle",
//     "department": "Chemistry",
//     "email": "danfeu@bergen.org",
//   },
//   "Kim, Deok-Yang": {
//     "name": "Kim, Deok-Yang",
//     "department": "Chemistry",
//     "email": "deokim@bergen.org",
//   },
//   "Sorrentino, Elizabeth": {
//     "name": "Sorrentino, Elizabeth",
//     "department": "Chemistry",
//     "email": "elisor@bergen.org",
//   },

//   "Carter, Hank": {
//     "name": "Carter, Hank",
//     "department": "Computer Science",
//     "email": "hancar@bergen.org",
//   },
//   "Isecke, Benjamin": {
//     "name": "Isecke, Benjamin",
//     "department": "Computer Science",
//     "email": "marbon@bergen.org",
//   },
//   "Respass, Bryan": {
//     "name": "Respass, Bryan",
//     "department": "Computer Science",
//     "email": "bryres@bergen.org",
//   },
//   "Sen, Serhat": {
//     "name": "Sen, Serhat",
//     "department": "Computer Science",
//     "email": "sersen@bergen.org",
//   },
//   "Wertz, Richard": {
//     "name": "Wertz, Richard",
//     "department": "Computer Science",
//     "email": "ricwer@bergen.org",
//   },

//   "Drapczynski, Anna": {
//     "name": "Drapczynski, Anna",
//     "department": "Culinary Arts & Hospitality Management",
//     "email": "anndra@bergen.org",
//   },
//   "Donohue, Kaitlin": {
//     "name": "Donohue, Kaitlin",
//     "department": "Culinary Arts & Hospitality Management",
//     "email": "kaidono@bergen.org",
//   },
//   "Jhocson, Jerel": {
//     "name": "Jhocson, Jerel",
//     "department": "Culinary Arts & Hospitality Management",
//     "email": "jerjho@bergen.org",
//   },

//   "Barbetta, Joseph": {
//     "name": "Barbetta, Joseph",
//     "department": "Engineering",
//     "email": "josbar@bergen.org",
//   },
//   "Nodarse, Carlos": {
//     "name": "Nodarse, Carlos",
//     "department": "Engineering",
//     "email": "carnod@bergen.org",
//   },
//   "Samarakone, Victor": {
//     "name": "Samarakone, Victor",
//     "department": "Engineering",
//     "email": "vicsam@bergen.org",
//   },

//   "Beato, Danielle": {
//     "name": "Beato, Danielle",
//     "department": "English",
//     "email": "danbea@bergen.org",
//   },
//   "Crimmel, Michelle": {
//     "name": "Crimmel, Michelle",
//     "department": "English",
//     "email": "miccrim@bergen.org",
//   },
//   "Hessami, Bashira": {
//     "name": "Hessami, Bashira",
//     "department": "English",
//     "email": "bashes@bergen.org",
//   },
//   "Kaba, Valmira": {
//     "name": "Kaba, Valmira",
//     "department": "English",
//     "email": "valkab@bergen.org",
//   },
//   "Molino, Rachel": {
//     "name": "Molino, Rachel",
//     "department": "English",
//     "email": "racmol@bergen.org",
//   },
//   "Rhee, Rachelle": {
//     "name": "Rhee, Rachelle",
//     "department": "English",
//     "email": "racrhe@bergen.org",
//   },
//   "Price-Halligan, Suzanne": {
//     "name": "Price-Halligan, Suzanne",
//     "department": "English",
//     "email": "suzhal@bergen.org",
//   },
//   "Villanova, Donna": {
//     "name": "Villanova, Donna",
//     "department": "English",
//     "email": "donvil@bergen.org",
//   },
//   "Wilson, David": {
//     "name": "Wilson, David",
//     "department": "English",
//     "email": "davwil@bergen.org",
//   },
//   "Xu, Alice": {
//     "name": "Xu, Alice",
//     "department": "English",
//     "email": "alicxu@bergen.org",
//   },

//   "Abramson, Michael": {
//     "name": "Abramson, Michael",
//     "department": "Mathematics",
//     "email": "micabra@bergen.org",
//   },
//   "Bolton, William": {
//     "name": "Bolton, William",
//     "department": "Mathematics",
//     "email": "wilbol@bergen.org",
//   },
//   "Bonanomi, Mark": {
//     "name": "Bonanomi, Mark",
//     "department": "Mathematics",
//     "email": "marbon@bergen.org",
//   },
//   "Casarico, Elizabeth": {
//     "name": "Casarico, Elizabeth",
//     "department": "Mathematics",
//     "email": "elicas@bergen.org",
//   },
//   "Djedji, Jack": {
//     "name": "Djedji, Jack",
//     "department": "Mathematics",
//     "email": "djadje@bergen.org",
//   },
//   "Heitzman, Carla": {
//     "name": "Heitzman, Carla",
//     "department": "Mathematics",
//     "email": "carhei@bergen.org",
//   },
//   "Loh, Sebastian": {
//     "name": "Loh, Sebastian",
//     "department": "Mathematics",
//     "email": "sebloh@bergen.org",
//   },
//   "Ogden, Christine": {
//     "name": "Ogden, Christine",
//     "department": "Mathematics",
//     "email": "chrogds@bergen.org",
//   },
//   "Penev, Krassimir": {
//     "name": "Penev, Krassimir",
//     "department": "Mathematics",
//     "email": "krapen@bergen.org",
//   },
//   "Pinyan, Jonathan": {
//     "name": "Pinyan, Jonathan",
//     "department": "Mathematics",
//     "email": "jonpin@bergen.org",
//   },
//   "Seventko, Justin": {
//     "name": "Seventko, Justin",
//     "department": "Mathematics",
//     "email": "jussev@bergen.org",
//   },
//   "Walsh, Gene": {
//     "name": "Walsh, Gene",
//     "department": "Mathematics",
//     "email": "genwal@bergen.org",
//   },
//   "Zangara, Amy": {
//     "name": "Zangara, Amy",
//     "department": "Mathematics",
//     "email": "amyzan@bergen.org",
//   },
//   "Dale, Jennifer": {
//     "name": "Dale, Jennifer",
//     "department": "Physical Education",
//     "email": "jendal@bergen.org",
//   },
//   "Fuentes, Elizabeth": {
//     "name": "Fuentes, Elizabeth",
//     "department": "Physical Education",
//     "email": "elifue@bergen.org",
//   },
//   "James, Dina": {
//     "name": "James, Dina",
//     "department": "Physical Education",
//     "email": "dinjam@bergen.org",
//   },
//   "Kalata, Greg": {
//     "name": "Kalata, Greg",
//     "department": "Physical Education",
//     "email": "grekal@bergen.org",
//   },
//   "Marmora, Joe": {
//     "name": "Marmora, Joe",
//     "department": "Physical Education",
//     "email": "josmar@bergen.org",
//   },
//   "Symons, Robert": {
//     "name": "Symons, Robert",
//     "department": "Physical Education",
//     "email": "robsym@bergen.org",
//   },

//   "Dogru, Ozgur": {
//     "name": "Dogru, Ozgur",
//     "department": "Physics",
//     "email": "ozgdog@bergen.org",
//   },
//   "Hodroski, William": {
//     "name": "Hodroski, William",
//     "department": "Physics",
//     "email": "wilhid@bergen.org",
//   },
//   "Liva, Michael": {
//     "name": "Liva, Michael",
//     "department": "Physics",
//     "email": "micliv@bergen.org",
//   },
//   "Rangrez, Karen": {
//     "name": "Rangrez, Karen",
//     "department": "Physics",
//     "email": "karran@bergen.org",
//   },
//   "Russo, Christopher": {
//     "name": "Russo, Christopher",
//     "department": "Physics",
//     "email": "chrrus@bergen.org",
//   },
//   "Zubov, Igor": {
//     "name": "Zubov, Igor",
//     "department": "Physics",
//     "email": "igozub@bergen.org",
//   },

//   "Alschen, Sergei": {
//     "name": "Alschen, Sergei",
//     "department": "Social Studies",
//     "email": "serals@bergen.org",
//   },
//   "Blake, Katherine": {
//     "name": "Blake, Katherine",
//     "department": "Social Studies",
//     "email": "katbla@bergen.org",
//   },
//   "Janssen, Katherine": {
//     "name": "Janssen, Katherine",
//     "department": "Social Studies",
//     "email": "katjan@bergen.org",
//   },
//   "Kim, Rosalyn": {
//     "name": "Kim, Rosalyn",
//     "department": "Social Studies",
//     "email": "roskim@bergen.org",
//   },
//   "Kramer, Mark": {
//     "name": "Kramer, Mark",
//     "department": "Social Studies",
//     "email": "markra@bergen.org",
//   },
//   "Lancaster, Jon": {
//     "name": "Lancaster, Jon",
//     "department": "Social Studies",
//     "email": "jonlan@bergen.org",
//   },
//   "Madden, William": {
//     "name": "Madden, William",
//     "department": "Social Studies",
//     "email": "wilmad@bergen.org",
//   },
//   "Mazurek, Gary": {
//     "name": "Mazurek, Gary",
//     "department": "Social Studies",
//     "email": "garmaz@bergen.org",
//   },
//   "Mullally, Karen": {
//     "name": "Mullally, Karen",
//     "department": "Social Studies",
//     "email": "karmul@bergen.org",
//   },
//   "Pagano, Emily": {
//     "name": "Pagano, Emily",
//     "department": "Social Studies",
//     "email": "emipag@bergen.org",
//   },
//   "Wallace, Christine": {
//     "name": "Wallace, Christine",
//     "department": "Social Studies",
//     "email": "chrwal@bergen.org",
//   },

//   "Edwards, Eboni": {
//     "name": "Edwards, Eboni",
//     "department": "Visual & Performing Arts",
//     "email": "eboedw@bergen.org",
//   },
//   "Guthrie, Peter": {
//     "name": "Guthrie, Peter",
//     "department": "Visual & Performing Arts",
//     "email": "petgut@bergen.org",
//   },
//   "Kaplan, Stephen": {
//     "name": "Kaplan, Stephen",
//     "department": "Visual & Performing Arts",
//     "email": "stekap@bergen.org",
//   },
//   "Lang, Scott": {
//     "name": "Lang, Scott",
//     "department": "Visual & Performing Arts",
//     "email": "slang@bergen.org",
//   },
//   "Lemma, Michael": {
//     "name": "Lemma, Michael",
//     "department": "Visual & Performing Arts",
//     "email": "miclem@bergen.org",
//   },
//   "Maks, Natalia": {
//     "name": "Maks, Natalia",
//     "department": "Visual & Performing Arts",
//     "email": "natmak@bergen.org",
//   },
//   "Pero, Victoria": {
//     "name": "Pero, Victoria",
//     "department": "Visual & Performing Arts",
//     "email": "vicper@bergen.org",
//   },
//   "Spinelli, Louis": {
//     "name": "Spinelli, Louis",
//     "department": "Visual & Performing Arts",
//     "email": "louspi@bergen.org",
//   },
//   "Torres, Raul": {
//     "name": "Torres, Raul",
//     "department": "Visual & Performing Arts",
//     "email": "rautor@bergen.org",
//   },
//   "Bian, Fang": {
//     "name": "Bian, Fang ",
//     "department": "World Languages",
//     "email": "fanbia@bergen.org",
//   },
//   "Calandra, Gabriela": {
//     "name": "Calandra, Gabriela",
//     "department": "World Languages",
//     "email": "gabcal@bergen.org",
//   },
//   "Fang, Amy": {
//     "name": "Fang, Amy",
//     "department": "World Languages",
//     "email": "amyfan@bergen.org",
//   },
//   "Fillebrown, Catherine": {
//     "name": "Fillebrown, Catherine",
//     "department": "World Languages",
//     "email": "catfil@bergen.org",
//   },
//   "Lewitt, Julia": {
//     "name": "Lewitt, Julia",
//     "department": "World Languages",
//     "email": "jullew@bergen.org",
//   },
//   "Ponce, Lucia": {
//     "name": "Ponce, Lucia",
//     "department": "World Languages",
//     "email": "lucpon@bergen.org",
//   },
//   "Rivera, Carlos": {
//     "name": "Rivera, Carlos",
//     "department": "World Languages",
//     "email": "carriv@bergen.org",
//   },
//   "Seltzer, Irma": {
//     "name": "Seltzer, Irma",
//     "department": "World Languages",
//     "email": "irmsel@bergen.org",
//   },
//   "Tolmo, Eva": {
//     "name": "Tolmo, Eva",
//     "department": "World Languages",
//     "email": "evatol@bergen.org",
//   },
//   "Torres Perez, Aymee": {
//     "name": "Torres Perez, Aymee",
//     "department": "World Languages",
//     "email": "aymtor@bergen.org",
//   },
//   "Villarosa, Hillary": {
//     "name": "Villarosa, Hillary",
//     "department": "World Languages",
//     "email": "hilvil@bergen.org",
//   },

//   "Sousa, Nancy": {
//     "name": "Sousa, Nancy",
//     "department": "Counseling",
//     "email": "nansou@bergen.org",
//   },
//   "Acuña, Kym": {
//     "name": "Acuña, Kym",
//     "department": "Counseling",
//     "email": "kymacu@bergen.org",
//   },
//   "Andaloro, Jennifer": {
//     "name": "Andaloro, Jennifer",
//     "department": "Counseling",
//     "email": "jenand@bergen.org",
//   },
//   "Belkin, Alison": {
//     "name": "Belkin, Alison",
//     "department": "Counseling",
//     "email": "alibel@bergen.org",
//   },
//   "Libecci, Jennifer": {
//     "name": "Libecci, Jennifer",
//     "department": "Counseling",
//     "email": "jenlib@bergen.org",
//   },
//   "Ripoll, Katie": {
//     "name": "Ripoll, Katie",
//     "department": "Counseling",
//     "email": "katrip@bergen.org",
//   },
//   "Smith, Michael": {
//     "name": "Smith, Michael",
//     "department": "Counseling",

//     "email": "micsmi@bergen.org",
//   },
//   "Kaser, Paul": {
//     "name": "Kaser, Paul",
//     "department": "Counseling",
//     "email": "paukas@bergen.org",
//   },
//   "Paula, Dania": {
//     "name": "Paula, Dania",
//     "department": "Counseling",
//     "email": "danpau@bergen.org",
//   },
//   "Sytsma, Nancy": {
//     "name": "Sytsma, Nancy",
//     "department": "Counseling",
//     "email": "nansyt@bergen.org",
//   },
//   "Pantaleo, Jill": {
//     "name": "Pantaleo, Jill",
//     "department": "Counseling",
//     "email": "donchi@bergen.org",
//   },
//   "Chippa, Donna": {
//     "name": "Chippa, Donna",
//     "department": "Counseling",
//     "email": "donchi@bergen.org",
//   },
// };

// /// Simple function to upload teachers to Firebase
// /// Call this ONCE from anywhere in your app (like a button press)
// ///
// /// Usage:
// /// await uploadTeachersToFirebase();
// Future<void> uploadTeachersToFirebase() async {
//   final firestore = FirebaseFirestore.instance;

//   try {
//     int count = 0;

//     // Loop through each teacher in the existing teacherList
//     for (final entry in teacherList.entries) {
//       final teacherData = entry.value;
//       final name = teacherData['name'] as String;
//       final department = teacherData['department'] as String;
//       final email = teacherData['email'] as String;

//       // Upload to Firebase - use the name as the document ID
//       await firestore.collection('teachers').doc(name).set({
//         'name': name,
//         'department': department,
//         'email': email,
//       });

//       count++;

//       if (kDebugMode) {
//         print('Uploaded $count: $name');
//       }
//     }

//     if (kDebugMode) {
//       print('✅ Successfully uploaded $count teachers to Firebase!');
//     }
//   } catch (e) {
//     if (kDebugMode) {
//       print('❌ Error uploading teachers: $e');
//     }
//     rethrow;
//   }
// }
