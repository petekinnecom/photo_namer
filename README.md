This script uses the EXIF timestamp to rename photos.  For example, the photo `DCIM80012.JPG` becomes `2014-08-09 08.22.19.jpg`

When a collision is found, it will append a counter.  For example, `2014-08-09 08.22.19 2.jpg`.

The script is not destructive.  It copies the files rather than renaming them.

Usage:

~~~bash
ruby photo_renamer.rb /path/to/input_folder/ /path/to/output_folder/
~~~
