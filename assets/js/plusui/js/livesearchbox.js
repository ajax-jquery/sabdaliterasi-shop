!function(a){function e(a){return a.split(" ").join("").toLowerCase()}function s(e){return a.getElementById(e)}var i=s("sitemap5");function n(){e(s("searchIn").value)&&i.classList.remove("hidden")}s("searchIn").addEventListener("keyup",function(){!function e(){if(s("liveSearchCSS"));else{var i=a.createElement("link");i.rel="stylesheet",i.id="liveSearchCSS",i.async=!0,i.href="https://sabdaliterasi.shop/assets/js/plusui/css/livesearchbox.css";var n=a.getElementsByTagName("script")[0].parentNode.insertBefore(i,n)}}();var n=s("badan");n.innerHTML="<li>Loadiang...</li>";var t=e(s("searchIn").value),r=RegExp(t,"i");t?fetch("https://sabdaliterasi.shop/liveser.json").then(a=>a.json()).then(a=>{for(var s="",t=0;t<a.length;t++)if(-1!=e(a[t].nama_mahasiswa).search(r)||-1!=e(a[t].alamat).search(r)){var l=a[t].alamat;s+='<li class="list-produk serrcok"><p class="ajax-search-image loading"><img class="lazyload" src="'+a[t].avatar+'?width=60&height=60" alt="'+a[t].nama_mahasiswa+'" style="display:block;width:60px;height:60px;"></p><h4 class="ajax-search-title"><a title="'+a[t].nama_mahasiswa+" | "+a[t].alamat+'" href="'+a[t].link+'"><strong>'+a[t].nama_mahasiswa+"</strong><p>"+l+"</p></a></h4></li>"}else s+="";i.classList.remove("hidden"),""==s?n.innerHTML='<li id="focus">Maaf Artikel atau Ebook yang Anda cari belum kami input.<br>HUBUNGI Admin UNTUK REQUEST Artikel atau Ebook<br><a href="#" onclick="pesanWa(\'Halo Min\')" style="border: 2px solid; display: block; margin: 7px; padding: 2px; font-weight: 600;">KLIK DISINI</a></li>':n.innerHTML=s}):(n.innerHTML="",i.classList.add("hidden"))}),document.addEventListener("click",function(){s("searchIn").activeElement?n():document.querySelector("#searchIn:focus")?n():i.classList.add("hidden")})}(document);
