package checkFormat;

###################################################################################################################################
#
# Copyright 2014-2017 IRD-CIRAD-INRA-ADNid
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/> or
# write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# You should have received a copy of the CeCILL-C license with this program.
#If not see <http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.txt>
#
# Intellectual property belongs to IRD, CIRAD and South Green developpement plateform for all versions also for ADNid for v2 and v3 and INRA for v3
# Version 1 written by Cecile Monat, Ayite Kougbeadjo, Christine Tranchant, Cedric Farcy, Mawusse Agbessi, Maryline Summo, and Francois Sabot
# Version 2 written by Cecile Monat, Christine Tranchant, Cedric Farcy, Enrique Ortega-Abboud, Julie Orjuela-Bouniol, Sebastien Ravel, Souhila Amanzougarene, and Francois Sabot
# Version 3 written by Cecile Monat, Christine Tranchant, Laura Helou, Abdoulaye Diallo, Julie Orjuela-Bouniol, Sebastien Ravel, Gautier Sarah, and Francois Sabot
#
###################################################################################################################################

use strict;
use warnings;
use Data::Dumper;
use Exporter;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

use lib qw(.);
use localConfig;
use toolbox;



################################################################################################
# sub checkFormatFastq => check if a file is really a FASTQ file
################################################################################################
# arguments : filename to analyze
# Returns boolean (1 if the format is fastq else 0)
################################################################################################

sub checkFormatFastq
{

    my $notOk = 0;                  # counter of error(s)
    my ($fileToTest) = @_;          # recovery of file to test

    #Checking the beginning and end structure
    my ($beginLines, $endLines);
    if ($fileToTest =~ m/gz$/)
    { # The file is in gzipped format
	#using zcat command for head and tail
	$beginLines = `zcat $fileToTest | head -n 4`;
	$endLines = `zcat $fileToTest | tail -n 4`;
    }
    else
    {
	$beginLines = `head -n 4 $fileToTest`;
	$endLines = `tail -n 4 $fileToTest`;
    }
    chomp $beginLines;
    chomp $endLines;

    if ($beginLines !~ m/^@/ and $endLines !~ m/^@/) # The file is not containing a 4 lines sequence in FASTQ format
    {
	toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : Number of lines is not a multiple of 4 in file $fileToTest, thus not a FASTQ file.\n",0);
    }


    open (my $inputHandle, $fileToTest) or toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : Cannot open the file $fileToTest\n$!\n",0); # open the file to test

    my  @linesF1=();
    my $comp=0;
    my $countlines=0;
    my $stop=0;

    #If $fileToTest is in gzip format
    if($fileToTest =~ m/\.gz$/)
    {
	$inputHandle = new IO::Uncompress::Gunzip $inputHandle or toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : Cannot open the gz file $fileToTest: $GunzipError\n",0);
    }

    while ((my $line = <$inputHandle>))                                           # scanning file and stocking in an array the four lines of a read.
    {
        chomp $line;
        $countlines++;

        if ($comp<3)
        {
            $comp++;
            push (@linesF1,$line);
        }
        else                                                            # Completing block, treatment starts here.
        {
            $stop++;
            push (@linesF1,$line);

            my $i=0;
            while ( ($i<=$#linesF1) and ($notOk <=1))                 # treatment of a block containing four lines of file and stop if 20 errors found.
            {

                my $idLine=$linesF1[$i];
                my $fastaLine=$linesF1[$i+1];
                my $plusLine=$linesF1[$i+2];
                my $qualityLine=$linesF1[$i+3];
                my $nbIDLine=$countlines-3;
                my $nbLineFasta=$countlines-2;
                my $nbPlusLine=$countlines-1;
                my $nbQualityLine=$countlines;

                if (($idLine=~m/^$/) and ($plusLine=~m/^$/))            # if the ID line and the "plus" line are not empty ...
                {
                    toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : The file $fileToTest is not a FASTQ file => The ID infos line $nbIDLine is not present.\n",0);
                    $notOk++;                                           # one error occured, so count it
                }

                elsif ( (($idLine=~m/^\@.*/) or ($idLine=~m/^\>.*/) ) and ($plusLine=~m/^\+/) )   # if ID ligne is not empty and it starts by "@" or ">" and the
                # plus line has a "+", the block of four lines ($i to $i+3) is traited.
                {
                    if ( length($fastaLine) == length($qualityLine) )   # comparing the fasta line and the quality line lengths.
                    {
                        my @fasta = split //, $fastaLine;
                        foreach my $nucleotide (@fasta)
                        {
                            if ($nucleotide!~m/A|T|G|C|a|g|t|c|N|n/)    # checking nucleotides in the fasta line.
                            {
                                toolbox::exportLog ("ERROR: checkFormat::checkFormatFastq : Not basic IUPAC letter, only ATGCNatgcn characters are allowed: unauthorized characters are in the line $nbLineFasta of $fileToTest.\n",0);
                                $notOk++;
                            }
                        }
                    }
                    else 												# error if fasta line length and quality line length are differents.
                    {
                        toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : Fasta line $nbLineFasta has not the same length than quality line $nbQualityLine in file $fileToTest.\n",0);
                        $notOk++;
                    }
                }

                else													#error if the ID line do not start with @ or >.
                {
                    toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : ID line has to start with @ or > in line $nbIDLine of file $fileToTest.\n",0);
                    $notOk++;
                }
                $i=$i+4; 												# jumping to next read.
            }

            last if ($stop==20000);                                    # stoping treatment if 50000 reads were analysed.

            undef @linesF1;
            $comp=0;
        }
        next;
    }

    if (($notOk == 0))                    						# if any error occured in the file, the format is right.
    {
        toolbox::exportLog("INFOS: checkFormat::checkFormatFastq : The file $fileToTest is a FASTQ file.\n",1);
	return 1;
    }
    else                                						# if one or some error(s) occured on the file, the fastq format is not right.
    {
        toolbox::exportLog("ERROR: checkFormat::checkFormatFastq : Invalid FASTQ requirements in file $fileToTest.\n",0);
    }

    close $inputHandle;

}
################################################################################################
# END sub checkFormatFastq
################################################################################################

################################################################################################
# sub checkSamOrBamFormat => verifying the SAM/BAM format based on samtools view system
# samtools view gave an error in case of non SAM or BAM format
################################################################################################
# arguments : filename to analyze
# Returns boolean (1 if the fileformat is sam, 2 bam and 0 neither bam or sam)
################################################################################################
sub checkSamOrBamFormat
{

    my ($samFile)=@_;

    existsFile($samFile); # Will check if the submitted file exists

    #Is the file sam of bam through the binary mode? Requested for the -S option in samtools view
    my ($inputOption,$binary);
    if (-B $samFile) #The file is a binary BAM file
    {
	$inputOption = ""; #no specific option in samtools view requested
	$binary = 1; # the file is binary
    }
    else #the file is a not binary SAM file
    {
	$inputOption = " -S ";#-S mean input is SAM
	$binary = 0; # the file is not binary
    }
    my $checkFormatCommand="$samtools view $inputOption $samFile -H > /dev/null";
    # The samtools view will ask only for the header to be outputted (-H option), and the STDOUT is redirected to nowher (>/dev/null);
    my $formatValidation=run($checkFormatCommand,"noprint");

    if ($formatValidation == 1)                    # if no error occured in extracting header, ok
    {
        ##DEBUG toolbox::exportLog("INFOS: toolbox::checkSamOrBamFormat : The file $samFile is a SAM/BAM file\n",1);
	return 1 if $binary == 0;# Return 1 if the file is a SAM
	return 2 if $binary == 1;# Return 2 if the file is a BAM
    }
    else                                # if one or some error(s) occured in extracting header, not ok
    {
        toolbox::exportLog("ERROR: checkFormat::checkSamOrBamFormat : The file $samFile is not a SAM/BAM file\n",0);
	return 0;
    }
}
################################################################################################
# END checkSamOrBamFormat
################################################################################################


1;

