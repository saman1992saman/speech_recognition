function baseProgram(methodName, V)

%% Initial Setting
numState = 5;
numMixture = 16;
vectorSize = 39;
phoneNumber = 31;
modelPath = 'models\';

methodName = ['monophone_39MFCC_16GMM_Train-Adapt']

% V = eye(39)
speechDataPath = 'Speechdata\\';
spcPath = 'spc\\';
LabelFilesListPHN = 'labels\lablefileslist.phn';
zLabelFilesListPHNsp = 'labels\lablefileslist.phn_sp';
TrainFileListMFC = 'scripts\train_mfc.scp';
TrainFileNameList = 'lib\file_mfc.txt';
scriptPath = 'SCRIPTS\\';
configPathName1 = 'lib\MFCC_config.txt'; 
configPathName2 = 'lib\MFCC_config2.txt'; 
phoneme = {'i', 'e', 'a', 'u', 'o', 'aa', 'sil', 'b', 'p', 'd' ,'t', 'g', 'k' ,'q' ,'gs', 'j', 'ch', 'zh' ,'sh', 'h', 'm', 'n', 'r', 'l', 'y', 'v', 'f' ,'kh', 's', 'z','sp'} 
accents = {'esfahani','jonubi','shomali','tehrani','torki'}


%%
% HLEd_Command = ['HLEd -A -D -T 1  edit.hed labels\testPhones0.mlf']; 
% dos(HLEd_Command)
% HLEd_Command = ['HLEd -A -D -T 1 -n labels\triphones1 mk',LRT,'.led ',trainMlfPath]; 
% dos(HLEd_Command)

%% Feature Extraction
trainScript = 'SCRIPTS\TrainClean_HCopy_.scp';
HCopyCommand_train = ['HCopy -T 1 -C ', configPathName1, ' -S ', trainScript ];
dos(HCopyCommand_train)
display ('Features of TRAIN files are being extracted successfully.');
CMVN('SCRIPTS\TrainClean.scp');
[a b c d e] = readhtk('speechdata\train\esfahani\esfahani1-20.mfc')
% 
testScript = 'SCRIPTS\TestClean_HCopy_.scp';
HCopyCommand_test = ['HCopy -T 1 -C ', configPathName1, ' -S ', testScript ];
dos(HCopyCommand_test)
display ('Features of TEST files are being extracted successfully.');
CMVN('SCRIPTS\TestClean.scp');

%% Create Model Directories
mkdir(['result\',methodName]);
mkdir(['models\',methodName]);
mkdir(['models\',methodName,'\phone0']);
mkdir(['models\',methodName,'\phone1']);
mkdir(['models\',methodName,'\hmmAdapt']);
mkdir(['models\',methodName,'\hmmAdapt2']);
for i = 1:20
    mkdir(['models\',methodName,'\hmm',int2str(i)]);
end

protoNamePath = [modelPath,methodName,'/phone0/proto.mod'];
createproto('proto',numState,numMixture,vectorSize,protoNamePath,e);

%% HInit
trainMlfPath = 'labels\trainPhones0.mlf';
scriptPathName = 'Scripts\Train-Adapt.scp'
protoNamePath = [modelPath,methodName,'\phone0\proto.mod'];
newModelPath = strcat(modelPath, methodName,'\phone0');
for k = 1:phoneNumber
    HInitCommand = ['HInit -A -T 1  -l ', phoneme{k}, ' -o ', phoneme{k}, ' -M ', newModelPath,' -I ',trainMlfPath,' -S ', scriptPathName, ' ', protoNamePath];
    dos(HInitCommand);
end

%% HRest
preModelPath = strcat(modelPath, methodName,'\\phone0\\');
newModelPath = strcat(modelPath, methodName,'\\phone1');
for k =1:phoneNumber
    HRestCommand = ['HRest -A -T 1  -l ', phoneme{k}, ' -M ', newModelPath,' -I ',trainMlfPath,' -S ', scriptPathName,' ', preModelPath, phoneme{k} ];
    dos(HRestCommand);
end

%
%% HCompV
protoNamePath = [modelPath,methodName,'\phone0\proto.mod'];
preModelPath = strcat(modelPath, methodName,'\\phone0\\');
newModelPath = strcat(modelPath, methodName,'\\phone1');
HCompVCommand = ['HCompV -A -T 1 -C ',configPathName2,' -f 0.01 -m -S ', scriptPathName, ' -M ', newModelPath, ' -I ',trainMlfPath,' ', protoNamePath];
dos(HCompVCommand);

copyCommand = ['copy lib\macros ', modelPath, methodName, '\phone1\macros'];
dos( copyCommand );

macroFilePathName = [modelPath, methodName,'\phone1\macros'];
vfloorFilePathName = [modelPath, methodName,'\phone1\vFloors'];

mergeMacroVFloor(macroFilePathName, vfloorFilePathName)

delCommand = ['del ', modelPath, methodName, '\phone1\proto'];
dos( delCommand );

modelsPath = [modelPath, methodName, '\'];
MergeModels(modelsPath, phoneme,phoneNumber,'hmm');

%% HEREST
macroFilePathName = [modelPath, methodName,'\phone1\macros'];
hmmdefsFilePathName = [modelPath, methodName,'\phone1\hmmdefs'];
preModelPath = strcat(modelPath, methodName,'\\phone1');
newModelPath = strcat(modelPath, methodName,'\\hmm1');
HERestCommand1 = ['HERest -A -T 1 -d ', preModelPath, ' -C ',configPathName2,' -I ',trainMlfPath,' -t 250.0 150.0 1000.0 -S ', scriptPathName,' -H ', macroFilePathName, ' -H ',hmmdefsFilePathName, ' -M ', newModelPath, ' monophones1 '];
dos( HERestCommand1 );

for hmmNum = 2:3
    preModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum-1));
    newModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum));
    hmmdefsFilePathName=strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\hmmdefs');
    macroFilePathName = strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\macros');
    HERestCommand2 = ['HERest -A -T 1 -d ',preModelPath,' -C ',configPathName2,' -I ',trainMlfPath,' -t 250.0 150.0 1000.0 -S ', scriptPathName, ' -H ', macroFilePathName, ' -H ', hmmdefsFilePathName, ' -M  ', newModelPath, ' monophones1 '];
    dos(HERestCommand2);
    display (['--- HERest ',int2str(hmmNum),' is done successfully ---'])
end
% 
% copyCommand = ['copy models\', methodName,'\hmm3\hmmdefs models\hmm3\hmmdefs'];
% dos( copyCommand );
% perl DuplicateSilence.pl models\hmm3\hmmdefs > models\hmm4\hmmdefs;
% copyCommand = ['copy  models\hmm4\hmmdefs models\', methodName,'\hmm4\hmmdefs'];
% dos( copyCommand );
% 
% copyCommand = ['copy models\', methodName,'\hmm3\macros models\', methodName,'\hmm4\macros'];
% dos( copyCommand );
% HHEdCommand = ['HHEd -A -T 1 -H models\', methodName,'\hmm4\macros -H models\', methodName,'\hmm4\hmmdefs -M models\', methodName,'\hmm5 sil.hed monophones1'];
% dos( HHEdCommand );

%% Train phones1 SP
for hmmNum = 4:15
    preModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum-1));
    newModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum));
    hmmdefsFilePathName=strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\hmmdefs');
    macroFilePathName = strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\macros');
    HERestCommand2 = ['HERest -A -T 1 -d ',preModelPath,' -C ',configPathName2,' -I ',trainMlfPath,' -t 250.0 150.0 1000.0 -S ', scriptPathName, ' -H ', macroFilePathName, ' -H ', hmmdefsFilePathName, ' -M  ', newModelPath, ' monophones1 '];
    dos(HERestCommand2);
    display (['--- HERest ',int2str(hmmNum),' is done successfully ---'])
end
%% Building word network
% HParse_Command = ['HParse dictionary\phsyn dictionary\phnet']
% dos(HParse_Command)

%% HVITE
for Acc=1:5
    HViteCommand = ['HVite -A -o N -C ',configPathName2,' -H models\', methodName,'\hmm15\hmmdefs -S scripts\Test-',accents{Acc},'.scp -i result\', methodName,'\Monophone_recout.mlf -w dictionary\phnet -s 2.0 -p -25.0 dictionary\phDict monophones1 > result\', methodName,'\Monophone_hvite.log']
    dos( HViteCommand );
    HResultCommand = ['HResults -A -t -I labels\testPhones0.mlf monophones0 result\', methodName,'\Monophone_recout.mlf > result\',methodName,'\monophone-hresult.txt'];
    dos( HResultCommand ); 
    
    [p2(Acc) q2(Acc)] = Correctness(['result\',methodName,'\monophone-hresult.txt'])
end

%%
HLstatsCommand = ['HLStats -b Dictionary\phoneLM.txt -o monophones0 labels\trainPhones0.mlf']
dos(HLstatsCommand)
HViteCommand = ['HVite -A -o N -C ',configPathName2,' -H models\', methodName,'\hmm15\hmmdefs -S scripts\TestClean.scp -i result\', methodName,'\Monophone_recout.mlf -w dictionary\phoneLM.txt -s 2.0 -p -25.0 dictionary\phDict monophones1 > result\', methodName,'\Monophone_hvite.log']
dos( HViteCommand );
HResultCommand = ['HResults -A -t -I labels\testPhones0.mlf monophones0 result\', methodName,'\Monophone_recout.mlf > result\',methodName,'\monophone-hresult.txt'];
dos( HResultCommand ); 
