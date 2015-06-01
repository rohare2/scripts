#!/bin/sh
#
# $Id: update_fedora.sh 467 2008-01-05 03:51:34Z rohare $
# $URL: https://restless/svn/scripts/trunk/update_fedora.sh $

# Create tailored Fedora Core 5 binary DVD and/or CD images.

# Orginal ideas and script by Rob Garth and Simone Caronni. Thx!
# http://www.users.on.net/~rgarth/weblog/fedora/patch_cd.html

# This script needs about 20-25 GByte disc space and a lot of time.

# Make sure to have the following packages installed:
#     createrepo, yum-utils, anaconda, and anaconda-runtime.

# Create a new directory, e.g. "/csfedora/", 
# and copy (!) complete FC DVD contents to "/csfedora/i386/". 
# Alternatively, copy the complete FC CD1 to "/csfedora/i386/"
# and then "Fedora/RPMS/*rpm" of all other CDs to 
# "/csfedora/i386/Fedora/RPMS/".

# Mount (or download) the updates to "/csfedora/updates/". 
# This dir can be empty.

# Run this script as root in the "/csfedora/" directory.

# Structure: /csfedora/i386/            - contents of original DVD,
#            /csfedora/updates/         - directory with the updates,
#            /csfedora/update_fedora.sh - this script.
 
# Note: The "/csfedora/i386/" directory will be updated, 
# the "/csfedora/updates/" will not be touched.

# The script outputs a DVD and/or 5 CD image(s) to the /usr/local/csfedora/ dir.

# BUILD_DVD=1 -> create DVD ISO image, BUILD_DVD=0 -> don't create DVD ISO 
BUILD_DVD=0
# BUILD_CDS=1 -> create 5 CD ISO images, BUILD_CDS=0 -> don't create CD ISOs
BUILD_CDS=1

export PYTHONPATH=/usr/lib/anaconda
export PATH="$PATH:/usr/lib/anaconda-runtime"
export FCBASE=`pwd`
arch=`uname -i`
date=`date +%Y%m%d`
publisher="rohare, mailto:rohare at llnl dot gov"
release="5"

echo "`date` - Merging updates ..."
cp -f $FCBASE/updates/*.rpm $FCBASE/$arch/Fedora/RPMS/
repomanage --old $FCBASE/$arch/Fedora/RPMS | xargs rm -f

# if you want to  tailor the installation, here are a few pointers:
# * Replace anaconda with a custom package for replaced artwork.
# * Add your own packages:
#   Copy additional RPMs to $FCBASE/$arch/Fedora/RPMS
#   To install these packages, refer to them in a kickstart file.
# * Automate the installation with kickstart files:
#   copy kickstart files to $FCBASE/$arch/
#   http://www.redhat.com/docs/manuals/enterprise/RHEL-4-Manual/sysadmin-guide/ch-kickstart2.html
echo "`date` - Adding non-Fedora stuff ..."
# copy kickstart files to $FCBASE/$arch/
#cp -a /my_ks/*cfg $FCBASE/$arch/
# copy additional RPMS to (or replace existing RPMs in) $FCBASE/$arch/Fedora/RPMS
#cp -a /my_rpms/*rpm $FCBASE/$arch/Fedora/RPMS/

# Remove old files
find $FCBASE -name "TRANS.TBL" -exec rm -f {} \;
rm -fr $FCBASE/$arch/isolinux/
rm -fr $FCBASE/$arch/images/

echo "`date` - Creating repo ...First createrepo for the tree."
cd $FCBASE/$arch
# First createrepo is for the tree
createrepo -g Fedora/base/comps.xml .
rm -rf .olddata/
cd ..


# Check for missing dependencies in repo
cat > $FCBASE/yum.conf.temp << EOF
[main]

[kh-temp]
name=kh-temp
baseurl=file://$FCBASE/$arch/
enabled=0
gpgcheck=0
EOF
echo " "
echo "##############################################################"
echo "##############################################################"
echo "##############################################################"
echo "`date` - Checking the repo for missing dependencies ..."
repoclosure -c $FCBASE/yum.conf.temp -r kh-temp
echo "###############################################################"
echo "#################### Look for errors above ####################"
echo "###############################################################"
echo " "
rm $FCBASE/yum.conf.temp

# Copy missing rpms into RPMS directory
# Cleanup and run createrepo again
# Retest, if good continue.

# Now included in buildinstall
#pkgorder --product=Fedora $FCBASE/$arch $arch Fedora > $FCBASE/pkgfile.$date

echo "`date` - Rebuilding installer ..."
buildinstall --comp dist-$release.$date \
   --pkgorder $FCBASE/pkgfile.$date --version $release \
   --product 'Fedora Core' --release "Fedora Core $release" \
   --prodpath Fedora $FCBASE/$arch


if [ $BUILD_DVD -eq 1 ]; then 
   echo "`date` - Creating DVD ISO ..."
   
   # we need to run createrepo a second time (for the media)
   dvd_discinfo=`head -1 $FCBASE/$arch/.discinfo`
   createrepo -u "media://${dvd_discinfo}#1" -g Fedora/base/comps.xml \
      --split $arch
   rm -rf .olddata/
   
   mkisofs -q -r -R -J -T -no-emul-boot -boot-load-size 4 \
      -b isolinux/isolinux.bin -c isolinux/boot.cat -boot-info-table \
      -V "FC $release update$date $arch DVD" \
      -A "Fedora Core $release update$date $arch DVD" \
      -publisher "$publisher" -p "$publisher" -x lost+found \
      -o FC-$release-update$date-$arch-DVD.iso $arch
   implantisomd5 FC-$release-update$date-$arch-DVD.iso
fi

if [ $BUILD_CDS -eq 1 ]; then 
   echo "`date` - Creating CD images ..."
   splittree.py --arch=$arch \
      --total-discs=5 --bin-discs=5 --src-discs=0 --srcdir=. \
      --release-string="Fedora Core $release" \
      --pkgorderfile=$FCBASE/pkgfile.$date --distdir=$FCBASE/$arch \
      --productpath=Fedora

   # we need to run createrepo a second time (for the media)
   rm -fr $FCBASE/${arch}-disc1/repodata
   cd_discinfo=`head -1 $FCBASE/${arch}-disc1/.discinfo`
   createrepo -u "media://${cd_discinfo}#1" -g Fedora/base/comps.xml \
   	-o ${arch}-disc1 \
      --split ${arch}-disc?

   echo -n "writing image for CD1"
   # The first CD is special (because it needs to be bootable)
   mkisofs -q -r -R -J -T -no-emul-boot -boot-load-size 4 -boot-info-table \
      -b isolinux/isolinux.bin -c isolinux/boot.cat \
      -V "FC $release update${date} $arch" \
      -A "Fedora Core $release update${date} $arch" \
      -publisher "$publisher" -p "$publisher" -x lost+found \
      -o FC-${release}-update${date}-${arch}-disc1.iso $FCBASE/${arch}-disc1

   CDS="2 3 4 5"
   for num in $CDS
   do
      echo -n " ... CD$num"
      mkisofs -q -r -R -J -T \
         -V "FC $release update${date} $arch" \
         -A "Fedora Core $release update${date} $arch" \
         -publisher "$publisher" -p "$publisher" -x lost+found \
         -o FC-${release}-update${date}-${arch}-disc${num}.iso $FCBASE/${arch}-disc${num}
   done
   
   echo ""
   
   CDS="1 2 3 4 5"
   for num in $CDS
   do
      implantisomd5 FC-${release}-update${date}-${arch}-disc${num}.iso
   done
fi

echo "`date` - Cleanup ..."
rm -rf $arch-disc?/ 
rm -f $FCBASE/pkgfile.$date

echo "`date` - Finished."
