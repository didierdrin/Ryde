# uCrop (image_cropper) optionally references OkHttp; app does not use it.
# Tell R8 to ignore missing OkHttp classes so release build succeeds.
-dontwarn okhttp3.**
-dontwarn okio.**
