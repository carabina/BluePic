#!/bin/bash

##
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

# If any commands fail, we want the shell script to exit immediately.
set -e

#https://<access point>/<API version>/AUTH_<project ID>/<container namespace>/<object namespace>
#https://dal.objectstorage.open.softlayer.com/v1/AUTH_742fffae2c24438b83a2c43491119a82

# Parse input parameters
source ./parse_inputs.sh

# Variables
authUrl=https://identity.open.softlayer.com/v3/auth/tokens
accessPoint=dal.objectstorage.open.softlayer.com
publicUrl=https://$accessPoint/v1/AUTH_$projectid

# Containers
container1=100002031687931a
container2=100002031687932b
container3=100002031687933c

# Echo publicUrl
echo "publicUrl: $publicUrl"

# Get access token
authToken=`curl -i -H "Content-Type: application/json" -d "{ \"auth\": { \"identity\": { \"methods\": [ \"password\" ], \"password\": { \"user\": { \"id\": \"$userid\", \"password\": \"$password\" } } }, \"scope\": { \"project\": { \"id\": \"$projectid\" } } } }" $authUrl | grep X-Subject-Token | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`

# Create and configure containers
declare -a containers=($container1 $container2 $container3)

for container in "${containers[@]}"; do
  echo "container: $container"
  # Create container
  curl -i $publicUrl/$container -X PUT -H "Content-Length: 0" -H "X-Auth-Token: $authToken"

  # Configure container for web hosting
  curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Meta-Web-Listings: true"

  # Configure container for public access
  curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Read: .r:*,.rlistings"
done

# Upload image sto containers
imagesFolder=`dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`/images
echo "imagesFolder: $imagesFolder"
declare -a images=("$container1:rush.jpg:image/jpg" "$container2:rush.jpg:image/jpg" "$container3:rush.jpg:image/jpg")

for record in "${images[@]}"; do
  IFS=':' read -ra image <<< "$record"
  container=${image[0]}
  fileName=${image[1]}
  contentType=${image[2]}
  echo "container: $container"
  echo "fileName: $fileName"
  echo "contentType: $contentType"
  curl -i $publicUrl/$container/$fileName --data-binary @$imagesFolder/$fileName -X PUT -H "Content-Type: $contentType" -H "X-Auth-Token: $authToken"
done

echo
echo "Successfully finished populating object storage."