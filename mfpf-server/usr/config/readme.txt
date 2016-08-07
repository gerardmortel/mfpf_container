This folder contains the server configuration fragments (keystore, server properties, user registry) used by MobileFirst Server Foundation.

   i) keystore.xml - the configuration of the repository of security certificates used for SSL encryption. The files listed must be referenced in the ./usr/security folder.
  ii) mfpfproperties.xml - Configuration properties for the MobileFirst Server Foundation. 
 iii) registry.xml - user registry configuration. The basicRegistry (a basic XML-based user-registry configuration) is provided as the default. User names and passwords can be configured for basicRegistry or you can configure ldapRegistry.
  iv) dataproxy.xml - Configuration properties for the dataproxy component. Uncomment the text in the dataproxy.xml and provide the necessary property values.
   v) Your database configuration files will be stored in this directory after you run the prepareserverdbs.sh script.