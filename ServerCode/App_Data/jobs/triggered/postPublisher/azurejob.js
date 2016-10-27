var express = require('express'),
    azureMobileApps = require('azure-mobile-apps');

var app = express(),
    mobile = azureMobileApps();

var sql = require('mssql');
sql.connect(mobile.configuration.data).then(function() {
    console.log("connected");
    var request = new sql.Request();
    request.query("UPDATE [dbo].[Post] SET published=1, publicationRequested=0 WHERE publicationRequested = 1").then(function(recordset) {
        console.log("Rows updated:" + request.rowsAffected);
    });
 }).catch(function(err) {
    console.log("Failed to connect");
});   

/*mobile.data.execute(query)
.then(function (results) {
    console.log("Query ejecutada");
});*/