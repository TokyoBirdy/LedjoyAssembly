/*
 * snake.asm
 *
 *  Created: 2012-04-25 08:45:00
 *   Author: a09perna
 */ 


 //[En lista med registerdefinitioner] 
.DEF rTemp         = r16
.DEF rTemp2        = r17
.DEF rRowData		=r20
.DEF rRowNumber		=r22
.DEF rBufferB		=r23
.DEF rBufferC		=r24
.DEF rBufferD		=r25
.DEF rRandom		=r18
.DEF rReadX			=r19
.DEF rReadY			=r21
.DEF rAppleX		= r6
.DEF rAppleY		= r7
.DEF rRandom2		= r3
.DEF rLength        = r4
.DEF rAppleFlag		= r5

.DEF rAppleRandom	= r8
.DEF rAppleRandom2  =r11

.DEF rTemp3         = r9
.DEF rZero			= r10  
.DEF rDirection		= r15   

//[En lista med konstanter]
.EQU NUM_COLUMNS  = 8
.EQU MAX_LENGTH    = 25


//[Datasegmentet]

.DSEG
matrix:   .BYTE 8
snake:    .BYTE MAX_LENGTH+1
lastSnakePosX: .BYTE MAX_LENGTH+1
lastSnakePosY: .BYTE MAX_LENGTH+1

//[Kodsegmentet]

.CSEG

// Interrupt vector table
.ORG 0x0000
     jmp init // Reset vector

//... fler interrupts
.ORG INT_VECTORS_SIZE

init:

	
     // Sätt stackpekaren till högsta minnesadressen
     ldi rTemp, HIGH(RAMEND)
     out SPH, rTemp
     ldi rTemp, LOW(RAMEND)
     out SPL, rTemp


	 ldi rTemp, 0b00001111
	 out DDRC, rTemp
	 
	 ldi rTemp, 0b11111100
	 out DDRD, rTemp

	 ldi rTemp, 0b00111111
	 out DDRB, rTemp

	 
	ldi rTemp, 0
	mov rZero, rTemp

	mov rAppleFlag, rTemp
	mov rAppleRandom, rTemp

	 ldi YH,HIGH(matrix)
	 ldi YL,LOW(matrix)

	

	  // initialize A/D-omvandling
	  lds rTemp,  ADMUX
	  ori rTemp, 0b01000000
	  sts ADMUX, rTemp

	 lds rTemp, ADCSRA
	 ori rTemp, 0b10000111
	 sts ADCSRA,rTemp

	


	maininit:
		//ldi rRandom, 0b00010000
		rcall createSnake
		
		mainloop:
			rcall clearMatrix


			ldi rTemp2, 0 // 1 no apple 0 apple
			cp rAppleFlag,rTemp2	
			brne no_apple
			rcall createApple
			no_apple:
			rcall renderApple
			rcall eatApple  // check if snake can eat apple
			ldi YH,HIGH(matrix)
			ldi YL,LOW(matrix)	
			rcall move_Snake
			rcall renderSnake

			rcall killSnake
		
			
			rcall wait
			jmp mainloop

clearMatrix:
	
	ldi YH,HIGH(matrix)
	ldi YL,LOW(matrix)

	
	ldi rTemp2,8
	
	clearMatrix_loop:
		ldi rTemp, 0b00000000
		st Y, rTemp
		adiw Y,1
		dec rTemp2

		cpi rTemp2,0
		brne clearMatrix_loop
	 
	ret

	


// subrutine rRowData activates 
enableColumn://12


	mov rTemp, rRowData
	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp
	or rBufferD, rTemp  //+8

	


	mov rTemp, rRowData
	lsr rTemp
	lsr rTemp

	or rBufferB,rTemp  //+4

	ret

	//subrutine row activates
enableRow: //18
	mov rTemp, rRowNumber
	/*lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp

	lsr rTemp
	lsr rTemp
	lsr rTemp
	lsr rTemp*/
	andi rTemp, 0b00001111
	or rBufferC,rTemp // 0+1 =1  //+10 cycles


	mov rTemp, rRowNumber
	lsr rTemp
	lsr rTemp
	lsr rTemp
	lsr rTemp

	lsl rTemp 
	lsl rTemp  // --abcd

	or rBufferD, rTemp  //+8

	ret


paintMatrix: //403 cycles

	ldi rRowNumber, 0b00000001

	//initialize matrix address
	ldi YH,HIGH(matrix)
	ldi YL,LOW(matrix) //3

	paintMatrix_loop: //50*8

		ldi rBufferB,0
		ldi rBufferC,0
		ldi rBufferD,0 //3

		//
		ld rRowData, Y //2

		rcall enableRow // 3+18=21
		rcall enableColumn //3+12=15

		out PORTB, rBufferB
		out PORTC, rBufferC
		out PORTD, rBufferD //3

		adiw Y,1 //2 
		lsl rRowNumber //1

		cpi rRowNumber, 0 //1
		
		brne paintMatrix_loop //2
		nop
		
ret


wait: 
    ldi rTemp, 250
	
	wait_loop:
		push rTemp

		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix

		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix

		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix

		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix
		rcall paintMatrix

		pop rTemp
		dec rTemp
		cpi rTemp, 0
		brne wait_loop

ret


			// läs in joystick y axil 
readStickY:
	
			lds rReadY,ADMUX 
			lsr rReadY
			lsr rReadY
			lsr rReadY
			lsr rReadY
			lsl rReadY
			lsl rReadY
			lsl rReadY
			lsl rReadY
			ori rReadY, 0b00000100 // y axil 
			sts ADMUX, rReadY 

ret 

readStickX:
			lds rReadX,ADMUX 
			lsr rReadX
			lsr rReadX
			lsr rReadX
			lsr rReadX
			lsl rReadX
			lsl rReadX
			lsl rReadX
			lsl rReadX
			ori rReadX, 0b00000101 // x axil 
			sts ADMUX, rReadX 
ret


activateAD_X:
			rcall readStickX
			
				//  ändra från 10 bitar till 8 bitar 
			lds rTemp, ADMUX
			ori rTemp, 0b00100000
			sts ADMUX, rTemp
			
			
	// Aktivera A/D-omvandling
			lds rTemp, ADCSRA
			ori rTemp, 0b01000000
			sts ADCSRA, rTemp


	// Iterera tills ADSC-biten =0
	iterateLopp:
			lds rTemp,ADCSRA
			sbrc rTemp, 6
			rjmp iterateLopp
			lds rTemp, ADCH
			add rAppleRandom, rTemp
			add rAppleRandom2, rTemp

ret 


activateAD_Y:
			rcall readStickY
			
				//  ändra från 10 bitar till 8 bitar 
			lds rTemp, ADMUX
			ori rTemp, 0b00100000
			sts ADMUX, rTemp
			
			
	// Aktivera A/D-omvandling
			lds rTemp, ADCSRA
			ori rTemp, 0b01000000
			sts ADCSRA, rTemp


	// Iterera tills ADSC-biten =0
			iterateLoop:
				lds rTemp,ADCSRA
				sbrc rTemp, 6
				rjmp iterateLoop

			lds rTemp, ADCH
			add rAppleRandom, rTemp
			add rAppleRandom2, rTemp
ret 

createSnake:
		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)

		ldi rTemp, 0b01000100
		st X+,rTemp

		//adiw X,1 
		ldi rTemp, 0b01000101 
		st X+,rTemp

		//adiw X,1 
		ldi rTemp, 0b01000110
		st X+,rTemp


		//adiw X,1 
		ldi rTemp, 0b01000111 
		st X+,rTemp
		
		ldi rTemp, 4
		mov rLength, rTemp

		ret


renderSnake:


		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)
		// the length 
		mov rTemp3, rLength
		

		snake_loop:


	//	loop_X_rows:
		ld rTemp, X
		andi rTemp, 0b00001111

	
	 // spara hägre 4 siffror Y coordinator 

		ld rTemp2, X
		lsr rTemp2
		lsr rTemp2
		lsr rTemp2
		lsr rTemp2 //spara vänstra 4 siffror X coordinator 

		
		ldi YH,HIGH(matrix)
		ldi YL,LOW(matrix)

		// läsa in 4 siffror Y coordinator till matrix 
		ldi rRandom,0
		cp rTemp, rRandom
		breq checkPosition_loop_end

		checkPosition_loop:
			adiw Y, 1
			inc rRandom
			cp rTemp, rRandom // rTemp 0b00000100==rRandome=4 ..... rRandom 0, 1, 2=0b00000010 3 =0b000000011   * 0b00000100=4
			brne checkPosition_loop
		checkPosition_loop_end:
			// st Y, rTemp


		// läsa in X coordinator 4 siffror

		ldi rReadY, 0b10000000
		ldi rRandom, 0
		cp rTemp2,rRandom // rTemp2 X
		breq shiftX_loopEnd

			shiftX_loop:
				lsr rReadY
				inc rRandom
				cp rTemp2,rRandom // rRandom 2 ..., rtemp2 0b00000010,
				brne shiftX_loop 

		
		shiftX_loopEnd:
		
		//loop_Y:
		

		ld rTemp, Y
		or rTemp, rReadY
		st Y, rTemp   // högre 4 siffror --x coordinator 

		adiw X,1
		
		dec rTemp3
		cp rTemp3,rZero
		brne snake_loop


ret

move_Snake:

		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)

		// pekar på den sista i snaken
		add XL, rLength
		adc XH,rZero
		sbiw X,1 

	
		mov YH,XH
		mov YL,XL
		sbiw Y,1 // nästa sista i snaken

		 mov rTemp, rLength
		 dec rTemp
	loop_snake:
		  
		ld rTemp2, Y
		st X, rTemp2

		sbiw X, 1
		sbiw Y, 1

		dec rTemp
		cpi rTemp, 0
		brne loop_snake // save the x, y position to the lastSnakePos

// lägg till huvud

			rcall activateAD_X
			ldi rTemp2, 1
			cp rDirection, rTemp2 //right
			breq doNotGoLeft
			cpi rTemp, 100
			brsh doNotGoLeft // same or higher 
				ldi rTemp2,0
				mov rDirection, rTemp2 // left
				jmp Direction_end
			doNotGoLeft:
			
			ldi rTemp2, 0
			cp rDirection, rTemp2
			breq doNotGoRight
			cpi rTemp, 150
			brlo doNotGoRight // lower 
				ldi rTemp2,1
				mov rDirection, rTemp2  // right
				jmp Direction_end
			doNotGoRight:


			rcall activateAD_Y
			
			ldi rTemp2, 3
			cp rDirection, rTemp2
			breq doNotGoUp
			cpi rTemp, 100
			brsh doNotGoUp // same or higher 
				ldi rTemp2,2
				mov rDirection, rTemp2  // up
				jmp Direction_end
			doNotGoUp:

			ldi rTemp2, 2
			cp rDirection, rTemp2
			breq doNotGoDown
			cpi rTemp, 150
			brlo doNotGoDown // lower
				ldi rTemp2,3
				mov rDirection, rTemp2  // down
				jmp Direction_end
			doNotGoDown:

		Direction_end:
			ldi XH, HIGH(snake)
			ldi XL, LOW(snake)
			ld rTemp3, X

			ldi rTemp2, 0
			cp rDirection, rTemp2
			breq move_to_left
			ldi rTemp2, 1
			cp rDirection, rTemp2
			breq move_to_right
			ldi rTemp2, 2
			cp rDirection, rTemp2
			breq move_to_up
			jmp move_to_down
			
			move_to_left:
			ldi rTemp, 0b10001000
			or rTemp3, rTemp
			ldi rTemp, 0b00010000//rTemp-16
			sub rTemp3, rTemp
			jmp move_to_end

			move_to_right:
			ldi rTemp, 0b01110111
			and rTemp3, rTemp
			ldi rTemp, 0b00010000
			add rTemp3, rTemp
			jmp move_to_end

			move_to_up:
			ldi rTemp, 0b01110111
			and rTemp3, rTemp
			ldi rTemp, 0b00000001  
			add rTemp3, rTemp
			jmp move_to_end

			move_to_down:
			ldi rTemp, 0b10001000
			or rTemp3, rTemp
			ldi rTemp, 0b00000001
			sub rTemp3, rTemp
			move_to_end:

			// dont not go outside of 8 bits 
			ldi rTemp, 0b01110111
			and rTemp3, rTemp
			st X, rTemp3
ret


		

createApple:
		
	

	   ldi rTemp2, 0b01110111
	   and rAppleRandom, rTemp2
	
		ldi rRandom, 0b01110000
		and rAppleRandom, rRandom
		lsr rAppleRandom
		lsr rAppleRandom
		lsr rAppleRandom
		lsr rAppleRandom
		mov rAppleX,rAppleRandom //
		

		 ldi rTemp2, 0b01110111
		 and rAppleRandom, rTemp2
		

		//y 
	   ldi rTemp2, 0b01110111
	   and rAppleRandom2, rTemp2
	
		ldi rRandom, 0b00000111
		and rAppleRandom2, rRandom
		mov rAppleY,rAppleRandom //


		// chech if apples position is in snakes body
		mov rTemp2,rLength
		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)
		
		loop_through_snake:
				ld rTemp, X
		andi rTemp, 0b00001111
		mov rReadY,rTemp // y position

		

		ld rTemp, X
		andi rTemp, 0b11110000
		lsl rTemp
		lsl rTemp
		lsl rTemp
		lsl rTemp
		mov rReadX, rTemp

		cp rReadX, rAppleX
		brne no_change

		// orelse check y
		cp rReadY, rAppleY
		brne no_change
		// in the snake
		inc rApplex  // move one step to the right


		no_change:
		adiw X,1
		dec rTemp2

		cp rTemp2, rZero
		brne loop_through_snake


		
			

		

		
		
ret

renderApple:

		ldi YH,HIGH(matrix)
		ldi YL,LOW(matrix)

		// läsa in 4 siffror Y coordinator till matrix 
		ldi rRandom,0
		cp rAppleY, rRandom
		breq Apple_loop_End

		Apple_loop:
			adiw Y, 1
			inc rRandom
			cp rAppleY, rRandom 
			brne Apple_loop
		Apple_loop_End:
	

		// läsa in X coordinator 4 siffror

		ldi rReadX, 0b10000000
		ldi rRandom, 0
		cp rAppleX,rRandom // rTemp2 X
		breq Apple_loop_X_end

			shift_X_loop:
				lsr rReadX
				inc rRandom
				cp rAppleX,rRandom //
				brne shift_X_loop 
		
		Apple_loop_X_end:		

		ld rTemp, Y
		or rTemp, rReadX
		st Y, rTemp   // högre 4 siffror --x coordinator 

		ldi rTemp2,1
		mov rAppleFlag,rTemp2
ret


eatApple:

		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)
		ld rRandom, X
		andi  rRandom, 0b11110000
		lsr rRandom
		lsr rRandom
		lsr rRandom
		lsr rRandom


		cp rRandom, rAppleX // x position 
		brne to_the_end

		
		check_Y_position:

		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)

		ld rTemp2, X
		andi rTemp2, 0b00001111  // y position

		cp rTemp2, rAppleY
		brne to_the_end

		
		eat_up_Apple:

		inc rLength

		mov rTemp, rAppleX
		andi rTemp, 0b00001111
		lsl rTemp
		lsl rTemp
		lsl rTemp
		lsl rTemp

		mov rTemp2,rAppleY
		andi rTemp2, 0b00001111

		or rTemp, rTemp2 //innehåller apples posistion x och y


		add XL, rLength
		adc XL,rZero
		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)

		
		st X, rTemp

		ldi rTemp, 0
		mov rAppleFlag, rTemp
		
		to_the_end:


ret


killSnake:
		
		ldi XH, HIGH(snake)
		ldi XL, LOW(snake)

		ld rTemp, X // load head position

		mov rRandom, rLength
		dec rRandom

		mov YH,XH
		mov YL,XL
		adiw Y,1
		//check_death:

		loop_snake_body:
		  
		ld rTemp2, Y
		cp rTemp, rTemp2
		brne no_death

		// death
		jmp init

		no_death:
		adiw Y, 1

		dec rRandom
		cpi rRandom, 0  //0bxxxxyyyy

		
		brne loop_snake_body 

		


ret

