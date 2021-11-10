#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

OLD_VERSION="$1"
NEW_VERSION="$2"


HERE=` basename "$PWD"`
if [[ "$HERE" != "tools" ]]; then
    echo "Please only execute in the tools/ directory";
    exit 1;
fi

# change version in all pom files
find .. -name 'pom.xml' -type f -exec perl -pi -e 's#<version>'"$OLD_VERSION"'</version>#<version>'"$NEW_VERSION"'</version>#' {} \;

# change version of the quickstart property
find .. -name 'pom.xml' -type f -exec perl -pi -e 's#<flink.version>'"$OLD_VERSION"'</flink.version>#<flink.version>'"$NEW_VERSION"'</flink.version>#' {} \;
