/* Rexx program

   sfadbu.rex
   Base code	02/14/2019
   Revision 1	02/14/2019
   Revision 2   04/25/2019
   Revision 3   04/27/2019
   Revision 4   05/03/2019
   Revision 5   05/05/2019
   Revision 5   05/09/2019
   
   This is a simple homegrown backup utility program. It reads a list of
   high level directories that are to be backed up. It builds the list of
   all subdirectories. If a directory/sub-directory does not exist in the
   target file system it is created. A file list is built for each of the 
   the directories on both the source and target. If the files and their
   attributes do not match, the file is copied. If a file exists on the
   source but not the target it is copied. Messages are written to a log
   file to track program execution.

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

FileInName = 'SourceDirectories.txt'
FileInExcl = 'SourceDirectoriesExclude.txt'
BackupDirectory = 'D:\Asus SyncFolder\@BU\'

/* Now create the log file name using date and time functions.                */

currentTime = time('n')
parse var currentTime currentHour ':' currentMinute ':' currentSecond
currentTime = currentHour || currentMinute || currentSecond
FileOutName = 'Log_' || date('S') || '_' || currentTime || '.txt'
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
FilesCopied = 0

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

/*
  At this point the list of source directories is contained in the 
  sourceDlist stem and the target directories are contained in the
  targetDlist stem.  We will check to see if the target directories
  exist. If they do not, then we will attempt to create the directory.
  If we encounter an error in the create, we will write a message to
  the log file and then terminate the exicution of the program.
*/

do sdirCnt = 1 to dirCount

 sfeRC = SysFileExists(targetDlist.sdirCnt)
 
 if sfeRC = 1 then iterate
 
 smdRC = SysMkDir(targetDlist.sdirCnt)
 
 if smdRC = 0 then
   do
     FoldersCreated = FoldersCreated + 1
	 outTxt = date('S') time('n') targetDlist.sdirCnt 'Folder created'
     logFile~lineout(outTxt)
     iterate
   end	 
 
 outTxt = date('S') time('n') 'Return code from SysMkDir =' smdRC 'for' targetDlist.sdirCnt
 logFile~lineout(outTxt)
 outTxt = date('S') time('n') SysGetErrortext(smdRC)
 logFile~lineout(outTxt)
 outTxt = date('S') time('n') 'End Program Execution'
 logFile~lineout(outTxt)
 exit smdRC
 
end

outTxt = date('S') time('n') 'Number of Directories/Folders created =' FoldersCreated
logFile~lineout(outTxt)

do sdirCount = 1 to dirCount
 
  sourceDlist.sdirCount = sourceDlist.sdirCount || '\*.*'  
  targetDlist.sdirCount = targetDlist.sdirCount || '\*.*'
  
  sfRC = SysFileTree(sourceDlist.sdirCount, SFL, 'F') 
  tfRC = SysFileTree(targetDlist.sdirCount, TFL, 'F')

  if TFL.0 = 0 then
    do
      do cntSFL = 1 to SFL.0
	    parse var SFL.cntSFL . . . . sourceFile
	    sourceFile = strip(sourceFile,'B')
	    parse var sourceFile sDrive '\' targetFile
	    targetFile = BackupDirectory || targetFile
	    sfcRC = SysFileCopy(sourceFile,targetFile)
	    if sfcRC \= 0 then
	      do
	        outTxt = date('S') time('n') 'SysFileCopy Error =' sfcRC sourceFile targetFile
	        logFile~lineout(outTxt)
	        outTxt = date('S') time('n') SysGetErrortext(sfcRC)
	        logFile~lineout(outTxt)
		  end
        else
        do	
          FilesCopied = FilesCopied + 1
          outTxt = date('S') time('n') targetFile 'copied'
          logFile~lineout(outTxt)		  
	    end
	  end
	  iterate
    end
	
/*
  The next code block uses an outer and inner loop to compare the entries in 
  the source and target directories. If the file appears to be a temporary
  file we skip it. The files appear to start with ~. If the source and target
  file names match, we exit the inner loop. If we fall out of the inner loop
  without a match, we check the inner loop control variable to see if it has
  been incremented beyonf the control limit. If it has, then we have a file
  that is in the source file system and not the target file system, so we need
  to construct the target file system path and name and then copy it. If the
  inner control loop variable has not exceeded the inner loop control limit,
  the file names matched and we need to check the other attributes. If they 
  are equal the file does not need to be copied. If we get a mismatch we need
  to opy the file.
*/	

  do oPoint = 1 to SFL.0

    parse var SFL.oPoint sflDate sflTime sflSize sflAttrib sflFname  
    sflFname = strip(sflFname,'B')
    sourceFname = IsoFname(sflFname)
    if left(sourceFname,1) = '~' then iterate
  
    do iPoint = 1 to TFL.0
  
      parse var TFL.iPoint tflDate tflTime tflSize tflAttrib tflFname
      tflFname = strip(tflFname,'B')
      targetFname = IsoFname(tflFname)

    if sourceFname = targetFname then leave iPoint
  
    end iPoint
  
    if iPoint = TFL.0 + 1 then
      do
	    parse var SFL.oPoint . . . . sourceFile
	    sourceFile = strip(sourceFile,'B')
	    parse var sourceFile sDrive '\' tflFname
	    tflFname = BackupDirectory || tflFname
	    sfcRC = SysFileCopy(sflFname,tflFname)
	    FilesCopied = FilesCopied + 1
		outTxt = date('S') time('n') tflFname 'copied'
        logFile~lineout(outTxt)
        iterate	
      end
  
  if sourceFname = targetFname & ,
   sflDate = tflDate & sflTime = tflTime & sflSize = tflSize then
     iterate
  else
    do
	  sfdRC = SysFileDelete(tflFname)
	  sfcRC = SysFileCopy(sflFname,tflFname)
      FilesCopied = FilesCopied + 1
      outTxt = date('S') time('n') tflFname 'copied'
      logFile~lineout(outTxt)	  
	  iterate
    end

  end oPoint  
  
end sdirCount

outTxt = date('S') time('n') 'Number of Files copied =' FilesCopied
logFile~lineout(outTxt)

outTxt = date('S') time('n') 'End program execution'
logFile~lineout(outTxt)

logFile~close
inTXTfile~close

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