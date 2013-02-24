-- Written and assembled Neil Kelly, February 2013
-- Background: This script makes use of the Scansnap scanner software's ability to set marked text as keywords.
-- It gets called from Hazel for every PDF put into my scanned documents folder
-- If the keyword is a date, this script will try to massage it to YYYY-MM-DD format (or whatever you have set your Mac's short date format to be)
-- It then adds the formatted date, the month and the year to the Spotlight Comments of the file, prefixed with the @ symbol.
-- It also exports the formatted date as a token for Hazel to use - for example, I use it to rename the file. 

-- Tested date formats include
-- 02/25/2013
-- 02/25/13
-- February 25, 2013 * may have some difficulty due to the comma, which can cause the scanned keyword to be split in two

on hazelProcessfile(theFile)
  --Initialize the variables
	set theendresult to ""
	set thePath to POSIX path of theFile
	set theMetadata to metaDataRecord for theFile
	set theMoreInfo to kMDItemKeywords of theMetadata
	
	-- Loop through the keyowrds in the file
	-- Dates get transformed into short date format, month string and year
	-- Non-dates pass through untouched except for removign commas
	-- All keywords get prepended with @ passed along to the next step
	repeat with theKeyword in theMoreInfo
		
		-- replace commas. Commas are bad. 
		set theKeyword to replace_chars(theKeyword, ",", " ")
		try
			set thedatestring to date theKeyword
			set theYear to year of thedatestring
			set themonth to month of thedatestring
			set theday to day of thedatestring
			set theendresult to theendresult & " @" & (short date string of thedatestring) & " @" & theYear & " @" & themonth
			
		on error
			set theendresult to theendresult & " @" & theKeyword
		end try
		
	end repeat
	
	
	-- output results of above process to Spotlight Comments. 
	tell application "Finder"
		set this_item to theFile
		set item_name to (get displayed name of this_item)
		if item_name is not ".DS_Store" then
			set current_com to (get comment of this_item)
			if current_com does not contain theendresult then
				if current_com is "" then
					set comment of this_item to theendresult
				else
					set comment of this_item to (current_com & " " & theendresult) as string
				end if
			end if
		end if
	end tell
	
	-- Give back the date to Hazel to play with
	return {hazelExportTokens:{filedate:(short date string of thedatestring)}}
end hazelProcessfile

-- this subroutine from http://www.macosxautomation.com/applescript/sbrt/sbrt-06.html
on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars


-- originally written by Nigel Garvey 
-- https://secure.macscripter.net/viewtopic.php?id=39270&p=2
on metaDataRecord for fp
	-- Ensure that we have a quoted POSIX path to the file.
	if (fp's class is text) then
		if (fp does not start with "'/") then
			if (fp does not start with "/") then set fp to POSIX path of fp
			set fp to quoted form of fp
		end if
	else
		set fp to quoted form of POSIX path of (fp as alias)
	end if
	
	-- Get the metadata text and edit it almost to compilability, marking date entries with unlikely tags. ;)
	set rs to (do shell script ("mdls " & fp & " | sed -E '{
   s| *= |:| ;            # Colon instead of spaces and equals sign.
   s|\"|\\\\\"|g ;        # All double-quotes in each line escaped as if nested …
   s|\\\\\"|\"| ;        # … then the first …
   s|\\\\\"(,?)$|\"\\1| ;    # … and last returned to normal.
   s|^( +)([^\",]+)(,?)$|\\1\"\\2\"\\3| ;        # Indented text double-quoted if not already.
   s|\"?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}\"?|<McUsr>&</McUsr>| ;    # Dates tagged.
   s|\\($|{| ;            # Parentheses to …
   s|^\\)|}| ;            # … braces.
   s|^( .*\\|.*{)$|& ¬| ;    # Continuation chr at end of lines beginning with space or ending with left brace.
   $ ! s|[^¬]$|&, ¬| ;    # Comma & continuation at end of all other lines except the last.
   1 s|^|{| ;            # Left brace appended at beginning of first line.
   $ s|$|}| ;            # Right brace appended to end of last line.
   }'"))
	
	if ((count rs) > 0) then
		-- Replace the ISO dates with AppleScript dates transposed to the computer's time zone (if relevant) and coerced to text as per the local preferences. Requires AS 2.1 (Snow Leopard) or later for the multiple TIDs.
		set astid to AppleScript's text item delimiters
		set AppleScript's text item delimiters to {"<McUsr>", "</McUsr>"}
		set rs to rs's text items
		repeat with i from 2 to (count rs) by 2
			set dateString to item i of rs
			set item i of rs to "date \"" & getASDate(dateString) & "\""
		end repeat
		set AppleScript's text item delimiters to ""
		set rs to rs as text
		set AppleScript's text item delimiters to astid
		
		-- Return the "compiled" record.
		return (run script rs)
	else
		return {}
	end if
end metaDataRecord

-- Return an AppleScript date from a given ISO date/time with separators, ignoring the time-zone displacement.
-- from http://hints.macworld.com/dlfiles/spotlight_comment_script.txt
on getASDate(ISODate)
	tell (current date)
		set {day, {year, its month, day, its hours, its minutes, its seconds}} to {1, words 1 thru 6 of ISODate}
		return it
	end tell
end getASDate


