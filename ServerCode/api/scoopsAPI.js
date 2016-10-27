
module.exports = {
    "post": function (req, res, next) {
        try {
            var postId = req.query["post_id"];
            if (postId) {
    
                var query = {
                    sql: "UPDATE [dbo].[Post] SET readings=readings+1 WHERE id = '" + postId + "'"
                };
                
                req.azureMobile.data.execute(query)
                .then(function (results) {
                    res.status(200).type('application/json').send({"result": "OK"});
                });
            } else {
                res.status(200).type('application/json').send({"result": "ERROR: Invalid parameters"});
            }
        } catch (exc) {
            res.status(200).type('application/json').send({"result": "ERROR: " + exc.message});
        }
    }
};
