TITLE Creating low-level I/O procedures    (Project06.asm)

; Author: Donald Drummond
; Last Modified: 14MAR2020
; OSU email address: drummond@oregonstate.edu
; Course number/section: CS 271-400 W2020
; Project Number: 06                 Due Date: 15MAR2020
; Description: This program will introduce the programmer
; and title, then provide brief instructions to the user
; and ask the user to input ten signed decimal integers. 
; The program will then output the list of entered integers,
; the sum of the integers and the rounded average.

INCLUDE Irvine32.inc


displayString		MACRO string
	push			edx
	mov				edx, string
	call			WriteString
	pop				edx
ENDM

getString			MACRO prompt, input, lenInput
	push			edx
	push			ecx
	displayString	prompt
	mov				ecx, lenInput
	mov				edx, input
	call			ReadString
	pop				ecx
	pop				edx
ENDM

.data

programTitle				BYTE	"Creating low-level I/O procedures", 0
programmerName				BYTE	"Programmed By: Don Drummond", 0
instructions1				BYTE	"Please input ten signed decimal integers that are small enough to fit in a 32 bit regiters.",0
instructions2				BYTE	"Then I'll show you a list of the integers as well as their sum and average.",0
enterInput					BYTE	"Enter a signed decimal integer: ",0
errorInput					BYTE	"Your input wasn't a signed number or your number was too large.",0
tryAgain					BYTE	"Try again: ",0
integersEntered				BYTE	"The signed decimal integers you entered:",0
sumIntegersEntered	        BYTE	"The sum of these integers is: ",0
averageIntegersEntered		BYTE	"The rounded average of these integers is: ",0
goodbyeMessage				BYTE	"Hope you enjoyed the numbers!", 0
userInputInteger			DWORD	0					;to hold the integer after validation
countIntegers				DWORD	0					;track how many valid integers have been entered
userInputs					BYTE	200		DUP(0)		;to hold the users input
userInputArray				DWORD	10		DUP(?)		;create empty array of 10 items for signed decimal integers entered by the user
sumUserInput				DWORD	?					;to hold the sum of the user's input
averageUserInput			DWORD	?					;to hold the average of the user's input
outputString				BYTE	50		DUP(0)		;to handle string output
spacing						BYTE	", ",0

.code


main PROC	

	push			OFFSET				programTitle
	push			OFFSET				programmerName
	push			OFFSET				instructions1
	push			OFFSET				instructions2
	call			introduction

	push			countIntegers								;to track how many valid integers have been entered
	push			userInputInteger							;the integer to hold validated user input
	push			OFFSET				tryAgain				;try again prompt
	push			OFFSET				userInputArray			;array to hold valid input
	push			OFFSET				errorInput				;error message for bad input
	push			LENGTHOF			userInputs				;length of string to hold user input
	push			OFFSET				userInputs				;string to hold user input
	push			OFFSET				enterInput				;user prompt
	call			readVal

	push			OFFSET				outputString
	push			OFFSET				spacing
	push			OFFSET				integersEntered
	push			OFFSET				sumIntegersEntered
	push			OFFSET				averageIntegersEntered			
	push			OFFSET				userInputArray
	push			sumUserInput
	push			averageUserInput
	call			displayValues

	push			OFFSET				goodbyeMessage		
	call			farewell


	exit	; exit to operating system
main ENDP

;------------------------------------
;introduction
;
; description: an introduction to of the program title
; and programmer
; receives: programTitle, programmerName, instructions(1,2)
; returns: prints program title and programmer's name
; to the screen, the instructions of what the program does
; and the extra credit 
; preconditions: none
; registers changed: none
;------------------------------------
introduction		PROC
	push	ebp
	mov		ebp, esp
	pushad
	displayString		[ebp+20]		;programTitle
	call	CrLf
	displayString		[ebp+16]		;programmerName
	call	CrLf
	displayString		[ebp+12]		;instructions1
	call	CrLf
	displayString		[ebp+8]			;instructions2
	call	CrLf
	popad
	pop		ebp
	ret 16								;reset the stack
introduction		ENDP

;------------------------------------
;readVal
;
; description: gets input of a user's string by the getString macro, it
; also validates that the user's input can fit within a 32 bit register
; and is a signed decimal integer
; receives: prompt, userInput, and length of userInput
; returns: 
; registers changed: ? 
;------------------------------------
readVal				PROC
	push		ebp
	mov			ebp, esp
	pushad
	call		CrLf
	mov			ebx, [ebp+36]
	cmp			ebx, 40							;stop adding numbers when 10 have been inputted
	je			doneAdding
badInput:
	getString	[ebp+8], [ebp+12], [ebp+16]		;input prompt, userInput, length userInput	
	push		[ebp+36]
	push		[ebp+32]
	push		[ebp+28]
	push		[ebp+24]						;push valid numeric array
	push		[ebp+20]						;push error message
	push		[ebp+16]						;push the LENGTHOF userInput on the stack
	push		[ebp+12]						;push the OFFSET of userInput on the stack
	push		[ebp+8]							;push user prompt
	call		convertStringToNumeric

doneAdding:
	popad
	pop			ebp
	ret			32
readVal				ENDP

;------------------------------------
;convertStringToNumeric
;	
; description: converts a string of digits to integers, 
; additionally validates that the string is valid input
; it may lead with + or -, but the rest must be numeric
; receives: receives the same 
; returns: 
; registers changed: none
;------------------------------------
convertStringToNumeric				PROC
	push			ebp
	mov				ebp, esp
	pushad
badInput:
	mov				ecx, [ebp+16]					;load LENGTHOF userInput into ecx to loop
	mov				esi, [ebp+12]					;address of userInput into ESI for lodsb
	mov				edi, [ebp+24]					;load the address of userInputAddress
	mov				edx, [ebp+32]		

loadString:	
	cld												;direction flag forward
	lodsb											;load byte at ESI into AX
	cmp				ax, 43							;handle + signs
	je				handleSign
	cmp				ax, 45							;handle - signs
	je				handleSign
signHandled:
	cmp				ax, 0							;determine if at the end of the string
	je				endString
	cmp				ax, 48							;to ensure the character is numeric
	jl				notValid						;check if it is within ASCII values
	cmp				ax, 57							;48 <= char <= 57
	ja				notValid
	imul			edx, 10							;multiple userInputInteger by 10 to align integers properly	
	sub				ax, 48							;to get the actual integer subtract 48
	add				edx, eax
	loop			loadString
handleSign:
	cmp				ecx, [ebp+16]					;if it is the first character
	jne				notValid						;if a + or - is entered on a character other than the first
	dec				ecx
	cmp				ax, 43							;loop to decrement ecx for the +, as we can skip a plus
	je				loadString						;loop to decrement ecx for the +
	cmp				ax, 45							;number needs to be be negated as it is negative
	je				loadNegString					

notValid:
	displayString	[ebp+20]						;error message
	call			CrLf
	displayString	[ebp+28]						;try again message
	call			CrLf
	getString		[ebp+8], [ebp+12], [ebp+16]		;input prompt, userInput, length userInput
	jmp				badInput
	
loadNegString:
	cld												;direction flag forward
	lodsb											;load byte at ESI into AX
	cmp				ax, 43							;handle + signs
	je				handleSign
	cmp				ax, 45							;handle - signs
	je				handleSign
	cmp				ax, 0							;determine if at the end of the string
	je				endNegString
	cmp				ax, 48							;to ensure the character is numeric
	jl				notValid						;check if it is within ASCII values
	cmp				ax, 57							;48 <= char <= 57
	ja				notValid
	imul			edx, 10							;multiple userInputInteger by 10 to align integers properly	
	sub				ax, 48							;to get the actual integer subtract 48
	add				edx, eax
	loop			loadNegString

endNegString:
	neg				edx
	jmp				endString

endString:
	cmp				ecx, [ebp+16]					;handle if the user just hits enter
	je				notValid
	mov				[edi+ebx], edx
	mov				ebx, [ebp+36]					;to track that we are getting 10 valid integers
	add				ebx, 4
	mov				[ebp+36], ebx
	push			[ebp+36]
	push			[ebp+32]						;variable to hold the validated user input
	push			[ebp+28]						;try again variable
	push			[ebp+24]						;push valid numeric array
	push			[ebp+20]						;push error message
	push			[ebp+16]						;push the LENGTHOF userInput on the stack
	push			[ebp+12]						;push the OFFSET of userInput on the stack
	push			[ebp+8]							;push input prompt
	call			readVal

	popad
	pop			ebp
	ret			32
convertStringToNumeric				ENDP

;------------------------------------
;writeVal
;	
; description: displays converts a numeric value to a string of digits
; by invoking the displayString maco
; receives: integer to convert, empty string variable 
; returns: an integer as as string
; registers changed: none
;------------------------------------
writeVal				PROC
	push				ebp
	mov					ebp, esp
	pushad
	mov					eax, [ebp+8]				;put integer to convert into eax
	mov					edi, [ebp+12]				;location to store string in ESI
	mov					ebx, 10						;to generate value, must divide by 10
	mov					ecx, 0



	call				WriteInt



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Partial implementation of converting digit to string
;commented out because it was not functioning completely
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;generateChar:
;	cdq
;	div					ebx
;	push				edx
;	inc					ecx							;count numbers pushed
;	cmp					eax, 0						;end of value to process
;	jne					generateChar



;outputChar:
;	pop					eax
;	cmp					eax, 43						;skip a + sign
;	je					skipSigns					
;	cmp					eax, 45
;	je					skipSigns					;skip a - sign
;	add					eax, 48						;get ASCII value
;	mov					[edi], eax
;	inc					edi
;	loop				outputChar

;skipSigns:
;	dec					ecx
;	jmp					outputChar

;	displayString		[epb+12]

	popad
	pop					ebp
	ret					8
writeVal				ENDP


;------------------------------------
;displayValues
;
; description: displays a list of integers input by the user
; displays the sum of the integers, displays the average of the integers
; receives: multiple prompt messages, userInputArray,
; sumUserInput, averageUserInput
; returns: output of the list of integers, sum of integers,
; and average of integers
; registers changed: none
;------------------------------------
displayValues			PROC
	push				ebp
	mov					ebp, esp
	pushad
	mov					edi, [ebp+16]			;address of the array of valid inputs
	mov					ecx, 10					;loop count to process array
	mov					ebx, 0					;clear ebx to hold sum
	
	call				CrLf
	displayString		[ebp+28]				;integersEntered
	call				CrLf
processInputs:
	mov					eax, [edi]
	push				[ebp+36]				;string to hold the converted number
	push				eax						;integer to convert to a string
	call				writeVal
	mov					edx, [ebp+32]			;add comma and spacing
	call				WriteString
	add					ebx, eax				;sum inputs
	add					edi, 4
	loop				processInputs
	

	call				CrLf
	call				CrLf
	displayString		[ebp+24]				;sumIntegersEntered
	push				[ebp+36]
	push				ebx
	call				writeVal

	call				CrLf
	call				CrLf
	displayString		[ebp+20]				;averageIntegersEntered
	mov					eax, ebx				;sum to eax for division
	mov					ebx, 10					;to calculate average
	cdq
	idiv				ebx
	push				[ebp+36]
	push				eax
	call				writeVal

	popad
	pop					ebp
	ret					32
displayValues			ENDP

;------------------------------------
;farewell
;
; description: a farewell message to the user
; receives: goodbyeMessage
; returns: prints goodbye message to the screen
; registers changed: edx
;------------------------------------
farewell			PROC
	push				ebp
	mov					ebp, esp
	call				CrLf
	displayString		[ebp+8]			;goodbyeMessage
	call				CrLf
	pop					ebp
	ret					4
farewell			ENDP

END main