#!/bin/sh

function get_remote_revision() {
  local repo_url=$1
  # echo "svn info $repo_url | grep \"Revision: \" | sed \"s/Revision: //\""
  echo `svn info $repo_url | grep "Revision: " | sed "s/Revision: //"`
}

valgrind_svn_url="svn://svn.valgrind.org/valgrind/trunk"
vex_svn_url="svn://svn.valgrind.org/vex/trunk"

current_dir=`realpath \`dirname $0\``
valgrind_dir=$current_dir/main
vex_dir=$valgrind_dir/VEX

valgrind_revision=`cat $current_dir/upstream.revs.txt | grep "val: " | sed "s/val: //"`
vex_revision=`cat $current_dir/upstream.revs.txt | grep "vex: " | sed "s/vex: //"`

echo "Current revisions (from upstream.revs.txt): "
echo "  valgrind: $valgrind_revision"
echo "  vex     : $vex_revision"

if [ -z valgrind_revision  -o -z vex_revision ]; then
  echo "Error: File upstream.revs.txt file does not exist or has invalid format"
  echo "Expecting 'val: <revision number>' and 'vex: <revision number>'"
  exit -1
fi

upstream_valgrind_revision=$(get_remote_revision $valgrind_svn_url)
upstream_vex_revision=$(get_remote_revision $vex_svn_url)

echo "Upstream revisions: "
echo "  valgrind: $upstream_valgrind_revision"
echo "  vex     : $upstream_vex_revision"

if [ $upstream_valgrind_revision -gt $valgrind_revision ]; then
  echo "Merging valgrind... (in $valgrind_dir)" | tee $current_dir/merge.log
  cd $valgrind_dir
  svn diff -r$valgrind_revision:$upstream_valgrind_revision $valgrind_svn_url | patch -p0 | tee -f $current_dir/merge.log
fi

if [ $upstream_vex_revision -gt $vex_revision ]; then
  echo "Merging vex... (in $vex_dir)" | tee -a $current_dir/merge.log
  cd $vex_dir
  svn diff -r$vex_revision:$upstream_vex_revision $vex_svn_url | patch -p0 | tee -a $current_dir/merge.log
fi

echo "valgrind: $upstream_valgrind_revision" > $current_dir/upstream.revs.txt
echo "vex: $upstream_vex_revision" >> $current_dir/upstream.revs.txt

echo "Done: please do not forget to"
echo " 1. Check $current_dir/merge.log for possible merge issues"
echo " 2. Test the build and make adjustments to $current_dir/main/Android.mk if neccessary"

