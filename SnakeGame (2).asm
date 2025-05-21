.Model Small
.Stack 100h
.Data
    ;Tieu de game
    snakeTitle DB 'S','N','A','K','E' 
    startText DB 'Press any key to start...' 

    ;Dia chi cua thuc an
    foodAddress DW ?   
    
    ;Cac thuoc tinh cua ran
    startPosition equ 1000 ;Vi tri giua man hinh
    snakeAddress DW startPosition, 100 Dup(0) ;Dia chi bat dau cua ran
    snakeChars DB '0',100 Dup(0) ;Cac ki tu cua ran
    snakeLength DB 1 ;Do dai cua ran
    
    ;Thong tin man choi
    scoreText DB "Score: $" ;Text diem so
    scoreCount DB 0 ;Gia tri diem so
    gameOverText DB "Game Over" ;Text Game Over
    optionText DB "Restart ? (Y / N)" ;Text Options
    
    twoConst DW 2   
    mapSize DW 1755 
    screenWidth DW 80 
    

.Code  
    ;Khoi tao
    initialize:
    MOV AX, @Data
    MOV DS, AX    
                                                                    
    MOV AX, 0b800h
    MOV ES, AX    
    
    
    MOV AH, 0   
    MOV AL, 0   
    INT 10h     
    
    CLD 
    
    ;An con tro van ban
    MOV AH, 1
    MOV CH, 2BH
    MOV CL, 0BH   
    INT 10h     
    
    CALL mainMenu ;Goi ham hien thi menu chinh
                   
          
    ;Bat dau game               
    startGame: 
    CALL clearScreen   ;Xoa man hinh de bat dau tro choi moi
    
    MOV snakeAddress, startPosition ;Dat lai ran ve vi tri bat dau     
    CALL buildScreen ;Xay dung lai man choi voi ranh gioi, ran va thuc an
    
    XOR CL, CL 
    XOR DL, DL 
    readInput: ;Doc input
        MOV AH, 1
        INT 16H     
        JZ moveLeft  
        
        MOV AH, 0
        INT 16H       
        AND AL, 0dfh 
        MOV DL, AL    
    
    moveLeft: 
        CMP DL, 'A'
        JNE moveRight
        CALL moveLeftSnake 
        MOV CL, DL    
        JMP readInput       
        
    moveRight:
        CMP DL, 'D'
        JNE moveUp                  
        CALL moveRightSnake 
        MOV CL, DL     
        JMP readInput  
    
    moveUp: 
        CMP DL, 'W'
        JNE moveDown
        CALL moveUpSnake 
        MOV CL, DL     
        JMP readInput  
    
    moveDown: 
        CMP DL, 'S'
        JNE keepMoving
        CALL moveDownSnake 
        MOV CL, DL     
        JMP readInput  
    
    keepMoving: 
        MOV DL, CL 
        JMP readInput 
        
ends 


mainMenu PROC 
     
    MOV DI, 10 * 80 + 16 * 2  
    MOV SI, OFFSET snakeTitle 
    MOV CX, 5               
    
;Hien thi tieu de "SNAKE"    
printSnakeTitle:
    MOV AL, [SI]           
    MOV ES:[DI], AL       
    INC DI
    MOV AL, 7              
    MOV ES:[DI], AL        
    INC DI
    INC SI
    LOOP printSnakeTitle      
    
    MOV DI, 12 * 80 + 8 * 2 
    MOV SI, OFFSET startText 
    MOV CX, 22               

;Hien thi thong bao "Press any key to start..."            
printStartText:
    MOV AL, [SI]           
    MOV ES:[DI], AL        
    INC DI
    MOV AL, 7              
    MOV ES:[DI], AL        
    INC DI
    INC SI
    LOOP printStartText   
    
    MOV AH, 7
    INT 21h                ;Cho nguoi choi nhan phim bat ky de bat dau
    RET
mainMenu ENDP
                  
                  
buildScreen PROC ;
    ;Xay dung man choi voi ranh gioi, ran va thuc an
    CALL drawBorder        ;Ve bien cua man choi
    
    CALL printScore        ;Hien thi diem so tren man hinh
        
    XOR DX, DX 
    MOV DI, snakeAddress   
    MOV DL, snakeChars     
    ES: MOV [DI], DL       
        
    CALL placeFood        ;Dat thuc an tai vi tri ngau nhien
    RET
buildScreen ENDP  
          
          
moveLeftSnake PROC
    ;Di chuyen sang trai
    PUSH DX                
    CALL shiftAddress    
    SUB snakeAddress, 2    
    
    CALL checkCollision    
    
    CALL updateSnake       
    POP DX                 
RET
ENDP

moveRightSnake PROC
    ;Di chuyen sang phai
    PUSH DX                
    CALL shiftAddress   
    ADD snakeAddress, 2    
    
    CALL checkCollision    
    
    CALL updateSnake       
    POP DX                 
RET
ENDP

moveUpSnake PROC
    ;Di chuyen len tren
    PUSH DX                
    CALL shiftAddress    
    SUB snakeAddress, 80   
    
    CALL checkCollision    
    
    CALL updateSnake       
    POP DX                 
RET
ENDP

moveDownSnake PROC
    ;Di chuyen xuong duoi
    PUSH DX                
    CALL shiftAddress    
    ADD snakeAddress, 80   
    
    CALL checkCollision    
    
    CALL updateSnake       
    POP DX                 
RET
ENDP

shiftAddress PROC
    ;Dich chuyen mang dia chi ran de cap nhat vi tri moi
    PUSH AX                
    XOR CH, CH
    XOR BH, BH
    MOV CL, snakeLength    
    INC CL                 
    MOV AL, 2
    MUL CL                 
    MOV BL, AL             
    
    XOR DX, DX
    
shiftSnake:
    MOV DX, snakeAddress[BX-2] 
    MOV snakeAddress[BX], DX   
    SUB BX, 2                  
    LOOP shiftSnake            
    POP AX                     
    RET
ENDP


checkCollision PROC 
;Kiem tra ran co va cham voi bien, thuc an, hay tu an chinh no khong
    PUSH AX 
    PUSH CX 
    
    MOV DI, snakeAddress    
    ES: CMP [DI], 0         ;Kiem tra xem vi tri co trong khong
    JZ noCollision          
    ES: CMP [DI], 20h       ;Kiem tra xem co phai la tuong (ky tu ' ')
    JZ hitWall              
    ES: CMP [DI], '*'       ;Kiem tra xem co phai la thuc an
    JE eatFood              
    JNE collided            ;Neu khong phai thuc an hay tuong, ran tu an minh

    eatFood:                   ;Va cham voi thuc an
        INC scoreCount         
        MOV foodAddress, 0     
        XOR BH, BH
        MOV BL, snakeLength        
        MOV snakeChars[BX], 'o'    
        ES: MOV [DI], 0        
        ADD snakeLength, 1     
        CALL printScore        
        CALL placeFood         
        JMP noCollision        ;Tiep tuc chuong trinh  
        
    hitWall:                   ;Va cham voi tuong 
        CMP DI, 160            
        JBE collided           
        CMP DI, 1920           
        JAE collided           
        MOV AX, DI
        MOV BL, 80    
        DIV BL
        CMP AH, 0              
        JZ collided            
        MOV AX, DI
        ADD AX, 2
        MOV BL, 80    
        DIV BL
        CMP AH, 0              
        JZ collided            ;Va cham
        JMP noCollision        ;Khong va cham    
        
    collided:                  ;Xu li va cham
        POP CX
        POP AX
        CALL gameOver          ;Goi ham ket thuc tro choi 
        
    noCollision:
        POP CX
        POP AX
RET
ENDP


placeFood PROC ;Dat * o vi tri ngau nhien
    PUSH AX
    PUSH DX  
    
    randomPosition:    
        MOV AH, 00h
        INT 1AH                
        
        MOV AX, DX
        XOR DX, DX
        DIV mapSize            
        ADD DX, 162           
        MOV BX, DX 
        
        MOV AX, DX  
        XOR DX, DX
        DIV twoConst           ;Kiem tra vi tri co phai la cot chan
        CMP DX, 0
        JNE randomPosition     ;Neu khong phai cot chan, lap lai
        
    XOR DX, DX 
    MOV AX, BX
    DIV screenWidth        ;Kiem tra vi tri co nam o cot trai cua ranh gioi khong
    CMP DX, 0
    JE  onLeftBorder       
    
    XOR DX, DX    
    MOV AX, BX
    ADD AX, 2
    DIV screenWidth        ;Kiem tra vi tri co nam o cot phai cua ranh gioi khong
    CMP DX, 0
    JE  onRightBorder

    onLeftBorder:
        ADD BX, 2              ;Dich chuyen vi tri sang phai 1 o
        JMP spawnFood
        
    onRightBorder:
        SUB BX, 2              ;Dich chuyen vi tri sang trai 1 o
        
    spawnFood:    
        ES: MOV [BX], '*'      ;Dat ky tu thuc an (*) tai vi tri BX
        MOV foodAddress, BX    
    POP DX
    POP AX 
    RET
placeFood ENDP



updateSnake PROC ;Cap nhat vi tri ran tren man hinh
    XOR CH, CH
    XOR SI, SI
    XOR DL, DL
    MOV CL, snakeLength    
    XOR BX, BX
    updateLoop: 
        MOV DI, snakeAddress[SI] 
        MOV DL, snakeChars[BX]   
        ES: MOV [DI], DL         
        ADD SI, 2                
        INC BX                   
        LOOP updateLoop
    MOV DI, snakeAddress[SI] 
    ES: MOV [DI], 0              
    RET
updateSnake ENDP
              
              
drawBorder PROC ;Ve ranh gioi cua man choi (40x25)
    MOV AH, 0
    MOV AL, 0
    INT 10h                

    MOV AX, 0B800h
    MOV ES, AX             

    MOV SI, 1             
    MOV AX, SI
    MOV BX, screenWidth   
    MUL BX                
    MOV DI, AX             

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc tren trai
    INC DI
    MOV AL, 7             
    MOV ES:[DI], AL        
    INC DI

    MOV CX, 38
drawTop: 
    MOV AL, '-'
    MOV ES:[DI], AL        ;Ve canh tren
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL        
    INC DI
    LOOP drawTop

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc tren phai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL

    MOV SI, 2                 
drawMiddleRows:            
    CMP SI, 23
    JA drawBottomRow       ;Neu vuot qua dong 23, ve canh duoi

    MOV AX, SI
    MOV BX, screenWidth    
    MUL BX
    MOV DI, AX             ;Tinh toan dia chi bat dau cua dong

    MOV AL, '|'
    MOV ES:[DI], AL        ;Ve canh trai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL
    INC DI

    MOV CX, 38
drawSpaces: 
    MOV AL, ' '
    MOV ES:[DI], AL        ;Ve khoang trong giua
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL
    INC DI
    LOOP drawSpaces

    MOV AL, '|'
    MOV ES:[DI], AL        ;Ve canh phai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL

    INC SI
    JMP drawMiddleRows

drawBottomRow: 
    MOV SI, 23             ;Ve canh duoi
    MOV AX, SI
    MOV BX, screenWidth   
    MUL BX
    MOV DI, AX

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc duoi trai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL
    INC DI

    MOV CX, 38
drawBottom: 
    MOV AL, '-'
    MOV ES:[DI], AL        ;Ve canh duoi
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL
    INC DI
    LOOP drawBottom

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc duoi phai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL

    RET
drawBorder ENDP

printScore PROC ;Hien thi diem so 
    MOV AH, 2
    MOV DH, 0
    MOV DL, 0
    MOV BH, 0
    INT 10h                
    
    MOV AH, 9
    LEA DX, scoreText
    INT 21h                ;In chuoi "Score:"
    
    MOV AX, 0
    MOV AL, scoreCount     ;Lay diem so
    MOV CX, 0
    MOV BX, 10
    pushStack: 
        MOV DX, 0
        DIV BX             
        INC CX             
        PUSH DX            
        CMP AX, 0
        JNE pushStack      
        
    popStack: 
        POP AX             
        MOV DL, AL
        ADD DL, '0'        
        MOV AH, 2
        INT 21h            ;In diem so
        LOOP popStack 
    RET
printScore ENDP

gameOver PROC ;Hien thi man hinh ket thuc tro choi
    MOV scoreCount, 0      
    MOV snakeLength, 1     ;
    
    MOV DI, 992            
    LEA SI, gameOverText
    MOV CX, 9        
    
    printGameOver:   ;In thong bao Game Over
        movsb              
        INC DI             
        LOOP printGameOver
        
    MOV DI, 1064           
    LEA SI, optionText
    MOV CX, 17       
    
    printOptionText:   ;    In cac lua chon
        movsb              
        INC DI             
        LOOP printOptionText 
        
    getOption: ;Hien thi lua chon khi Game Over       
        MOV AH, 7
        INT 21h            
        CMP AL, 'y'        
        JE startGame       
        CMP AL, 'n'        
        JE backToMenu      
        JMP getOption       
        
    backToMenu: ;Ve man hinh chinh
         CALL clearScreen   
         CALL mainMenu      
         JMP startGame      
ENDP                    
    
clearScreen PROC ;Xoa toan bo man hinh
    XOR CX, CX
    MOV DH, 24
    MOV DL, 39
    MOV BH, 7
    MOV AX, 700h
    INT 10h      
RET
ENDP