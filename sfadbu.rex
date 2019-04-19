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

/* Set initial directory count to zero.                                      */

dirCount = 0

do dPoint = 1 to dCount
 curDir = DirToBackup.dPoint
 call EnumDirect
end

/*
  At this point we have the base list of directories as well as any sub-
  directories that are to be backed up.  The next step is to build the necessary
  search patterns so that we can get a list of files in the source and targetdirectories.
*/

sourceDlist. = ''
targetDlist. = ''

do sdirCount = 1 to dirCount
  sourceDlist.sdirCount = dirList.sdirCount || '\*.*'
  parse var dirList.sdirCount tDrive '\' targetDlist.sdirCount
  targetDlist.sdirCount = 'D:\Asus Sync Folder\@BU\' || targetDlist.sdirCount || '\*.*'
  say sourceDlist.sdirCount '->' targetDlist.sdirCount
end

/*
  We now have the source and target fine name patterns built. Next step is to obtain
  a full listing from each directory/folder and then we can compare the lists to de-
  termine which files will need to be backed up.
*/

do sdirCount = 1 to dirCount
  sourcePat = dirList.sdirCount || '\*.*'
  call SysFileTree sourcePat, SourceFile, "F"
  
  if SourceFile.0 > 0 then
    do SF = 1 to SourceFile.0
	  parse var SourceFile.SF . . . . curSource .
	  parse var curSource tDrive '\' TargetFile
	  TargetFile = 'D:\Asus Sync Folder\@BU\' || TargetFile	  
	end
end

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


EnumDirect: procedure expose dirCount curDir dirList.

dirCount = dirCount + 1
dirList.dirCount = curDir
sourcePat = curDir || "\*.*"

call SysFileTree sourcePat, myDir, "D"

if myDir.0 > 0 then

  do KK = 1 to myDir.0
    parse var myDir.KK . . . . curDir . 
    call EnumDirect
  end

return