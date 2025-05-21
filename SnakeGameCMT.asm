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
    
    twoConst DW 2 ;Hang so 2
    mapSize DW 1755 
    screenWidth DW 80 
    

.Code  
    ;Khoi tao
    initialize:
    MOV AX, @Data
    MOV DS, AX    ;Thiet lap thanh ghi DS tro vao phan doan du lieu .Data
                                                                    
    MOV AX, 0b800h
    MOV ES, AX    ;ES tro den bo nho man hinh
    ;Tai day co the viet ki tu truc tiep len man hinh bang cach ghi vao ES:[DI]
    
    MOV AH, 0   ;Chon che do video
    MOV AL, 0   ;Chon che do 40x25, moi ki tu gom 2 byte: ki tu + mau
    INT 10h     ;Goi ngat BIOS de thiet lap che do video
    
    CLD ;Xoa direction flag: thiet lap huong di chuyen cua SI/DI tang len
    
    ;An con tro van ban
    MOV AH, 1
    MOV CH, 2BH
    MOV CL, 0BH   
    INT 10h     ;Goi ngat BIOS de an con tro tren man hinh
    
    CALL mainMenu ;Goi ham hien thi menu chinh
                   
          
    ;Bat dau game               
    startGame: 
    CALL clearScreen   ;Xoa man hinh de bat dau tro choi moi
    
    MOV snakeAddress, startPosition ;Dat lai ran ve vi tri bat dau (O giua man hinh)     
    CALL buildScreen ;Xay dung lai man choi voi ranh gioi, ran va thuc an
    
    XOR CL, CL ;Luu phim di theo huong cu (khoi tao ban dau la 0)
    XOR DL, DL ;Luu phim moi nhap (khoi tao ban dau la 0)
    readInput: ;Doc input
        MOV AH, 1
        INT 16H     ;Doc xem co input khong, Zero Flag = 1 neu khong co phim
        JZ moveLeft ;Neu khong co thi tiep tuc xu li huong dang di chuyen 
        
        MOV AH, 0
        INT 16H       ;Lay input tu buffer ban phim
        AND AL, 0dfh  ;Chuyen ki tu nhap vao tu in thuong thanh in hoa
        MOV DL, AL    ;Luu ki tu nguoi choi vua nhap vao DL
    
    moveLeft: 
        CMP DL, 'A'
        JNE moveRight
        CALL moveLeftSnake ;Di chuyen ran sang trai
        MOV CL, DL    ;Luu huong di chuyen hien tai vao CL
        JMP readInput ;Quay lai doc input tiep theo
    
    moveRight:
        CMP DL, 'D'
        JNE moveUp                  
        CALL moveRightSnake ;Di chuyen ran sang phai
        MOV CL, DL     ;Luu huong di chuyen hien tai vao CL
        JMP readInput  ;Quay lai doc input tiep theo
    
    moveUp: 
        CMP DL, 'W'
        JNE moveDown
        CALL moveUpSnake ;Di chuyen ran len tren
        MOV CL, DL     ;Luu huong di chuyen hien tai vao CL
        JMP readInput  ;Quay lai doc input tiep theo
    
    moveDown: 
        CMP DL, 'S'
        JNE keepMoving
        CALL moveDownSnake ;Di chuyen ran xuong duoi
        MOV CL, DL     ;Luu huong di chuyen hien tai vao CL
        JMP readInput  ;Quay lai doc input tiep theo
    
    keepMoving: 
        MOV DL, CL ;Giu nguyen huong di chuyen cu neu khong co input moi
        JMP readInput ;Quay lai doc input tiep theo
        
ends 


mainMenu PROC 
     
    MOV DI, 10 * 80 + 16 * 2  ;Vi tri tieu de (dong 10, cot 16)   
    MOV SI, OFFSET snakeTitle ;Tro SI den mang snakeTitle
    MOV CX, 5               ;Do dai cua tieu de (5 ki tu)   
    
;Hien thi tieu de "SNAKE"    
printSnakeTitle:
    MOV AL, [SI]           ;Lay ki tu tu mang snakeTitle
    MOV ES:[DI], AL        ;Ghi ki tu len man hinh
    INC DI
    MOV AL, 7              ;Thiet lap mau chu (7 = mau trang)
    MOV ES:[DI], AL        ;Ghi thuoc tinh mau len man hinh
    INC DI
    INC SI
    LOOP printSnakeTitle       ;Lap lai de in het tieu de
    
    MOV DI, 12 * 80 + 8 * 2 ;Vi tri thong bao "Press any key to start..." (dong 12, cot 8)
    MOV SI, OFFSET startText ;Tro SI den mang startText
    MOV CX, 22               ;Do dai cua thong bao (22 ky tu)

;Hien thi thong bao "Press any key to start..."            
printStartText:
    MOV AL, [SI]           ;Lay ky tu tu mang startText
    MOV ES:[DI], AL        ;Ghi ky tu len man hinh
    INC DI
    MOV AL, 7              ;Thiet lap mau chu (7 = mau trang)
    MOV ES:[DI], AL        ;Ghi thuoc tinh mau len man hinh
    INC DI
    INC SI
    LOOP printStartText   ;Lap lai de in het thong bao
    
    MOV AH, 7
    INT 21h                ;Cho nguoi choi nhan phim bat ky de bat dau
    RET
mainMenu ENDP
                  
                  
buildScreen PROC ;
    ;Xay dung man choi voi ranh gioi, ran va thuc an
    CALL drawBorder        ;Ve bien cua man choi
    
    CALL printScore        ;Hien thi diem so tren man hinh
        
    XOR DX, DX 
    MOV DI, snakeAddress   ;Lay dia chi dau ran (vi tri bat dau)
    MOV DL, snakeChars     ;Lay ky tu dau ran ('0')
    ES: MOV [DI], DL       ;Dat ran len man hinh tai vi tri ban dau
        
    CALL placeFood        ;Dat thuc an tai vi tri ngau nhien
    RET
buildScreen ENDP  
          
          
moveLeftSnake PROC
    ;Di chuyen sang trai
    PUSH DX                ;Luu gia tri DX
    CALL shiftAddresses    ;Dich chuyen cac vi tri cua ran
    SUB snakeAddress, 2    ;Giam dia chi ran di 2 de di chuyen sang trai
    
    CALL checkCollision    ;Kiem tra va cham (bien, thuc an, tu an minh)
    
    CALL updateSnake       ;Cap nhat vi tri ran tren man hinh
    POP DX                 ;Khoi phuc gia tri DX
RET
ENDP

moveRightSnake PROC
    ;Di chuyen sang phai
    PUSH DX                ;Luu gia tri DX
    CALL shiftAddresses    ;Dich chuyen cac vi tri cua ran
    ADD snakeAddress, 2    ;Tang dia chi ran them 2 de di chuyen sang phai
    
    CALL checkCollision    ;Kiem tra va cham (bien, thuc an, tu an minh)
    
    CALL updateSnake       ;Cap nhat vi tri ran tren man hinh
    POP DX                 ;Khoi phuc gia tri DX
RET
ENDP

moveUpSnake PROC
    ;Di chuyen len tren
    PUSH DX                ;Luu gia tri DX
    CALL shiftAddresses    ;Dich chuyen cac vi tri cua ran
    SUB snakeAddress, 80   ;Giam dia chi ran di 80 de di chuyen len tren (1 dong)
    
    CALL checkCollision    ;Kiem tra va cham (bien, thuc an, tu an minh)
    
    CALL updateSnake       ;Cap nhat vi tri ran tren man hinh
    POP DX                 ;Khoi phuc gia tri DX
RET
ENDP

moveDownSnake PROC
    ;Di chuyen xuong duoi
    PUSH DX                ;Luu gia tri DX
    CALL shiftAddresses    ;Dich chuyen cac vi tri cua ran
    ADD snakeAddress, 80   ;Tang dia chi ran them 80 de di chuyen xuong duoi (1 dong)
    
    CALL checkCollision    ;Kiem tra va cham (bien, thuc an, tu an minh)
    
    CALL updateSnake       ;Cap nhat vi tri ran tren man hinh
    POP DX                 ;Khoi phuc gia tri DX
RET
ENDP

shiftAddresses PROC
    ;Dich chuyen mang dia chi ran de cap nhat vi tri moi
    PUSH AX                ;Luu gia tri AX
    XOR CH, CH
    XOR BH, BH
    MOV CL, snakeLength    ;Lay do dai ran
    INC CL                 ;Tang do dai de tinh ca phan dau
    MOV AL, 2
    MUL CL                 ;Tinh toan kich thuoc mang (do dai * 2 vi la DW)
    MOV BL, AL             ;Luu kich thuoc vao BL
    
    XOR DX, DX
    
shiftSnake:
    MOV DX, snakeAddress[BX-2] ;Lay dia chi truoc do
    MOV snakeAddress[BX], DX   ;Dich chuyen dia chi len vi tri moi
    SUB BX, 2                  ;Giam BX di 2 vi snakeAddress la DW
    LOOP shiftSnake            ;Lap lai cho den khi het do dai ran
    POP AX                     ;Khoi phuc gia tri AX
    RET
ENDP


checkCollision PROC 
;Kiem tra ran co va cham voi bien, thuc an, hay tu an chinh no khong
    PUSH AX 
    PUSH CX 
    
    MOV DI, snakeAddress    ;Lay dia chi dau ran
    ES: CMP [DI], 0         ;Kiem tra xem vi tri co trong khong
    JZ noCollision          ;Neu trong thi khong va chaml
    ES: CMP [DI], 20h       ;Kiem tra xem co phai la tuong (ky tu ' ')
    JZ hitWall              ;Neu la tuong thi kiem tra vi tri so voi ranh gioi
    ES: CMP [DI], '*'       ;Kiem tra xem co phai la thuc an
    JE eatFood              ;Neu la thuc an thi xu ly
    JNE collided            ;Neu khong phai thuc an hay tuong, ran tu an minh

    eatFood: 
        INC scoreCount         ;Tang diem so
        MOV foodAddress, 0     ;Xoa dia chi thuc an cu
        XOR BH, BH
        MOV BL, snakeLength        ;Lay do dai ran
        MOV snakeChars[BX], 'o'    ;Them ky tu than ran moi
        ES: MOV [DI], 0        ;Xoa thuc an tai vi tri
        ADD snakeLength, 1     ;Tang do dai ran
        CALL printScore        ;Cap nhat diem so tren man hinh
        CALL placeFood         ;Dat thuc an moi
        JMP noCollision        ;Tiep tuc chuong trinh  
        
    hitWall:
        CMP DI, 160            ;Kiem tra va cham tuong tren
        JBE collided           ;Neu <= 160 thi va cham
        CMP DI, 1920           ;Kiem tra va cham tuong duoi
        JAE collided           ;Neu >= 1920 thi va cham
        MOV AX, DI
        MOV BL, 80             
        DIV BL
        CMP AH, 0              ;Kiem tra va cham tuong trai
        JZ collided            ;Neu chia het cho 80 thi va cham
        MOV AX, DI
        ADD AX, 2
        MOV BL, 80    
        DIV BL
        CMP AH, 0              ;Kiem tra va cham tuong phai
        JZ collided            ;Neu chia het cho 80 thi va cham
        JMP noCollision        ;Khong va cham    
        
    collided:
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
        INT 1AH                ;Lay thoi gian he thong, ket qua luu o DX
        
        MOV AX, DX
        XOR DX, DX
        DIV mapSize            ;Tinh toan vi tri ngau nhien trong khoang 0-1754
        ADD DX, 162            ;Dich chuyen vi tri de nam trong vung choi
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
        MOV foodAddress, BX    ;Luu dia chi th?c an
    POP DX
    POP AX 
    RET
placeFood ENDP



updateSnake PROC ;Cap nhat vi tri ran tren man hinh
    XOR CH, CH
    XOR SI, SI
    XOR DL, DL
    MOV CL, snakeLength    ;Lay do dai ran
    XOR BX, BX
    updateLoop: 
        MOV DI, snakeAddress[SI] ;Lay dia chi phan tu ran
        MOV DL, snakeChars[BX]   ;Lay ky tu cua phan tu ran
        ES: MOV [DI], DL         ;Ghi ky tu ran len man hinh
        ADD SI, 2                ;Tiep tuc den phan tu tiep theo (DW)
        INC BX                   ;Tiep tuc den ky tu tiep theo
        LOOP updateLoop
    MOV DI, snakeAddress[SI] 
    ES: MOV [DI], 0              ;Xoa vi tri cuoi cua ran
    RET
updateSnake ENDP
              
              
drawBorder PROC ;Ve ranh gioi cua man choi (40x25)
    MOV AH, 0
    MOV AL, 0
    INT 10h                ;Thiet lap lai che do video 40x25

    MOV AX, 0B800h
    MOV ES, AX             ;Tro ES den bo nho man hinh

    MOV SI, 1              ;Bat dau ve tu dong 1
    MOV AX, SI
    MOV BX, screenWidth   
    MUL BX                
    MOV DI, AX             ;Tinh toan dia chi bat dau cua dong 1

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc tren trai
    INC DI
    MOV AL, 7             
    MOV ES:[DI], AL        ;Thiet lap mau
    INC DI

    MOV CX, 38
drawTop: 
    MOV AL, '-'
    MOV ES:[DI], AL        ;Ve canh tren
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL        ;Thiet lap mau
    INC DI
    LOOP drawTop

    MOV AL, '*'
    MOV ES:[DI], AL        ;Ve goc tren phai
    INC DI
    MOV AL, 7
    MOV ES:[DI], AL

    MOV SI, 2              ;Ve cac dong giua    
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
    INT 10h                ;Di chuyen con tro den vi tri (0, 0)
    
    MOV AH, 9
    LEA DX, scoreText
    INT 21h                ;In chuoi "Score:"
    
    MOV AX, 0
    MOV AL, scoreCount     ;Lay diem so
    MOV CX, 0
    MOV BX, 10
    pushStack: 
        MOV DX, 0
        DIV BX             ;Chia diem so cho 10 de tach cac chu so
        INC CX             ;Dem so luong chu so
        PUSH DX            ;Day chu so vao stack
        CMP AX, 0
        JNE pushStack      ;Tiep tuc neu con chu so
        
    popStack: 
        POP AX             ;Lay chu so tu stack
        MOV DL, AL
        ADD DL, '0'        ;Chuyen chu so thanh ky tu
        MOV AH, 2
        INT 21h            ;In ky tu chu so
        LOOP popStack 
    RET
printScore ENDP

gameOver PROC ;Hien thi man hinh ket thuc tro choi
    MOV scoreCount, 0      ;Dat lai diem so ve 0
    MOV snakeLength, 1     ;Dat lai do dai ran ve 1
    
    MOV DI, 992            ;Vi tri in Game Over
    LEA SI, gameOverText
    MOV CX, 9
    printGameOver:
        movsb              ;Sao chep ky tu tu gameOverText len man hinh
        INC DI             ;Bo qua byte mau
        LOOP printGameOver
        
    MOV DI, 1064           ;Vi tri in Restart ? (Y / N)
    LEA SI, optionText
    MOV CX, 17       
    
    printOptionText:
        movsb              ;Sao chep ky tu tu endText len man hinh
        INC DI             ;Bo qua byte mau
        LOOP printOptionText 
        
    getOption: ;Hien thi lua chon khi Game Over       
        MOV AH, 7
        INT 21h            ;Doc input
        CMP AL, 'y'        ;Kiem tra neu nhan y 
        JE startGame       ;Neu nhan y, bat dau lai
        CMP AL, 'n'        ;Kiem tra neu nhan n
        JE backToMenu      ;Neu nhan n, ve man hinh chinh
        JMP getOption      ;Tiep tuc doi 
        
    backToMenu: ;Ve man hinh chinh
         CALL clearScreen   ;Xoa man hinh
         CALL mainMenu      ;Quay ve man hinh chinh
         JMP startGame      ;Bat dau lai tro choi
ENDP                    
    
clearScreen PROC ;Xoa toan bo man hinh
    XOR CX, CX
    MOV DH, 24
    MOV DL, 39
    MOV BH, 7
    MOV AX, 700h
    INT 10h      ;Goi ngat BIOS xoa toan bo man hinh
RET
ENDP