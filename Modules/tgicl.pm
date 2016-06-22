package tgicl;

###################################################################################################################################
#
# Copyright 2014-2016 IRD-CIRAD-INRA-ADNid
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
# Version 3 written by Cecile Monat, Christine Tranchant, Cedric Farcy, Maryline Summo, Julie Orjuela-Bouniol, Sebastien Ravel, Gautier Sarah, and Francois Sabot
#
###################################################################################################################################

use strict;
use warnings;
use localConfig;
use toolbox;
use Data::Dumper;


sub tgiclRun
{
    my($refFastaFileIn,$optionsHachees)=@_;
    if (toolbox::sizeFile($refFastaFileIn)==1)		##Check if the reference file exist and is not empty
    {
        my $options=toolbox::extractOptions($optionsHachees, " ");		##Get given options
        my $command=$tgicl." ".$refFastaFileIn." ".$options;		##command
        #Execute command
        if(toolbox::run($command)==1)		##The command should be executed correctly (ie return) before exporting the log
        {
            ##DEBUG toolbox::exportLog("INFOS: bwa::bwaIndex : correctly done\n",1);		# bwaIndex have been correctly done
            return 1;
        }
        else
        {
            toolbox::exportLog("ERROR: tgicl::tgiclRun : ABORTED\n",0);		# bwaIndex have not been correctly done
            return 0;
        }
    }
    else
    {
        toolbox::exportLog("ERROR: tgicl::tgiclRun : the file $refFastaFileIn is empty\n",0);		# bwaIndex can not function because of wrong/missing reference file
        return 0;
    }
}

1;

=head1 NAME

    Package I<tgicl> 

=head1 SYNOPSIS

        use tgicl;
    
        tgicl::tgiclRun ($refFastaFileIn, $option_prog{'TGICL option'});
    
        
=head1 DESCRIPTION

    TGI Clustering tools (TGICL): a software system for fast clustering of large EST datasets
    This package automates clustering and assembly of a large EST/mRNA dataset. The clustering is performed by a slightly modified version of NCBI's megablast , and the resulting clusters are then assembled using CAP3 assembly program. TGICL starts with a large multi-FASTA file (and an optional peer quality values file) and outputs the assembly files as produced by CAP3
=head2 FUNCTIONS


=head3 tgicl::tgiclRun

This function execute the tgicl software and generate a clustering fasta file 

It is required 2 arguments in input :
- the sequence file (fasta format),
- the hash from config file with tgicl options

Return 0,1,2 with the sub toolbox::run

Example: 
C<tgicl::tgiclRun ($faFile, $hashOptions) ;> 	

=head1 AUTHORS

Intellectual property belongs to IRD, CIRAD and South Green developpement plateform 
Written by Cecile Monat, Ayite Kougbeadjo, Marilyne Summo, Cedric Farcy, Mawusse Agbessi, Christine Tranchant and Francois Sabot

=head1 SEE ALSO

L<http://www.southgreen.fr/>

=cut
