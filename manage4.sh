##  original script from corsaro. Modified by liberspirita. Modified my MrV. Modified by corsaro for 4 nodes
####################################################
## corsaro modifications are :
## added 4th node
####################################################
####################################################
## MrV modifications are :
## SRV1 is no longer preferred
## Setup for 3 servers now
## Lowered sleep to monitor more often
####################################################
####################################################
## modifications are :
## SRV1 is prefered anyway when the 2 nodes are OK
## unactivate forging on SRV2 if both are activated
## activate forging on SRV1 if none is activated
## secret write only once in variable
####################################################
##
## auto select forging script, version for 2 nodes
## Requirements are: 1 fixed IP (home IP, office IP, VPN or VPS are fine) and 2 cheap VPS
## https needed
## jq is needed. instal it with:
## sudo apt-get install jq
## you have to whitelist on config.json (on the API and FORGING section), the IP of the machine where the script is running
## Inside the script you have to write your SECRET seed
## on this version, I use https on port 2443
##
#!/bin/bash
SECRET="\"PASSPHRASE\""
SRV1="SERVER1"  # ip or host if set in /etc/hosts
SRV2="SERVER2" # ip or host if set in /etc/hosts
SRV3="SERVER3" # ip or host if set in /etc/hosts
SRV4="SERVER4" # ip or host if set in /etc/hosts
PRT1=":8000"   # 7000 on testnet, 8000 on mainnet
PRT2=$PRT1     # same port used on both server
PRT3=$PRT1  
PRT4=$PRT1   # same port used on both server
PRTS=":8443"   # port used on https
pbk="PUBLIC KEY"
while true; do
    HEIGHT1=$(curl --connect-timeout 3 -s "http://"$SRV1""$PRT1"/api/loader/status/sync"| jq '.height')
    if [[ -z "$HEIGHT1" ]];
    then
        HEIGHT1=$(curl --connect-timeout 3 -s "http://"$SRV1""$PRT1"/api/loader/status/sync"| jq '.height')
    fi
    HEIGHT2=$(curl --connect-timeout 3 -s "http://"$SRV2""$PRT2"/api/loader/status/sync"| jq '.height')
    if [[ -z "$HEIGHT2" ]];
    then
        HEIGHT2=$(curl --connect-timeout 3 -s "http://"$SRV2""$PRT2"/api/loader/status/sync"| jq '.height')
    fi
    HEIGHT3=$(curl --connect-timeout 3 -s "http://"$SRV3""$PRT3"/api/loader/status/sync"| jq '.height')
    if [[ -z "$HEIGHT3" ]];
    then
        HEIGHT3=$(curl --connect-timeout 3 -s "http://"$SRV3""$PRT3"/api/loader/status/sync"| jq '.height')
    fi
    HEIGHT4=$(curl --connect-timeout 3 -s "http://"$SRV4""$PRT4"/api/loader/status/sync"| jq '.height')
    if [[ -z "$HEIGHT4" ]];
    then
        HEIGHT4=$(curl --connect-timeout 3 -s "http://"$SRV4""$PRT4"/api/loader/status/sync"| jq '.height')
    fi
    
    ## Check if any servers are off
    if ! [[ "$HEIGHT1" =~ ^[0-9]+$ ]];
    then
        echo $SRV1 " " "is off?"
        HEIGHT1="0"
    fi
    if ! [[ "$HEIGHT2" =~ ^[0-9]+$ ]];
    then
        echo $SRV2 " " "is off?"
        HEIGHT2="0"
    fi
    if ! [[ "$HEIGHT3" =~ ^[0-9]+$ ]];
    then
        echo $SRV3 " " "is off?"
        HEIGHT3="0"
    fi
    if ! [[ "$HEIGHT4" =~ ^[0-9]+$ ]];
    then
        echo $SRV4 " " "is off?"
        HEIGHT4="0"
    fi
    
    ## Get forging status of servers
    FORGE1=$(curl --connect-timeout 3 -s "http://"$SRV1""$PRT1"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    if [[ -z "$FORGE1" ]];
    then
        FORGE1=$(curl --connect-timeout 3 -s "http://"$SRV1""$PRT1"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    fi
    FORGE2=$(curl --connect-timeout 3 -s "http://"$SRV2""$PRT2"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    if [[ -z "$FORGE2" ]];
    then
        FORGE2=$(curl --connect-timeout 3 -s "http://"$SRV2""$PRT2"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    fi
    FORGE3=$(curl --connect-timeout 3 -s "http://"$SRV3""$PRT3"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    if [[ -z "$FORGE3" ]];
    then
        FORGE3=$(curl --connect-timeout 3 -s "http://"$SRV3""$PRT3"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    fi
    
    FORGE4=$(curl --connect-timeout 3 -s "http://"$SRV4""$PRT4"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    if [[ -z "$FORGE4" ]];
    then
        FORGE4=$(curl --connect-timeout 3 -s "http://"$SRV4""$PRT4"/api/delegates/forging/status?publicKey="$pbk| jq '.enabled')
    fi
    
    ## Display status of servers
    echo
    echo $SRV1 " " $HEIGHT1 " " $FORGE1
    echo $SRV2 " " $HEIGHT2 " " $FORGE2
    echo $SRV3 " " $HEIGHT3 " " $FORGE3
    echo $SRV4 " " $HEIGHT4 " " $FORGE4
    
    ## Find highest height
    HEIGHT=$HEIGHT1
    if [ "$HEIGHT2" -gt "$HEIGHT" ];
    then
    	HEIGHT=$HEIGHT2
    fi
    if [ "$HEIGHT3" -gt "$HEIGHT" ];
    then
    	HEIGHT=$HEIGHT3
    fi
    
    if [ "$HEIGHT4" -gt "$HEIGHT" ];
    then
    	HEIGHT=$HEIGHT4
    fi
    
    echo
    echo "Highest Height: $HEIGHT"
    
    ## Make sure a server is forging.
    ## modified by corsaro
    if [ "$FORGE1" != "true"  ] && [ "$FORGE2" != "true" ] && [ "$FORGE3" != "true" ] && [ "$FORGE4" != "true" ];
    then
    	diff1=$(( $HEIGHT - $HEIGHT1 ))
    	diff2=$(( $HEIGHT - $HEIGHT2 ))
    	diff3=$(( $HEIGHT - $HEIGHT3 ))
  #  	diff4=$(( $HEIGHT - $HEIGHT4 ))
    	if [ "$diff1" -eq "0" ]
		then
			echo
        	echo "$SRV1 height is fine, trying to forge on $SRV1"
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/enable
		
		
		elif [ "$diff2" -eq "0" ]
				    then
			echo
        	echo "$SRV2 height is fine, trying to forge on $SRV2"
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/enable

		elif [ "$diff3" -eq "0" ]
				    then
			echo
        	echo "$SRV3 height is fine, trying to forge on $SRV3"
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/enable
			
		else
			echo
        	echo "No node forging.  Starting on $SRV4"
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/enable
		fi
    fi
    
    ## Check height of forging server
    ## modified by corsaro
    if [[ "$FORGE1" == "true" ]];
    then
    	diffa=$(( $HEIGHT - $HEIGHT1 ))
		diffb=$(( $HEIGHT - $HEIGHT2 ))
        diffc=$(( $HEIGHT - $HEIGHT3 ))
        diffd=$(( $HEIGHT - $HEIGHT4 ))
        
    	if [ "$diffa" -eq "0" ]
		    then
		    echo
		    ## do nothing
		elif [ "$diffc" -eq "0" ]
			then
			echo
				echo "$SRV1 height too low. Switching to $SRV3"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
				
		elif [ "$diffb" -eq "0" ]
			then
				echo
				echo "$SRV1 height too low. Switching to $SRV2"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
					
		else
				echo
				echo "$SRV1 height too low. Switching to $SRV4"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/enable
			
		fi
    
    fi
    
    
    if [[ "$FORGE2" == "true" ]];
    then
    	diffa=$(( $HEIGHT - $HEIGHT1 ))
		diffb=$(( $HEIGHT - $HEIGHT2 ))
        diffc=$(( $HEIGHT - $HEIGHT3 ))
        diffd=$(( $HEIGHT - $HEIGHT4 ))
        
    	if [ "$diffb" -eq "0" ]
		    then
		    echo
		    ## do nothing
		elif [ "$diffa" -eq "0" ]
				    then
			echo
				echo "$SRV2 height too low. Switching to $SRV1"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
				
		elif [ "$diffd" -eq "0" ]
			then
				echo
				echo "$SRV2 height too low. Switching to $SRV4"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/enable
	
		else
				echo
				echo "$SRV2 height too low. Switching to $SRV3"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
							
		fi
    fi
  
  


    if [[ "$FORGE3" == "true" ]];
    then
    	diffa=$(( $HEIGHT - $HEIGHT1 ))
		diffb=$(( $HEIGHT - $HEIGHT2 ))
        diffc=$(( $HEIGHT - $HEIGHT3 ))
        diffd=$(( $HEIGHT - $HEIGHT4 ))
        
    	if [ "$diffc" -eq "0" ]
		    then
		    echo
				## do nothing
		elif [ "$diffa" -eq "0" ]
				    then
			echo
				echo "$SRV3 height too low. Switching to $SRV1"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
		elif [ "$diffd" -eq "0" ]
			then
				echo
				echo "$SRV3 height too low. Switching to $SRV4"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/enable
	
		else
				echo
				echo "$SRV3 height too low. Switching to $SRV2"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable			
		fi
    fi
    
    
    
    
    
    
     if [[ "$FORGE4" == "true" ]];
    then
    	diffa=$(( $HEIGHT - $HEIGHT1 ))
		diffb=$(( $HEIGHT - $HEIGHT2 ))
        diffc=$(( $HEIGHT - $HEIGHT3 ))
        diffd=$(( $HEIGHT - $HEIGHT4 ))
        
    	if [ "$diffd" -eq "0" ]
		    then
		    echo
		    ## do nothing
		elif [ "$diffa" -eq "0" ]
		    then
			echo
				echo "$SRV4 height too low. Switching to $SRV1"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable

		elif [ "$diffb" -eq "0" ]
			then
				echo
				echo "$SRV4 height too low. Switching to $SRV2"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
	
		else
				echo
				echo "$SRV4 height too low. Switching to $SRV3"
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/enable
				curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
			
		fi
    fi
  
  
  
  
  
  
  
    
    ## Make sure only one node is forging.  If not, enable it on first node within highest height and disable on others
    if ( [ "$FORGE1" == "true" ] && [ "$FORGE2" == "true" ] && [ "$FORGE3" == "true" ] && [ "$FORGE4" == "true" ] ) || ( [ "$FORGE1" == "true" ] && [ "$FORGE2" == "true" ] && [ "$FORGE3" == "true" ] ) || ( [ "$FORGE1" == "true" ] && [ "$FORGE2" == "true" ] && [ "$FORGE4" == "true" ] ) || ( [ "$FORGE2" == "true" ] && [ "$FORGE3" == "true" ] && [ "$FORGE4" == "true" ] ) || ( [ "$FORGE1" == "true" ] && [ "$FORGE2" == "true" ] ) || ( [ "$FORGE1" == "true" ] && [ "$FORGE3" == "true" ] ) || ( [ "$FORGE1" == "true" ] && [ "$FORGE4" == "true" ] ) || ( [ "$FORGE2" == "true" ] && [ "$FORGE3" == "true" ] ) || ( [ "$FORGE2" == "true" ] && [ "$FORGE4" == "true" ] ) || ( [ "$FORGE3" == "true" ] && [ "$FORGE4" == "true" ] );
    then
    	echo
        echo "Multiple servers forging"
    	diff=$(( $HEIGHT - $HEIGHT1 ))
    	diff2=$(( $HEIGHT - $HEIGHT2 ))
    	diff3=$(( $HEIGHT - $HEIGHT3 ))
        if [ "$diff" -lt "3" ]
		then
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/enable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
            echo "Switching to $SRV1"
		elif [ "$diff2" -lt "3" ]
		then
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/enable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
			echo "Switching to $SRV2"
		elif [ "$diff3" -lt "3" ]
		then
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/enable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/disable
			echo "Switching to $SRV3"
	
		else
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV1""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV2""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV3""$PRTS"/api/delegates/forging/disable
			curl --connect-timeout 3 -k -H "Content-Type: application/json" -X POST -d '{"secret":'"$SECRET"'}' https://"$SRV4""$PRTS"/api/delegates/forging/enable
			echo "Switching to $SRV4"
		fi
    fi
    
    ## Sleep for 7 seconds
    sleep 7
done
