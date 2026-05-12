// Facebook SDK for web
window.fbAsyncInit = function() {
  FB.init({
    appId: '741961928192956',
    cookie: true,
    xfbml: true,
    version: 'v18.0'
  });
  console.log('✅ Facebook SDK initialized');
};

(function(d, s, id){
   var js, fjs = d.getElementsByTagName(s)[0];
   if (d.getElementById(id)) {return;}
   js = d.createElement(s); js.id = id;
   js.src = "https://connect.facebook.net/en_US/sdk.js";
   fjs.parentNode.insertBefore(js, fjs);
 }(document, 'script', 'facebook-jssdk'));