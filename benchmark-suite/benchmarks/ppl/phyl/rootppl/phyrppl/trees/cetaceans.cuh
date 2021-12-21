#ifndef cetaceans
#define cetaceans

/*
 * File birds.cuh contains pre-processed phylogenetic trees stored in SoA-format (Structure of Arrays). Taken from the concept paper.
 */

//const int ROOT_IDX = 0;

struct cetaceans_87_tree_t {
	static const int NUM_NODES = 173;
	static const int MAX_DEPTH = 19;
	const floating_t ages[NUM_NODES] =  {35.857844,28,33.799003,8.816019,26.063016,22.044391,32.390661,0,1.622021,0,17.890655,0,8.803018,0.28307,31.621529000000002,0,0.347029,0,16.066685,0,0,0,0,19.195664,26,0,0,15.099324,12.847395,0,18.023412,24.698214,17.939426,5.278071,10.472234,0,11.382958,6.28945,15.669702,0,18.226419,14.061554000000001,10.70277,0,0,0,0,0,5.265325,0,0,0,14.540283,0,0,5.466432,5.6163810000000005,0,9.438013,0,4.322022,11.028304,13.042869,0,0,4.985876,4.94717,8.20905,8.716039,0,0,0,8.100266,0,11.079293,0,3.706276,0,4.045703,0,6.04703,0,8.143058,0,0,0,8.925943,0,0,0,0,0,5.493241,6.975185,7.514394,0,8.252103,0,4.45272,0,5.263495000000001,5.897506,4.355717,0,7.677424,0,3.048675,1.361358,4.570892,0,3.212561,3.44536,3.626115,0,7.176679999999999,0,1.470782,0,0,3.291163,3.791853,0,0,0,0,3.07917,2.83298,4.732448,6.375631,0,0,0,1.821239,0,2.919779,0,2.194413,0,1.934812,0,4.170968,0,5.796587,0,0,0,2.096219,0,0,0,1.506737,0,0,4.927159,5.096384,0,1.570433,1.011163,1.268114,0,0,0,4.166226,0,0,0,0,0,0.924862,0,0,0,0};
	const int idxLeft[NUM_NODES] =  {1,3,5,7,9,11,13,-1,15,-1,17,-1,19,21,23,-1,25,-1,27,-1,-1,-1,-1,29,31,-1,-1,33,35,-1,37,39,41,43,45,-1,47,49,51,-1,53,55,57,-1,-1,-1,-1,-1,59,-1,-1,-1,61,-1,-1,63,65,-1,67,-1,69,71,73,-1,-1,75,77,79,81,-1,-1,-1,83,-1,85,-1,87,-1,89,-1,91,-1,93,-1,-1,-1,95,-1,-1,-1,-1,-1,97,99,101,-1,103,-1,105,-1,107,109,111,-1,113,-1,115,117,119,-1,121,123,125,-1,127,-1,129,-1,-1,131,133,-1,-1,-1,-1,135,137,139,141,-1,-1,-1,143,-1,145,-1,147,-1,149,-1,151,-1,153,-1,-1,-1,155,-1,-1,-1,157,-1,-1,159,161,-1,163,165,167,-1,-1,-1,169,-1,-1,-1,-1,-1,171,-1,-1,-1,-1};
	const int idxRight[NUM_NODES] =  {2,4,6,8,10,12,14,-1,16,-1,18,-1,20,22,24,-1,26,-1,28,-1,-1,-1,-1,30,32,-1,-1,34,36,-1,38,40,42,44,46,-1,48,50,52,-1,54,56,58,-1,-1,-1,-1,-1,60,-1,-1,-1,62,-1,-1,64,66,-1,68,-1,70,72,74,-1,-1,76,78,80,82,-1,-1,-1,84,-1,86,-1,88,-1,90,-1,92,-1,94,-1,-1,-1,96,-1,-1,-1,-1,-1,98,100,102,-1,104,-1,106,-1,108,110,112,-1,114,-1,116,118,120,-1,122,124,126,-1,128,-1,130,-1,-1,132,134,-1,-1,-1,-1,136,138,140,142,-1,-1,-1,144,-1,146,-1,148,-1,150,-1,152,-1,154,-1,-1,-1,156,-1,-1,-1,158,-1,-1,160,162,-1,164,166,168,-1,-1,-1,170,-1,-1,-1,-1,-1,172,-1,-1,-1,-1};
	const int idxParent[NUM_NODES] =  {-1,0,0,1,1,2,2,3,3,4,4,5,5,6,6,8,8,10,10,12,12,13,13,14,14,16,16,18,18,23,23,24,24,27,27,28,28,30,30,31,31,32,32,33,33,34,34,36,36,37,37,38,38,40,40,41,41,42,42,48,48,52,52,55,55,56,56,58,58,60,60,61,61,62,62,65,65,66,66,67,67,68,68,72,72,74,74,76,76,78,78,80,80,82,82,86,86,92,92,93,93,94,94,96,96,98,98,100,100,101,101,102,102,104,104,106,106,107,107,108,108,110,110,111,111,112,112,114,114,116,116,119,119,120,120,125,125,126,126,127,127,128,128,132,132,134,134,136,136,138,138,140,140,142,142,146,146,150,150,153,153,154,154,156,156,157,157,158,158,162,162,168,168};
	const int idxNext[NUM_NODES] =  {1,3,5,7,9,11,13,8,15,10,17,12,19,21,23,16,25,18,27,20,6,22,14,29,31,26,4,33,35,30,37,39,41,43,45,36,47,49,51,40,53,55,57,44,34,46,28,48,59,50,38,52,61,54,32,63,65,58,67,60,69,71,73,64,56,75,77,79,81,70,2,72,83,74,85,76,87,78,89,80,91,82,93,84,62,86,95,88,66,90,42,92,97,99,101,96,103,98,105,100,107,109,111,104,113,106,115,117,119,110,121,123,125,114,127,116,129,118,108,131,133,122,102,124,112,135,137,139,141,130,68,132,143,134,145,136,147,138,149,140,151,142,153,144,120,146,155,148,126,150,157,152,128,159,161,156,163,165,167,160,154,162,169,164,94,166,158,168,171,170,24,172,-1};
};

#endif
