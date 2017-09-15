# Copyright (c) 2010, Lawrence Livermore National Security (LLNS), LLC
# Produced at the Lawrence Livermore National Laboratory (LLNL)
# Written by Adam Moody <moody20@llnl.gov>.
# UCRL-CODE-232117.
# All rights reserved.
#
# This file is part of mpiGraph. For details, see
#   http://www.sourceforge.net/projects/mpigraph
# Please also read the Additional BSD Notice below.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the disclaimer below.
# * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the disclaimer (as noted below) in the documentation
#    and/or other materials provided with the distribution.
# * Neither the name of the LLNL nor the names of its contributors may be used to
#    endorse or promote products derived from this software without specific prior
#    written permission.
# *
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL LLNL, THE U.S. DEPARTMENT
# OF ENERGY OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Additional BSD Notice
# 1. This notice is required to be provided under our contract with the U.S. Department
#    of Energy (DOE). This work was produced at LLNL under Contract No. W-7405-ENG-48
#    with the DOE.
# 2. Neither the United States Government nor LLNL nor any of their employees, makes
#    any warranty, express or implied, or assumes any liability or responsibility for
#    the accuracy, completeness, or usefulness of any information, apparatus, product,
#    or process disclosed, or represents that its use would not infringe privately-owned
#    rights.
# 3. Also, reference herein to any specific commercial products, process, or services
#    by trade name, trademark, manufacturer or otherwise does not necessarily constitute
#    or imply its endorsement, recommendation, or favoring by the United States Government
#    or LLNL. The views and opinions of authors expressed herein do not necessarily state
#    or reflect those of the United States Government or  LLNL and shall not be used for
#    advertising or product endorsement purposes.

package hostlist_lite;
use strict;

# This package processes SLURM-style hostlist strings.
#
# expand($hostlist)
#   returns a list of individual hostnames given a hostlist string
# compress(@hostlist)
#   returns an ordered hostlist string given a list of hostnames
# diff(\@hostlist1, \@hostlist2)
#   subtracts elements in hostlist2 from hostlist1 and returns list of remainder
# intersect(\@hostlist1, \@hostlist2)
#   returns list of nodes that are in both hostlist1 and hostlist2
# 
#
# Author:  Adam Moody (moody20@llnl.gov)

# Returns a list of hostnames, give a hostlist string
# expand("rhea[2-4,6]") returns ('rhea2','rhea3','rhea4','rhea6')
sub expand {
  # read in our hostlist, should be first parameter
  if (@_ != 1) {
    return undef;
  }
  my $nodeset = shift @_;

  my $machine = undef;
  my @lowhighs = ();
  if ($nodeset =~ /([a-zA-Z]+)\[([\d,-]+)\]/) {
    # hostlist with brackets, e.g., atlas[2-5,28,30]
    $machine = $1;
    my @ranges = split ",", $2;
    foreach my $range (@ranges) {
      my $low  = undef;
      my $high = undef;
      if ($range =~ /(\d+)-(\d+)/) {
        # low-to-high range
        $low  = $1;
        $high = $2;
      } else {
        # single element range
        $low  = $range;
        $high = $range;
      }
      push @lowhighs, $low, $high;
    }
  } else {
    # single node hostlist, e.g., atlas2
    $nodeset =~ /([a-zA-Z]+)(\d+)/;
    $machine = $1;
    push @lowhighs, $2, $2;
  }

  # produce our list of nodes
  my @nodes = ();
  while(@lowhighs) {
    my $low  = shift @lowhighs;
    my $high = shift @lowhighs;
    for(my $i = $low; $i <= $high; $i++) {
      push @nodes, $machine . $i;
    }
  }

  return @nodes;
}

# Returns a hostlist string given a list of hostnames
# compress('rhea2','rhea3','rhea4','rhea6') returns "rhea[2-4,6]"
sub compress {
  if (@_ == 0) {
    return "";
  }

  # pull the machine name from the first node name
  my @numbers = ();
  my ($machine) = ($_[0] =~ /([a-zA-Z]+)(\d+)/);
  foreach my $host (@_) {
    # get the machine name and node number for this node
    my ($name, $number) = ($host =~ /([a-zA-Z]+)(\d+)/);

    # check that all nodes belong to the same machine
    if ($name ne $machine) {
      return undef;
    }

    # record the number
    push @numbers, $number;
  }

  # order the nodes by number
  my @sorted = sort {$a <=> $b} @numbers;

  # TODO: toss out duplicates?

  # build the ranges
  my @ranges = ();
  my $low  = $sorted[0];
  my $last = $low;
  for(my $i=1; $i < @sorted; $i++) {
    my $high = $sorted[$i];
    if($high == $last + 1) {
      $last = $high;
      next;
    }
    if($last > $low) {
      push @ranges, $low . "-" . $last;
    } else {
      push @ranges, $low;
    }
    $low  = $high;
    $last = $low;
  }
  if($last > $low) {
    push @ranges, $low . "-" . $last;
  } else {
    push @ranges, $low;
  }

  # join the ranges with commas and return the compressed hostlist
  return $machine . "[" . join(",", @ranges) . "]";
}

# Given references to two lists, subtract elements in list 2 from list 1 and return remainder
sub diff {
  # we should have two list references
  if (@_ != 2) {
    return undef;
  }
  my $set1 = $_[0];
  my $set2 = $_[1];

  my %nodes = ();

  # build list of nodes from set 1
  foreach my $node (@$set1) {
    $nodes{$node} = 1;
  }

  # remove nodes from set 2
  foreach my $node (@$set2) {
    delete $nodes{$node};
  }

  my @nodelist = (keys %nodes);
  if (@nodelist > 0) {
    my $list = scr_hostlist::compress(@nodelist);
    return scr_hostlist::expand($list);
  }
  return ();
}

# Given references to two lists, return list of intersection nodes
sub intersect {
  # we should have two list references
  if (@_ != 2) {
    return undef;
  }
  my $set1 = $_[0];
  my $set2 = $_[1];

  my %nodes = ();

  # build list of nodes from set 1
  my %tmp_nodes = ();
  foreach my $node (@$set1) {
    $tmp_nodes{$node} = 1;
  }

  # remove nodes from set 2
  foreach my $node (@$set2) {
    if (defined $tmp_nodes{$node}) {
      $nodes{$node} = 1;
    }
  }

  my @nodelist = (keys %nodes);
  if (@nodelist > 0) {
    my $list = scr_hostlist::compress(@nodelist);
    return scr_hostlist::expand($list);
  }
  return ();
}

1;
