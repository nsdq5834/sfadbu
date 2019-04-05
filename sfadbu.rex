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
/*trace i */
say "Input file name:"
pull FileInName

inTXTfile = .stream~new(FileInName)

signal on notready name eofAllDone

/* Loop through the input file looking for the securities bought section     */
ii=0
do forever
  inBuff = inTXTfile~linein
  ii = ii + 1
  inDirList.ii = strip(inBuff,"B")
end

eofAllDone:

do jj = 1 to ii
 curDir = inDirList.jj
end


dirCount = 0
call EnumDirect
 
/*call SysFileTree Backup, "SrcQB", "FO"
call SysFileTree Q_Data, "Tg1QB", "FO"
call SysFileTree Archive, "Tg2QB", "FO"
*/
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

EnumDirect: procedure
say dirCount
dirCount = dirCount + 1
dirList.dirCount = curDir
listPat = curDir || "\*.*"
say listPat
call SysFileTree listPat, myDir, "D"

say myDir.0

say curDir
return