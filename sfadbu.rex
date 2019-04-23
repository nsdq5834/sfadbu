/* Rexx program

   sfadbu.rex
   Base code	02/14/2019
   Revision 1	02/14/2019

   This is a special function Rexx program that is used to make backup
   copies of the Quicken database. We will make two copies to two dif-
   ferent locations. We get a list of the files in the Quicken backup
   directory/folder and if a file in the source location does not exist
   in the target location, then we will make a copy.
   
   When this operation is complete, we make a copy of the KeePass data-
   base to the two locations as well.
   
   Set up some variables to make it easier to alter both the source and
   target locations as well as the file search pattern.
*/
   
/*	Use the SysFileTree function to obtain the contents of the source and
    two target directories. The results are placed into STEM variables
    which will allow us to loop through the file lists.
*/

/*say "Input file name:" 
pull FileInName  */

FileInName = 'SourceDirectories.txt'

inTXTfile = .stream~new(FileInName)

dCount=0
dirList. = ''

signal on notready name eofAllDone

/* Loop through the file reading the list of directories to be backed up     */

do forever
  inBuff = inTXTfile~linein
  dCount = dCount + 1
  DirToBackup.dCount = strip(inBuff,"B")
end

eofAllDone:

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

/*
  Sort the list of directories in dirList into ascending order.
*/

do oPoint = 1 to dirCount - 1
  do iPoint = oPoint+1 to dirCount
    if dirList.oPoint > dirList.iPoint then
      do
	    tempDir = dirList.oPoint
	    dirList.oPoint = dirList.iPoint
	    dirList.iPoint = tempDir
	  end  
  end iPoint
end oPoint

/*
  Build the list of source and target directories.
*/

sourceDlist. = ''
targetDlist. = ''

do sdirCount = 1 to dirCount
  sourceDlist.sdirCount = dirList.sdirCount
  parse var dirList.sdirCount tDrive '\' targetDlist.sdirCount
  targetDlist.sdirCount = 'D:\Asus SyncFolder\@BU\' || targetDlist.sdirCount
end

/*
  First step is to check and see if the target directory exists. If it does not
  we will attempt to create it.
  Next step is to create the needed file patterns to obtain a list of files in
  both the source and target directory.  If there are no files in the target
  directory we just created it and need to copy all the files from the source.
    
*/

do sdirCount = 1 to dirCount

  tfRC = SysFileExists(targetDlist.sdirCount)
  if tfRC = 0 then
  do
    tfRC = SysMkDir(targetDlist.sdirCount)
	if tfRC \= 0 then
	  say 'Return code from SysMkDir =' tfRC 'for' targetDlist.sdirCount
  end
  
  sourceDlist.sdirCount = sourceDlist.sdirCount || '\*.*'  
  targetDlist.sdirCount = targetDlist.sdirCount || '\*.*'
  
  sfRC = SysFileTree(sourceDlist.sdirCount, SFL, 'F') 
  tfRC = SysFileTree(targetDlist.sdirCount, TFL, 'F')
  
  if TFL.0 = 0 then
    do cntSFL = 1 to SFL.0
	  parse var SFL.cntSFL . . . . sourceFile
	  sourceFile = strip(sourceFile,'B')
	  parse var sourceFile sDrive '\' targetFile
	  targetFile = 'D:\Asus SyncFolder\@BU\' || targetFile
	  cpRC = SysFileCopy(sourceFile,targetFile)
	  if cpRC \= 0 then say 'SysFileCopy Error =' cpRC sourceFile targetFile
	  leave sdirCount
	end 

  do oPoint = 1 to SFL.0
  
    parse var SFL.oPoint sflDate sflTime sflSize sflAttrib sflFname
	
	sourceFname = IsoFname(sflFname)
	sflFname = strip(sflFname,'B')
	
    do iPoint = 1 to TFL.0
	
	  parse var TFL.iPoint tflDate tflTime tflSize tflAttrib tflFname
	  targetFname = IsoFname(tflFname)
	  
	  tflFname = strip(tflFname,'B')
	  
	  if  sourceFname = targetFname & ,
	     (sflSize \= tflSize | sflDate \= tflDate | sflTime \= tflTime) then
		   
		do  
		    sfdRC = SysFileDelete(tflFname)
			
			if sfdRC \= 0 then
			  do
			    say 'SysFileDelete Error ' tflFname sfdRC SysGetErrortext(sfdRC)
			    leave oPoint
			  end 
			  
		    sfcRC = SysFileCopy(sflFname,tflFname)
			say sflFname tflFname
			
			if sfcRC \= 0 then
			  do
			    say 'SysFileCopy Error' sflFname tflFname sfcRC SysGetErrortext(sfcRC)
				leave oPoint
		      end		  		  
        
		end
		
    end iPoint
	
	sfcRC = SysFileCopy(sflFname,tflFname)
	
	if sfcRC \= 0 then
	  say 'SysFileCopy Error' sflFname tflFname sfcRC SysGetErrortext(sfcRC)
	
  end oPoint	
  
  
end sdirCount

/*
   Loop through the source names. If we do not find the source name
   in the target list, then the file needs to be copied.
   We will do this twice because we are making two copies of the backup
   files to two different locations.
   
   We will use the SysFileCopy function to make our copies. If the file
   already exists in the target location, we will overwrite it.
*/

/*

call SysFileCopy Backup, Q_Data

call SysFileCopy Backup, Archive
*/
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