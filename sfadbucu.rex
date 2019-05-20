/* Rexx program

   sfadbucu.rex
   Base code	05/18/2019
   
   This is a simple homegrown backup utility program that is used in con-
   junction with sfadbu. sfadbucu is a clean up utility progam that can be
   executed at whatever frequency is needed. It compares the contents of the
   target or backup to the source. If a file is present in the target and not
   in the source it will be deleted from the target.

   See if we were passed an argument.  If so, see if it is equal to the
   word debug. If it is, set a logic flag that we will use to control the
   messages we will write to our log file.   

   Next identify the input file that contains the list of the base
   directories/folders that we want to make backups from. Create a unique
   file name that we can use for our log file that will track the programs
   execution.
*/
debugFlag = 0

arg passedValue

if passedValue = 'DEBUG' then
  debugFlag = 1

ConfigFileName = 'config.txt'

if \ SysFileExists(ConfigFileName) then
  do
    say 'Unable to locate config.txt'
	say 'Terminating program execution.'
	exit sfeRC
  end

configFile = .stream~new(ConfigFileName)
configFile~open('READ')

/*
  Loop through the configuration file picking up parameters. If we encounter
  an unknown keyword we will issue a message and exit the program.
*/

do while configFile~lines \= 0

  inBuff = strip(configFile~linein,'B')
  parse var inBuff parmDir '=' parmValue
  parmDir = strip(parmDir,'B')
  parmValue = strip(parmValue,'B')
  
  select
    when parmDir = 'FileInName' then
	  FileInName = parmValue
	when parmDir = 'FileInExcl' then
	  FileInExcl = parmValue
	when parmDir = 'BackupDirectory' then
	  BackupDirectory = parmValue
	otherwise
	  do
	    say 'Unrecognized configuration keyword **' inBuff '**'
		configFile~close
		exit 1000
	  end
  end
  
end

/*
  Make sure that each of the files exist.
*/

if \ SysFileExists(FileInName) then
  do
    say 'Unable to locate ' FileInName
	say 'Terminating program execution.'
	exit 1000
  end

if \ SysFileExists(FileInExcl) then
  do
    say 'Unable to locate ' FileInExcl
	say 'Terminating program execution.'
	exit 1000
  end

if \ SysFileExists(BackupDirectory) then
  do
    say 'Unable to locate ' BackupDirectory
	say 'Terminating program execution.'
	exit 1000
  end

/* Now create the log file name using date and time functions.                */

currentTime = time('n')
parse var currentTime currentHour ':' currentMinute ':' currentSecond
currentTime = currentHour || currentMinute || currentSecond
FileOutName = 'Log_cu_' || date('S') || '_' || currentTime || '.txt'
FileOutName = 'C:\SFADBU\' || FileOutName

/*
  Set up the stream objects so that we can then use them to access the
  underlying files.
*/

inTXTfile = .stream~new(FileInName)
inEXCfile = .stream~new(FileInExcl)
logFile = .stream~new(FileOutName)

logFile~open('WRITE')

outTxt = date('S') time('n') 'Begin program execution'
logFile~lineout(outTxt)

/* Open our two input files.                                                  */

inTXTfile~open('READ')
inEXCfile~open('READ')

/* initialize some variables.                                                 */

dCount = 0
eCount = 0
dirList. = ''
DirToExclude. = ''
DirToBackup. = ''
FoldersCreated = 0
FilesDeleted = 0

/* Loop through the file reading the list of directories to be excluded.      */

do while inEXCfile~lines \= 0
  inBuff = inEXCfile~linein
  eCount = eCount + 1
  DirToExclude.eCount = strip(inBuff,"B")
end

inEXCfile~close

/* Loop through the file reading the list of directories to be backed up. We 
   will check the exclude list as we build our list of directories to be backed
   up.
*/

do while inTXTfile~lines \= 0
  inBuff = inTXTfile~linein
  dCount = dCount + 1
  DirToBackup.dCount = strip(inBuff,"B")
end  

inTXTfile~close

/*
  Write a message to the log detailing the base number of directories we are
  going to try to process.
*/

outTxt = date('S') time('n') 'Number of base directories to process =' dCount
logFile~lineout(outTxt)
outTxt = date('S') time('n') 'Number directories to exclude =' eCount
logFile~lineout(outTxt)


/* Set initial directory count to zero.
   Call the EnumDirect routine to obtain a list of any subdirectories.
   When we complete this loop, the dirList stem should contail a list
   of all the directories as well as the subdirectories.   
*/

dirCount = 0

do dPoint = 1 to dCount
 curDir = DirToBackup.dPoint
 call EnumDirect
end

DirToBackup. = dirList.
dirList. = ''

dPoint = 0

do basePoint = 1 to dirCount
  AddFileToBackup = 1 
  do exclPoint = 1 to eCount
    if DirToBackup.basePoint = DirToExclude.exclPoint then
	  do
	    AddFileToBackup = 0
		leave exclPoint
	  end
  end exclPoint
  if AddFileToBackup then
    do
	  dPoint = dPoint + 1
	  dirList.dPoint = DirToBackup.basePoint
	end
end basePoint

/*
  Write a message to the log detailing the total number of directories that we
  are going to try to process.  At this point, the dirList stem variable con-
  tains the list of source directories and dirCount contains the number of
  source directories.
*/

outTxt = date('S') time('n') 'Total # directories to process =' dPoint
logFile~lineout(outTxt)

dirCount = dPoint

if debugFlag then
  do
    do dPoint = 1 to dirCount
      outTxt = date('S') time('n') dirList.dPoint
      logFile~lineout(outTxt)
   end dPoint
  end 

/*
  Build the list of source and target directories we will process.
*/

outTxt = date('S') time('n') 'Build target directory list'
logFile~lineout(outTxt)

sourceDlist. = ''
targetDlist. = ''

do sdirCnt = 1 to dirCount
  sourceDlist.sdirCnt = dirList.sdirCnt
  parse var dirList.sdirCnt tDrive '\' targetDlist.sdirCnt
  targetDlist.sdirCnt = BackupDirectory || targetDlist.sdirCnt
end sdirCnt

outTxt = date('S') time('n') 'Target directory list build complete'
logFile~lineout(outTxt)

/*
  Output the list of target directories that we will attempt to process.
*/

if debugFlag then
  do
    do sdirCnt = 1 to dirCount
      outTxt = date('S') time('n') targetDlist.sdirCnt
      logFile~lineout(outTxt)
    end sdirCnt
  end

do sdirCount = 1 to dirCount
 
  sourceDlist.sdirCount = sourceDlist.sdirCount || '\*.*'  
  targetDlist.sdirCount = targetDlist.sdirCount || '\*.*'
  
  sfRC = SysFileTree(sourceDlist.sdirCount, SFL, 'F') 
  tfRC = SysFileTree(targetDlist.sdirCount, TFL, 'F')

  do oPoint = 1 to TFL.0
  
    parse var TFL.oPoint tflDate tflTime tflSize tflAttrib tflFname  
    tflFname = strip(tflFname,'B')
    targetFname = IsoFname(tflFname)
	
    do iPoint = 1 to SFL.0
	
      parse var SFL.iPoint dflDate sflTime sflSize sflAttrib sflFname
      sflFname = strip(sflFname,'B')
      sourceFname = IsoFname(sflFname)
	  if targetFname = sourceFname then leave iPoint
	  
	end iPoint
	
	if iPoint = SFL.0 + 1 then
	  do
	    SysFileDelete(tflFname)
		FilesDeleted = FilesDeleted + 1
		outTxt = date('S') time('n') 'Deleted' tflFname
        logFile~lineout(outTxt)
	  end	
	
  end oPoint  

end sdirCount

/*
  Issue final messages and close up the log file and then exit.
*/

outTxt = date('S') time('n') 'Number of Files deleted =' FilesDeleted
logFile~lineout(outTxt)

outTxt = date('S') time('n') 'End program execution'
logFile~lineout(outTxt)

logFile~close

exit

/*
  The EnumDirect procedure is used to obtain the list of all directories
  within the directory whose name is in curDir. dirCount, curDir and the
  stem dirList. are all exposed so that their values are availble across
  the entire program scope. The routine is also called recursively.
*/

EnumDirect: procedure expose dirCount curDir dirList.

dirCount = dirCount + 1
dirList.dirCount = curDir
sourcePat = curDir || "\*.*"

call SysFileTree sourcePat, myDir, "D"

if myDir.0 > 0 then

  do KK = 1 to myDir.0
    parse var myDir.KK . . . . curDir
	curDir = strip(curDir,'B')
    call EnumDirect
  end

return

/*
  The IsoFname function takes a fully qualified file name and strips off the
  path information so we are left with the simple file name.
*/

IsoFname: procedure

arg FullFileName
OnlyFileName = ''

FullFileName = strip(FullFileName,'B')
lengthFFN = length(FullFileName)
lengthFFN1 = lengthFFN

do pointFFN = lengthFFN to 1 by -1


  if substr(FullFileName,pointFFN,1) = '\' then
    do
	  lengthFFN1 = lengthFFN1 - pointFFN
	  pointFFN1 = pointFFN + 1
	  OnlyFileName = substr(FullFileName,pointFFN1,lengthFFN1)
	  leave
	end
	
end pointFFN

return OnlyFileName
