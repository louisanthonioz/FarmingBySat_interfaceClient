#!/bin/bash

#-------------------------------------------------------------------------------------------	#
# Evolution du script bash dhusget 0.3.4 @ISEN - YNCREA
#-------------------------------------------------------------------------------------------	#

export VERSION=0.3.4.1000

WD=$HOME/dhusget_tmp
PIDFILE=$WD/pid

test -d $WD || mkdir -p $WD

bold=$(tput bold)
normal=$(tput sgr0)
print_script=`echo "$0" | rev | cut -d'/' -f1 | rev`

##Fonction d aide pour utilisation (-help)
function print_usage
{
 echo ""
 echo "-------------- Support d'utilisation --------------"
 echo "Ce script a été écrit dans le but de télécharger les documents nécessaires
 à l'élaboration d'un NDVI à partir des images satellites Copernicus"
 echo "---------------------------------------------------"
 echo "L'option -f <chemin/nom> permet d'utiliser un fichier comme date de début de la recherche"
 echo "L'option -c <lon1,lat1:lon2,lat2> permet de rechercher les images contenues dans un rectangle (Attention ordre inversé)"
 echo "L'option -F permet d'ajouter du code Query"
 echo ""
 exit -1
}

function print_version
{
	echo "dhusget $VERSION"
	exit -1
}


#---  Lecture des paramètres d'entrée
# $url + $user + $passwd + $NombreArchives + $Mission +$NomfichierXML +$NomFichierCSV
# + $InstrumentRecherché + $DebutRecherche +$FinRecherche + $DebutDateDetection +$FinDateDetection
# + $ProductType + $Telechargement +$FichierFailMD5 +$FichierData +$NbEssaisTelechargement
# + $UnicitéExecutionScript + $NbTéléchargementsSimultanés +$PageNumber?
export DHUS_DEST="https://scihub.copernicus.eu/dhus"
export USERNAME="DavidDESM"
export PASSWORD="XTU0dqb0"
export ROWS="1"
export MISSION="Sentinel-2"
export NAMEFILERESULTS="Ressources/OSquery-result.xml"
export PRODUCTLIST="Ressources/product-list.csv"
export INSTRUMENT=""
export INGESTION_TIME_FROM="2017-10-13T00:00:00.000Z"
export INGESTION_TIME_TO="NOW"
export SENSING_TIME_FROM="2017-10-13T00:00:00.000Z"
export SENSING_TIME_TO="NOW"
export PRODUCT_TYPE=""
export TO_DOWNLOAD="all"
export FAILED=""
export output_folder="Ressources/farmingData"
export number_tries="5"
export lock_file=""
export THREAD_NUMBER="1"
export PAGE="1"
export TIME_SUBQUERY=""
export CLOUD_COVER="[0 TO 3]"
unset TIMEFILE

#-- Set des paramètres d'entrée
export DHUS_DEST_IS_SET='OK'
export isselected_filtertime_lasthours='OK'
export isselected_filtertime_ingestion_date='OK'
export check_save_failed='OK'
##export save_products_failed='OK'
export OUTPUT_FOLDER_IS_SET='OK'
export LOCK_FILE_IS_SET='OK'
export THREAD_NUMBER_IS_SET='OK'


while getopts ":f:c:F:h:" opt; do
 case $opt in
	f)
		export TIMEFILE="$OPTARG"
		if [ -s $TIMEFILE ]; then
			export INGESTION_TIME_FROM="`cat $TIMEFILE`"
		else
			export INGESTION_TIME_FROM="1970-01-01T00:00:00.000Z"
		fi
		;;
	c)
		ROW=$OPTARG

		FIRST=`echo "$ROW" | awk -F\: '{print \$1}' `
		SECOND=`echo "$ROW" | awk -F\: '{print \$2}' `

		#--
		export x1=`echo ${FIRST}|awk -F, '{print $1}'`
		export y1=`echo ${FIRST}|awk -F, '{print $2}'`
		export x2=`echo ${SECOND}|awk -F, '{print $1}'`
		export y2=`echo ${SECOND}|awk -F, '{print $2}'`
		;;
        F)
                FREE_SUBQUERY_CHECK="OK"
		FREE_SUBQUERY="$OPTARG"
		;;
	h)
		print_usage $0
		;;
	esac
done

echo ""
echo "================================================================================================================"
echo "dhusget version: $VERSION"
echo "Type '$print_script -help' for usage information"
echo "================================================================================================================"
ISSELECTEDEXIT=false;
trap ISSELECTEDEXIT=true INT;

if [ -z $lock_file ];then
        export lock_file="$WD/lock"
fi

mkdir $lock_file

if [ ! $? == 0 ]; then
	echo -e "Error! An instance of \"dhusget\" retriever is running !\n Pid is: "`cat ${PIDFILE}` "if it isn't running delete the lockdir  ${lock_file}"

	exit
else
	echo $$ > $PIDFILE
fi

trap "rm -fr ${lock_file}" EXIT

export TIME_SUBQUERY="ingestiondate:[$INGESTION_TIME_FROM TO $INGESTION_TIME_TO]  "

export SENSING_SUBQUERY="beginPosition:[$SENSING_TIME_FROM TO $SENSING_TIME_TO]  "

if [ -z $THREAD_NUMBER ];then
        export THREAD_NUMBER="2"
fi

if [ -z $output_folder ];then
        export output_folder="PRODUCT"
fi

export WC="wget --no-check-certificate"

echo "LOGIN"

printf "\n"

if [ -z $DHUS_DEST_IS_SET ];then
echo "Data hub url not specified. "
echo "Default Data Hub Service URL is: "
else
echo "Specified Data Hub Service URL is: $DHUS_DEST"
fi

if [ ! -z $USERNAME ] && [ -z $PASSWORD ];then
echo "You have inserted only USERNAME"
echo ""
fi

if [ -z $USERNAME ] && [ ! -z $PASSWORD ];then
echo "You have inserted only PASSWORD"
echo ""
fi

if [ -z $USERNAME ];then
        read -p "Enter username: " VAL
        printf "\n"
        export USERNAME=${VAL}
fi

if [ -z $PASSWORD ];then
	read -s -p "Enter password: " VAL
        printf "\n\n"
	export PASSWORD=${VAL}
fi

export AUTH="--user=${USERNAME} --password=${PASSWORD}"

if [ -z $number_tries ];then
      export TRIES="--tries=5"
else
      export TRIES="--tries=${number_tries}"
fi

mkdir -p './logs/'

if [ ! -z $check_retry ] && [ -s $FAILED_retry ]; then
	 cp $FAILED_retry .failed.control.retry.now.txt
   	 export INPUT_FILE=.failed.control.retry.now.txt


	mkdir -p $output_folder

if [ -f .failed.control.now.txt ]; then
    rm .failed.control.now.txt
fi
cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c ' while : ; do
        echo "Downloading product ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
        ${WC} ${AUTH} ${TRIES} --progress=dot -e dotbytes=10M -c --output-file=./logs/log.${3}.log -O $output_folder/${3}".zip" "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
        test=$?;
        if [ $test -eq 0 ]; then
                echo "Product ${3} successfully downloaded at " `tail -2 ./logs/log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
                remoteMD5=$( ${WC} -qO- ${AUTH} ${TRIES} -c "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Checksum/Value/$value" | awk -F">" '\''{print $3}'\'' | awk -F"<"     '\''{print $1}'\'');
                localMD5=$( openssl md5 $output_folder/${3}".zip" | awk '\''{print $2}'\'');
                localMD5Uppercase=$(echo "$localMD5" | tr '\''[:lower:]'\'' '\''[:upper:]'\'');
                if [ "$remoteMD5" == "$localMD5Uppercase" ]; then
                        echo "Product ${3} successfully MD5 checked";
                else
                echo "Checksum for product ${3} failed";
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
                if [ ! -z $save_products_failed ];then
		      rm $output_folder/${3}".zip"
		fi
                fi;
        else
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
                if [ ! -z $save_products_failed ];then
		      rm $output_folder/${3}".zip"
                fi
        fi;
        break;
done '
rm .failed.control.retry.now.txt
fi

#----- Options value check
echo "================================================================================================================"
echo "SEARCH QUERY OPTIONS"
if [ -z $TIME ] && [ -z $TIMEFILE ] && [ -z $ROW ] && [ -z $PRODUCT_TYPE ] && [ -z $FREE_SUBQUERY_CHECK ] && [ -z $SENSING_TIME ] && [ -z $MISSION ] && [ -z $INSTRUMENT ];
then
     echo ""
     echo "No Search Options specified. Default query is q='*'."
     export QUERY_STATEMENT="*"
else
echo ""
fi
if [ -z $MISSION ]; then
	echo "Search is performed on all available sentinel missions."
else
        echo "Mission is set to $MISSION. "
fi
if [ -z $INSTRUMENT ]; then
	echo "Search is performed on all available instruments."
else
        echo "Instrument is set to $INSTRUMENT. "
fi
if [ -z $TIME ]; then
	echo "Ingestion date options not specified"
else
if [ ! -z $isselected_filtertime_ingestion_date ] && [ ! -z $isselected_filtertime_lasthours ]; then
             if [ -z $TIMEFILE ];then
		echo "Time saerch is set from $INGESTION_TIME_FROM to $INGESTION_TIME_TO. "
             else
                echo "Search is performed for all products ingested in the period [$INGESTION_TIME_FROM,$INGESTION_TIME_TO]. "
             fi
     else
     if [ ! -z $isselected_filtertime_lasthours ]; then
        if [ -z $TIMEFILE ];then
         echo "Search is performed for all products ingested in the last $TIME hours. "
        fi
     else
         echo "Search is performed for all products ingested in the period [$INGESTION_TIME_FROM,$INGESTION_TIME_TO]. "
     fi
     fi
fi
if [ -z $SENSING_TIME ]; then
	echo "Sensing date options not specified"
else
        echo "Search for all products having sensing date included in [$SENSING_TIME_FROM,$SENSING_TIME_TO]. "
fi
if [ ! -z $TIMEFILE ] && [ -z $isselected_filtertime_ingestion_date ]; then
	echo "The ingestion date provided through $TIMEFILE is used to search all products ingested in the period [DATEINGESTION,NOW]. The file is updated with the ingestion date of the last available product found. "
fi
if [ -z $ROW ]; then
	echo "'No specified Area of Interest. Search is performed on the whole globe."
else
        echo "Search is performed on an Area of interest defined as a bounding box delimited by P1=[lon1=$x1,lat1=$y1] and P2=[lon2=$x2,lat2=$y2]."
fi
if [ -z $PRODUCT_TYPE ]; then
	echo "Search is performed on all available product types. "
else
        echo "Product type is set to $PRODUCT_TYPE. "
fi
if [ ! -z $FREE_SUBQUERY_CHECK ]; then
        echo "Your QUERY search is $FREE_SUBQUERY. This OpenSearch query will be in AND with other search options. "
fi
echo "================================================================================================================"
echo "SEARCH RESULT OPTIONS"
echo ""
if [ -z $ROWS ]; then
	echo "Default Maximum Number of Results per page is 25. "
else
        echo "The number of results per page is $ROWS. "
fi
if  [ -z $PAGE ]; then
	echo "Default Page Number is 1. "
else
        echo "The page visualized is $PAGE. "
fi
if [ -z $NAMEFILERESULTS ]; then
	echo "OpenSearch results are stored by default in ./OSquery-result.xml. "
else
        echo "OpenSearch results are stored in $NAMEFILERESULTS. "
fi
if [ -z $PRODUCTLIST ]; then
	echo "List of results are stored by default in the CSV file ./products-list.csv. "
else
        echo "List of results are stored in the specified CSV file $PRODUCTLIST. "
fi
if [ ! -z $TO_DOWNLOAD ] || [ ! -z $check_retry ];then
CHECK_VAR=true;
else
CHECK_VAR=false;
fi
echo "================================================================================================================"
echo "DOWNLOAD OPTIONS"
echo ""
if [ $CHECK_VAR == false ];then
echo "No download options specified. No files will be downloaded. "
fi
if [ ! -z $TO_DOWNLOAD ]; then
        if [ $TO_DOWNLOAD=="product" ]; then
            echo "Downloads are active. By default product downloads are stored in ./PRODUCT"
        else
        if [ $TO_DOWNLOAD=="manifest" ]; then
            echo "Download $TO_DOWNLOAD. Only manifest files are downloaded. Manifest files are stored in ./manifest. "
        else
            echo "Download $TO_DOWNLOAD. Downloads are active. Products and manifest files are downloded separately. "
        fi
        fi
fi

if [[ $CHECK_VAR == true &&  ! -z $OUTPUT_FOLDER_IS_SET ]]; then
    echo "Product downloads are stored in ./$output_folder. "
fi
if [[ $CHECK_VAR == true  &&  -z $number_tries ]]; then
        echo "By default the number of wget download retries is 5. "
else
   if [[ $CHECK_VAR == true  &&  ! -z $number_tries ]]; then
        echo "The number of wget download retries is $number_tries. "
   fi
fi
if [[ $CHECK_VAR == true  &&  -z $check_save_failed ]]; then
        echo "By default the list of products failing the MD5 integrity check is saved in ./failed_MD5_check_list.txt. "
else
     if [[ $CHECK_VAR == true  &&  ! -z $check_save_failed ]]; then
        echo "The list of products failing the MD5 integrity check is saved in $FAILED. "
     fi
fi
if [[ $CHECK_VAR == true  &&  ! -z $save_products_failed ]]; then
    echo "MD5 validation is active. Products that have failed the MD5 integrity check are deleted from the local disks. "
fi
if [[ $CHECK_VAR == true  &&  ! -z $check_retry ]]; then
    echo "Retry the download of the products listed in $FAILED_retry. "
fi
if [ ! -z $LOCK_FILE_IS_SET ]; then
        echo "Multiple instances of execution is $lock_file. This instance of dhusget can be executed in parallel to other instances. "
fi
if [[ $CHECK_VAR == true  &&  -z $THREAD_NUMBER_IS_SET ]]; then
        echo "By default the number of concurrent downloads (either products or manifest files) is 2. "
else
    if [[ $CHECK_VAR == true  &&  ! -z $THREAD_NUMBER_IS_SET ]]; then
        echo "The number of concurrent downloads (either products or manifest files) is set to $THREAD_NUMBER. Attention, this value doesn't override the quota limit set on the server side for the user. "
    fi
fi

echo "================================================================================================================"
echo "CONNECTION TO DATA HUB"
echo ""
if [ ! -z $MISSION ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT platformname:$MISSION"
	QUERY_STATEMENT_CHECK='OK'
fi
if [ ! -z $INSTRUMENT ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT instrumentshortname:$INSTRUMENT"
	QUERY_STATEMENT_CHECK='OK'
fi
if [ ! -z $PRODUCT_TYPE ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT producttype:$PRODUCT_TYPE"
	QUERY_STATEMENT_CHECK='OK'
fi
if [ ! -z $TIME ];then
	if [ ! -z $QUERY_STATEMENT_CHECK ]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND "
	fi
	export QUERY_STATEMENT="$QUERY_STATEMENT ${TIME_SUBQUERY}"
	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $SENSING_TIME ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT ${SENSING_SUBQUERY}"
	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $TIMEFILE ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT ${TIME_SUBQUERY}"

	QUERY_STATEMENT_CHECK='OK'
fi

if [ ! -z $FREE_SUBQUERY_CHECK ];then
        if [ ! -z $QUERY_STATEMENT_CHECK ]; then
                export QUERY_STATEMENT="$QUERY_STATEMENT AND "
        fi
        export QUERY_STATEMENT="$QUERY_STATEMENT $FREE_SUBQUERY"
	QUERY_STATEMENT_CHECK='OK'
fi
#--- Prépare le query machin pour la couverture nuageuse
export CLOUD_SUBQUERY=`LC_NUMERIC=en_US.UTF-8; printf "(cloudcoverpercentage:$CLOUD_COVER)"`
#---- Prepare query polygon statement
if [ ! -z $x1 ];then
	if [[ ! -z $QUERY_STATEMENT ]]; then
		export QUERY_STATEMENT="$QUERY_STATEMENT AND $CLOUD_SUBQUERY AND"
	fi
	export GEO_SUBQUERY=`LC_NUMERIC=en_US.UTF-8; printf "( footprint:\"Intersects(POLYGON((%.13f %.13f,%.13f %.13f,%.13f %.13f,%.13f %.13f,%.13f %.13f )))\")" $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 `
	export QUERY_STATEMENT=${QUERY_STATEMENT}" ${GEO_SUBQUERY}"
else
	export GEO_SUBQUERY=""
fi
#- ... append on query (without repl
if [ -z $ROWS ];then
        export ROWS=25
fi

if [ -z $PAGE ];then
        export PAGE=1
fi
START=$((PAGE-1))
START=$((START*ROWS))
export QUERY_STATEMENT="${DHUS_DEST}/search?q="${QUERY_STATEMENT}"&rows="${ROWS}"&start="${START}""
## La flemme de relire ça ! echo "HTTP request done: "$QUERY_STATEMENT""
##echo ""
#--- Execute query statement
if [ -z $NAMEFILERESULTS ];then
        export NAMEFILERESULTS="OSquery-result.xml"
fi
/bin/rm -f $NAMEFILERESULTS
${WC} ${AUTH} ${TRIES} -c -O "${NAMEFILERESULTS}" "${QUERY_STATEMENT}"
LASTDATE=`date -u +%Y-%m-%dT%H:%M:%S.%NZ`
sleep 5

cat $PWD/"${NAMEFILERESULTS}" | grep '<id>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_id_list

cat $PWD/"${NAMEFILERESULTS}" | grep '<link rel="alternative" href=' | cut -f4 -d'"' | cat -n | sed 's/\/$//'> .product_link_list

cat $PWD/"${NAMEFILERESULTS}" | grep '<title>' | tail -n +2 | cut -f2 -d'>' | cut -f1 -d'<' | cat -n > .product_title_list
if [ ! -z $TIMEFILE ];then
if [ `cat "${NAMEFILERESULTS}" | grep '="ingestiondate"' |  head -n 1 | cut -f2 -d'>' | cut -f1 -d'<' | wc -l` -ne 0 ];
then
	lastdate=`cat $PWD/"${NAMEFILERESULTS}" | grep '="ingestiondate"' |  head -n 1 | cut -f2 -d'>' | cut -f1 -d'<'`;
	years=`echo $lastdate | tr "T" '\n'|head -n 1`;
	hours=`echo $lastdate | tr "T" '\n'|tail -n 1`;
	echo `date +%Y-%m-%d --date="$years"`"T"`date +%T.%NZ -u --date="$hours + 0.001 seconds"`> $TIMEFILE
fi
fi

paste -d\\n .product_id_list .product_title_list | sed 's/[",:]/ /g' > product_list

cat .product_title_list .product_link_list | sort -k1n,1 -k2r,2 | sed 's/[",:]/ /g' | sed 's/https \/\//https:\/\//' > .product_list_withlink

rm -f .product_id_list .product_link_list .product_title_list .product_ingestion_time_list

echo ""

cat "${NAMEFILERESULTS}" | grep '<subtitle>' | cut -f2 -d'>' | cut -f1 -d'<' | cat -n

NPRODUCT=`cat "${NAMEFILERESULTS}" | grep '<subtitle>' | cut -f2 -d'>' | cut -f1 -d'<' | cat -n | cut -f11 -d' '`;

echo ""

if [ "${NPRODUCT}" == "0" ]; then exit 1; fi

cat .product_list_withlink
if [ -z $PRODUCTLIST ];then
   export PRODUCTLIST="products-list.csv"
fi
cp .product_list_withlink $PRODUCTLIST
cat $PRODUCTLIST | cut -f2 -d$'\t' > .products-list-tmp.csv
cat .products-list-tmp.csv | grep -v 'https' > .list_name_products.csv
cat .products-list-tmp.csv | grep 'https' > .list_link_to_products.csv
paste -d',' .list_name_products.csv .list_link_to_products.csv > $PRODUCTLIST
rm .product_list_withlink .products-list-tmp.csv .list_name_products.csv .list_link_to_products.csv
export rv=0
if [ "${TO_DOWNLOAD}" == "manifest" -o "${TO_DOWNLOAD}" == "all" ]; then
	export INPUT_FILE=product_list

	if [ ! -f ${INPUT_FILE} ]; then
	 echo "Error: Input file ${INPUT_FILE} not present "
	 exit
	fi

	mkdir -p MANIFEST/

cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c 'while : ; do
	echo "Downloading manifest ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Nodes('\''"$3".SAFE'\'')/Nodes('\'manifest.safe\'')/\$value";
	${WC} ${AUTH} ${TRIES} --progress=dot -e dotbytes=10M -c --output-file=./logs/log.${3}.log -O ./MANIFEST/manifest.safe-${3} "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Nodes('\''"$3".SAFE'\'')/Nodes('\'manifest.safe\'')/\$value" ;
	test=$?;
	if [ $test -eq 0 ]; then
		echo "Manifest ${3} successfully downloaded at " `tail -2 ./logs/log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
	fi;
	[[ $test -ne 0 ]] || break;
done '
fi

if [ "${TO_DOWNLOAD}" == "product" -o "${TO_DOWNLOAD}" == "all" ];then

    export INPUT_FILE=product_list


mkdir -p $output_folder

#Xargs works here as a thread pool, it launches a download for each thread (P 2), each single thread checks
#if the download is completed succesfully.
#The condition "[[ $? -ne 0 ]] || break" checks the first operand, if it is satisfied the break is skipped, instead if it fails
#(download completed succesfully (?$=0 )) the break in the OR is executed exiting from the intitial "while".
#At this point the current thread is released and another one is launched.
if [ -f .failed.control.now.txt ]; then
    rm .failed.control.now.txt
fi
cat ${INPUT_FILE} | xargs -n 4 -P ${THREAD_NUMBER} sh -c ' while : ; do
	echo "Downloading product ${3} from link ${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
        ${WC} ${AUTH} ${TRIES} --progress=dot -e dotbytes=10M -c --output-file=./logs/log.${3}.log -O $output_folder/${3}".zip" "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/\$value";
	test=$?;
	if [ $test -eq 0 ]; then
		echo "Product ${3} successfully downloaded at " `tail -2 ./logs/log.${3}.log | head -1 | awk -F"(" '\''{print $2}'\'' | awk -F")" '\''{print $1}'\''`;
		remoteMD5=$( ${WC} -qO- ${AUTH} ${TRIES} -c "${DHUS_DEST}/odata/v1/Products('\''"$1"'\'')/Checksum/Value/$value" | awk -F">" '\''{print $3}'\'' | awk -F"<" '\''{print $1}'\'');
		localMD5=$( openssl md5 $output_folder/${3}".zip" | awk '\''{print $2}'\'');
		localMD5Uppercase=$(echo "$localMD5" | tr '\''[:lower:]'\'' '\''[:upper:]'\'');
		#localMD5Uppercase=1;
		if [ "$remoteMD5" == "$localMD5Uppercase" ]; then
			echo "Product ${3} successfully MD5 checked";
		else
		echo "Checksum for product ${3} failed";
		echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
		if [ ! -z $save_products_failed ];then
		      rm $output_folder/${3}".zip"
		fi
		fi;
	else
                echo "${0} ${1} ${2} ${3}" >> .failed.control.now.txt;
                if [ ! -z $save_products_failed ];then
		      rm $output_folder/${3}".zip"
                fi
	fi;
        break;
done '
fi
if [ ! -z $check_save_failed ]; then
    if [ -f .failed.control.now.txt ];then
    	mv .failed.control.now.txt $FAILED
    else
    if [ ! -f .failed.control.now.txt ] && [ $CHECK_VAR == true ] && [ ! ISSELECTEDEXIT ];then
    	echo "All downloaded products have successfully passed MD5 integrity check"
    fi
    fi
else
    if [ -f .failed.control.now.txt ];then
    	 mv .failed.control.now.txt failed_MD5_check_list.txt
    else
    if [ ! -f .failed.control.now.txt ] && [ $CHECK_VAR == true ] && [ ! ISSELECTEDEXIT ];then
    	echo "All downloaded products have successfully passed MD5 integrity check"
    fi
    fi
fi
echo 'the end'
