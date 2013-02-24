GetDateFromPDFMetadata
======================

A quick Applescript to manipulate date information stored in PDF metadata.

The Scansnap scanner software will allow you to saved highlighted text in a scanned document as keywords. 
This script is called from Hzel. It takes those keywords, searches for any that are dates and formats them to the short date format. It also returns all the keywords (plus the month and year from any dates it finds) as Spotlight Comments prefixed with '@'. Finally, it returns the short date string as a Hazel export token for use in further rules. 

I have tested it with a handful of date formats which have worked. 

Quesitons/comments/etc: github@neilbert.com
