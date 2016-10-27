
module.exports = {
    "get": function(req, res, next) {
        var currentUser = req.azureMobile.user;
        currentUser.getIdentity().then(function (identities) { 
            var user = {
                id: identities.facebook.user_id
            };
            
            for (var i = 0; i < identities.facebook.user_claims.length; i++) {
                var claim = identities.facebook.user_claims[i];
                if (claim.typ.indexOf("/name") != -1) {
                    user.name = claim.val;
                }
            }
            
            console.log("Identidad:");
            console.log(user);    
            
            res.status(200).type('application/json').send(user);
        });
    }
};
