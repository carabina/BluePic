/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import Kitura
import KituraNet
import KituraSys
import CouchDB
import LoggerAPI
import HeliumLogger
import Credentials
import CredentialsFacebookToken
import CredentialsGoogleToken
import SwiftyJSON

///
/// Because bridging is not complete in Linux, we must use Any objects for dictionaries
/// instead of AnyObject. The main branch SwiftyJSON takes as input AnyObject, however
/// our patched version for Linux accepts Any.
///
#if os(OSX)
    typealias JSONDictionary = [String: AnyObject]
#else
    typealias JSONDictionary = [String: Any]
#endif

do {
  // Logger
  Log.logger = HeliumLogger()

  // Get Configuration object (and properties)
  let config = try Configuration()
  let dbClient = CouchDBClient(connectionProperties: config.couchDBConnProps)
  let database = dbClient.database(config.couchDBName)

  // Create router instance
  let router = Router()

  // Create authentication credentials middlewares
  let fbCredentials = CredentialsFacebookToken()
  let googleCredentials = CredentialsGoogleToken()
  let credentials = Credentials()
  credentials.register(fbCredentials)
  credentials.register(googleCredentials)

  // Define routes
  definePhotoRoutes(router, credentials: credentials, database: database)

  // Start server...
  let server = HttpServer.listen(8090, delegate: router)
  Server.run()
} catch Configuration.Error.IO {
  Log.error("Oops, something went wrong... Server did not start!")
}