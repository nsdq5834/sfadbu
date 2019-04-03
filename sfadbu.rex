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
   


SourceDirectory = "C:\Quicken Backup\"
TargetDirectory1 = "C:\Users\Bill\Google Drive\Q_Data\"
TargetDirectory2 = "D:\Asus SyncFolder\Financial\Quicken Archive\"

FilePattern = "*.QDF"

Backup = SourceDirectory || FilePattern
Q_Data = TargetDirectory1 || FilePattern
Archive = TargetDirectory2 || FilePattern

/*	Use the SysFileTree function to obtain the contents of the source and
    two target directories. The results are placed into STEM variables
    which will allow us to loop through the file lists.
*/

call SysFileTree Backup, "SrcQB", "FO"
call SysFileTree Q_Data, "Tg1QB", "FO"
call SysFileTree Archive, "Tg2QB", "FO"

/*
   Loop through the source names. If we do not find the source name
   in the target list, then the file needs to be copied.
   We will do this twice because we are making two copies of the backup
   files to two different locations.
   
   We will use the SysFileCopy function to make our copies. If the file
   already exists in the target location, we will overwrite it.
*/

do i = 1 to SrcQB.0

  parse var SrcQB.i . "\" . "\" Src1
  
  SRCtoTGT = 1
  
  do j = 1 to Tg1QB.0
    
    parse var Tg1QB.j . "\" . "\" . "\" . "\" . "\" Tg11
    
    if Src1 = Tg11 then
      do
      	SRCtoTGT = 0
      	leave
      end
    
  end
  
  if SRCtoTGT then
  	do
  	  TargetFile = TargetDirectory1 || Src1
  	  call SysFileCopy SrcQB.i, TargetFile
  	end
  
end

/* Now perform the second loop to copy to the secondary location. */

do i = 1 to SrcQB.0

  parse var SrcQB.i . "\" . "\" Src1
  
  SRCtoTGT = 1
  
  do j = 1 to Tg2QB.0
    
    parse var Tg2QB.j . "\" . "\" . "\" . "\" . "\" Tg21
    
    if Src1 = Tg21 then
      do
      	SRCtoTGT = 0
      	leave
      end
    
  end
  
  if SRCtoTGT then
  	do
  	  TargetFile = TargetDirectory2 || Src1
  	  call SysFileCopy SrcQB.i, TargetFile
  	end
  
end

/* Added code to back up my KeePass database.                    */

SourceDirectory = "D:\My Documents\KeePassData\"
TargetDirectory1 = "C:\Users\Bill\Google Drive\Q_Data\"
TargetDirectory2 = "D:\Asus SyncFolder\Financial\Quicken Archive\"

FilePattern = "MeanyKeePass.kdbx"

Backup = SourceDirectory || FilePattern
Q_Data = TargetDirectory1 || FilePattern
Archive = TargetDirectory2 || FilePattern

call SysFileCopy Backup, Q_Data

call SysFileCopy Backup, Archive

exit