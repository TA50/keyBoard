org         0x7c00
bits        16
    
    cli
    mov ah, 0x02
    mov al , 8 
    mov dl , 0x80
    mov dh , 0 
    mov ch , 0 
    mov cl , 2 
    mov bx , main
    int 0x13
    jmp main
    
    times       (510 - ($ - $$)) db 0
    db          0x55 , 0xAA
    
    
    
        
main:
    mov ebp, esp; for correct debugging
    cli 
    xor ax , ax 
    mov ss , ax
    mov sp , 0xffff  
    mov         ebx,ScanCodeTable
  
    mov         esi,edi
    dec         esi
    
    xor         dx, dx 
    xor ecx , ecx
    mov ah , 0 
    mov al , 3h
    int 10h
    mov cl  , 7
    
    ;;;;;;
    xor esi , esi 
    mov esi , scString
    ;;;;;;;;;
pushad    
mov ax, 1003h
mov bx, 0
int 10h
popad
;;;;;;;;;;;;;;;set tabs
push ebx
mov ebx , 0
cls:
    
    cmp ebx , 7
    jg doneCls
    mov [pageNumber] ,  ebx
    pushad
    mov al , 0
    mov ecx , 80*25
    push ecx
   forC:
        call writeChar 
        call goRight
    loop forC
    pop ecx
    popad
    
    mov dword[crusor_col] , 0 
    mov dword[crusor_raw] , 0 
    call setCrusorPosition
    ;;;;;; set crusor shape
   
   
    inc ebx 
jmp cls
doneCls:
pop ebx
mov dword[pageNumber] , 0 
call setCrusorPosition
    check:
        in      al , 0x64 
        and     al ,1
        jz      check
    
    Read:
        in  al , 0x60
        cmp     al , 0x3A
        je      Caps
        wr:
        cmp     al,0x1c
        je      Press_Enter
        cmp al , 0x43
        je f9
        ;;;;;;;;;;;;;;;NUMPAd;;;;;
        cmp  al , 0x45
        je  Num_Lock
            
        cmp al , 0x4f 
        je Num1
        
        cmp al , 0x50
        je Num2
        
        cmp al , 0x51
        je Num3
        
        cmp al , 0x4b
        je Num4
        
        cmp al , 0x4c
        je Num5
        
        cmp al , 0x4d 
        jz Num6
        
        cmp al , 0x47 
        je Num7
         
        cmp al , 0x48 
        je Num8
        
        cmp al , 0x49
        je Num9
        
        cmp al , 0x53
        je NumDot

      
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cmp al , 0xE0 
        je setE0
         cmp al , 3bh 
         je F1
         cmp al , 3Ch 
         je F2
        cmp     al , 0x0f
        jz  Tab
        cmp     al , 0x4b
        jz  Num4
       
        cmp     al ,2Ah
        je  Make_SHIFT
        cmp     al , 0x36
        je  Make_SHIFT
        cmp al,0x0E
        je BckSp
        cmp     al , 0x80
        ja breakCode
        cmp al , 0x9D
        je disable_ctrl
        cmp al , 0x1D
        je enable_ctrl
        ;;;;;;;;;;;;;;;;;;;;;;;;;;Hot Keys;;;;;;;;;;;;;;;;;
        cmp al , 0x2d 
        je X
       
        cmp al , 0x2E
        je C
        cmp al , 0x2f
        je V
        cmp al , 0x1e
        je A
       ;;;;;;;;;;;;;;;;;;;;;;;;;;; Writing ;;;;;;;;;;;;;;;]
       xlat
       write:
        cmp dword[Highlight_Length] , 0
        je ww 
       ; call cut
        call UN_Highlight_Screen
        
        mov dword[len] , 0
        
        ww:
        pushad
        call shiftRight
        popad
        call writeChar
         
        call goRight
       
        cmp dword[crusor_col]  , 79
        je New
        jmp check
        New:
            inc dword[last_raw] 
            call goRight
            jmp check
            
            
setE0:
       
            in al , 0x60 
            cmp al , 0x1D
            je enable_ctrl
            cmp al , 0x9d
            je disable_ctrl
            cmp al , 0x48
            je  U_Arrow
            cmp al , 0x4B
            je  L_Arrow
            cmp al , 0x50
            je  D_Arrow
            cmp al , 0x4D
            je  R_Arrow
             cmp al , 0x53
            je Delete
            cmp al , 0x47 
            je Home
            cmp al , 0x4f 
            je End
            
            cmp al , 0x49
            je pg_up
            cmp al , 0x51
            je pg_dn
            jmp check
          
      
breakCode:
        
        cmp     al ,0xAA
        je  Break_SHIFT
        cmp     al , 0xB6
        je  Break_SHIFT
        jmp     check
 

   

 
         
Make_SHIFT:
         mov byte[shift_pressed] , 1
         push eax 
         push ecx
         mov eax , shifted_Table
         mov ecx, Caps_shifted_Table
         cmp byte[caps_Status] ,0
         cmove ebx, eax
         cmovne ebx,ecx
         pop ecx
         pop eax
         jmp check 
Break_SHIFT:
     mov byte[shift_pressed] , 0
     mov eax,CapsTable
     mov ebx,ScanCodeTable 
     cmp byte[caps_Status],0
     cmovne ebx,eax
     jmp check
Num_Lock:
        not byte[Num_Status]
        jmp check         
Caps:
         push eax 
         push ecx
         mov eax ,ScanCodeTable
         mov ecx, CapsTable
         not byte[caps_Status]
         cmp byte[caps_Status] ,0
         cmove ebx , eax
         cmovne ebx , ecx
         pop ecx
         pop eax
         capsFor:
         in al,0x60
         cmp al,0xBA
         jz check
         jnz wr
         jmp capsFor
BckSp:
    call BackSpace
    call UN_Highlight_Screen
    jmp check    
    BackSpace:

         call getCrusorPosition
         cmp eax , 0xb8000
         je eR
         cmp dword[crusor_col] , 0
         jz  Begin_of_A_Line
         dec dword[crusor_col]
    erase:
       
        call setCrusorPosition
        call ShiftLeft
        eR:  ret
        
  Begin_of_A_Line:
       call ShiftUp
       push dword[crusor_col]
       push dword[crusor_raw]
       inc dword[crusor_raw]
       mov dword[crusor_col] , 0 
       call setCrusorPosition
       call readChar
       pop dword[crusor_raw]
       pop dword[crusor_col]
       call setCrusorPosition
       cmp al , 0
       je pullingUp
       jmp check
     
     pullingUp:
        mov eax ,[crusor_raw] 
        add eax , 2 
        forPulling:
            cmp eax , [last_raw]
            jg donePulling
            call pullUp
            inc eax
            jmp forPulling
            
        donePulling:

        jmp check
            
    removeWord:
            call readChar
            cmp al ,0x20
            je check
            cmp dword[crusor_col] ,  0
            je check
            mov al , 0 
            call writeChar
            dec dword[crusor_col]
            call setCrusorPosition
            call ShiftLeft
           
            jmp removeWord    
Press_Enter:
    
    cmp dword[last_raw] , 25 
    je check
      mov ecx , [last_raw]
       
       forEn:
       cmp ecx , [crusor_raw]
       je doneEn
       mov eax , ecx
       call pullDown
       dec ecx
       jmp forEn
       
       doneEn:
       call ShiftDown
       inc dword[last_raw]
       
       jmp check

enable_ctrl:
         mov byte[shift_pressed] , 1
         push eax 
         push ecx
         mov eax , shifted_Table
         mov ecx, Caps_shifted_Table
         cmp byte[caps_Status] ,0
         cmove ebx, eax
         cmovne ebx,ecx
         pop ecx
         pop eax
         jmp check     
disable_ctrl:
     mov byte[shift_pressed] , 0
     mov eax,CapsTable
     mov ebx,ScanCodeTable 
     cmp byte[caps_Status],0
     cmovne ebx,eax
     jmp check  
Delete:
        call goRight
        call readChar
        cmp al , 0 
        je endOfLine
        endDel:call BackSpace
        jmp check
        endOfLine:
        mov  dword[crusor_col] , 0 
        inc dword[crusor_raw] 
        call setCrusorPosition
        jmp endDel
        
        
Home:
        mov cl , [pageNumber]
        mov dword[crusor_col] , 0 
        call setCrusorPosition
        jmp check 
End:
        xor ecx , ecx
        call getLastCol
        mov cl , [pageNumber]
        mov [crusor_col] , eax
        
        call setCrusorPosition
       
        jmp check 

Tab:  
       
        pushad
         mov ecx , 8 
        f1:
        call shiftRight
        loop f1
        mov al , ' '
        mov cx , 8
        mov bh , byte[pageNumber]
        mov ah , 0ah
        int 10h 
        popad
        mov ecx , 8 
        f:
       
        call goRight
        loop f
        jmp check
        
            
 ;;;;;;;;;;;;;;;;;;;;;;HIGHLIGHT;;;;;;;;;;;;;;;;;;;;;
        U_Highlight:
           push dword[crusor_col] 
           push dword[crusor_raw]
           call goUp 
           mov dl , [crusor_col]
           mov dh , [crusor_raw]  
           pop dword[crusor_raw] 
           pop dword[crusor_col] 
           call setCrusorPosition
           
           forUH:
                mov cl , [crusor_col] 
                mov ch, [crusor_raw] 
                cmp cx , dx  
                je doneUH
                call L_Highlight
                call goLeft
                jmp forUH
            doneUH:
                jmp check
        D_Highlight:
           mov dl , [crusor_col]
           mov dh , [crusor_raw]  
           call goDown 
           forDH:
                mov cl , [crusor_col] 
                mov ch, [crusor_raw] 
                cmp cx , dx  
                je doneDH
                call L_Highlight
                call goLeft
                jmp forDH
            doneDH:
                call goDown
                jmp check
        R_Highlight:
        call goRight
        call readChar
        cmp al , 0x0 
        je RD
        call readChar
        cmp ah , 0x70
        jz R_Un_Highlight
        call Highlight
        ;;;;;copy
        call readChar
        mov ecx , [N]
        mov  byte[scString+ecx] , al
        inc dword[N] 
        RD:  
        jmp R   
        L_High:
        call L_Highlight
        call goLeft
        jmp check
        L_Highlight:
        call readChar
        cmp al , 0x0 
        je LD
        cmp ah , 0x70
        jz L_Un_Highlight
        ;;;;;;;;;copy
        dec esi 
        inc dword[N]
        mov [esi] , al 
        call Highlight
        LD:  
        ret
                    
        R_Un_Highlight:
              mov ecx , [N]
              mov  byte[esi+ecx] , al
              call Un_Highlight
              dec dword[N] 
              jmp R
                  
        L_Un_Highlight:
                mov dl , [crusor_col] 
                mov dh , [crusor_raw] 
                cmp dx  , 0 
                je LUH
                mov [esi] , al 
                dec dword[N] 
                inc esi
                call Un_Highlight
               LUH:ret                                      
;;;;;;;;;;;;;;;;;;;;;; M-U-L-T-I   -T-A-B-S;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       
F2:
       cli 
      pushad
      mov edx, [last_raw]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_raws+ecx*4] , edx 
      mov al , 1
      mov ah , 5
      int 10h 
      popad
      pushad
      mov byte[pageNumber] ,1 
      pushad
  ;    call getCrusorPosition 
      mov byte[crusor_raw] , dh
      mov byte[crusor_col] , dl
      popad
        xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_raws+ecx*4]
      mov [last_raw] , edx 
      jmp check 
      
      
F1:
      cli 
      push ebx
      mov edx, [last_raw]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_raws+ecx*4] , edx 
      
      mov al , 0
      mov ah , 5
      int 10h
     
     
      mov byte[pageNumber] ,0 
      push edx
  ;    call getCrusorPosition 
      mov byte[crusor_raw] , dh
      mov byte[crusor_col] , dl
      pop edx
      xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_raws+ecx*4]
      mov [last_raw] , edx 
      jmp check 
       pop ebx
       
       
F3:
      cli 
      pushad
      mov edx, [last_raw]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_raws+ecx*4] , edx 
      
      mov al , 2
      mov ah , 5
      int 10h 
      popad
      pushad
      mov byte[pageNumber] ,2 
  ;    call getCrusorPosition 
      
      xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_raws+ecx*4]
      mov [last_raw] , edx 
      jmp check
      
f9:
  
   jmp check
;;;;;;;;;;;;;;;;;;;;;;COPY _ PASTE ;;;;;;;;;;;;;;;;;;;;;;

paste:
   cli 
   pushad
   cmp dword[len] , 0 
   je check
   mov ah , 13h
   mov al , 0
   mov bp , [copied_address]
   push cs 
   pop es 
   mov cx , [len] 
   mov dl , [crusor_col] 
   mov dh , [crusor_raw] 
   mov bh , [pageNumber]
   mov bl , 0x7
   int 10h 
   xor ecx , ecx 
   mov ecx, [len] 
   _for:
   push ecx
   call goRight
   pop ecx
   loop _for
   
   popad 
   
   jmp check
   
   
copy:
   mov ecx , [N] 
   mov [len] , ecx
   mov [copied_address] , si
   mov si , scString
   mov dword[N] , 0
   jmp check
   
Cut:
   
   call cut 
   jmp check
   cut:
   cmp dword[N] ,  0 
   je copied_befor
   mov ecx , [N] 
   mov [len] , ecx
   mov [copied_address] , si
   mov si , scString
   copied_befor:
   cmp word[copied_address] , scString 
   je right 
  
   
   eraseCut:
   mov ecx , [len] 
   forF:
    push ecx
    call   ShiftLeft
    pop ecx
   loop forF   
   call   UN_Highlight_Screen
   jmp endCut
   
   endCut:
   call goRight
   ret
   right:
    mov ecx , [len] 
    forB:
    push ecx
    call   BackSpace
    pop ecx
    loop forB  
    call UN_Highlight_Screen  
    jmp endCut     
  
      
    
selectAll:
    pushad
    call UN_Highlight_Screen
    push dword[crusor_col]
    push dword[crusor_raw]
        mov ecx , [last_raw]
        mov [crusor_raw] , ecx
        call getLastCol
        mov [crusor_col] , eax
        
        forSelect:
                call goLeft
                pushad      
                call L_Highlight      
                popad  
                mov dl , [crusor_col]
                mov dh , [crusor_raw]
                cmp dx , 0 
                jne forSelect 
        
    pop dword[crusor_raw]
    pop dword[crusor_col]
    call setCrusorPosition
    popad
jmp check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HOT KEYS
A:
    cmp byte[ctrl_pressed] ,  0
    jnz selectAll
    xlat
    jmp write
X:
    cmp byte[ctrl_pressed] ,  0 
    jnz Cut
    xlat
    jmp write
C:
    cmp byte[ctrl_pressed] ,  0 
    jnz copy
    xlat
    jmp write
V:
    cmp byte[ctrl_pressed] ,  0 
    jnz paste
    xlat
    jmp write            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pg_up:
        
        mov dword[crusor_raw] , 0
        call setCrusorPosition
        jmp check
pg_dn:
        mov ecx , [last_raw]
        mov dword[crusor_raw] , ecx
        call setCrusorPosition
        jmp check
;;;;;;;;;;;;;;;;;;;; N   U  M  P  A  D;;;;;;;;;;;;;;;;;;;;;;;;
        Num1:
            cmp Byte[Num_Status] , 0 
            je End
            mov al , '1'              
            jmp write
        Num2:
            cmp Byte[Num_Status] , 0 
            je D_Arrow
            mov al , '2'              
            jmp write
        Num3:
            cmp Byte[Num_Status] , 0 
            je pg_dn
            mov al , '3'              
            jmp write
        Num4:
            cmp Byte[Num_Status] , 0 
            je L_Arrow
            mov al , '4'              
            jmp write
        Num5:
            cmp Byte[Num_Status] , 0 
            je check
            mov al , '5'              
            jmp write
        Num6:
            cmp Byte[Num_Status] , 0 
            je R_Arrow
            mov al , '1'              
            jmp write
        Num7:
            cmp Byte[Num_Status] , 0 
            je Home
            mov al , '7'              
            jmp write
        Num8:
            cmp Byte[Num_Status] , 0 
            je U_Arrow
            mov al , '8'              
            jmp write
        Num9:
            
            cmp Byte[Num_Status] , 0 
            je pg_up
            mov al , '9'              
            jmp write
        Num0:
            cmp Byte[Num_Status] , 0 
            je check
            mov al , '0'              
            jmp write
            
        NumDot:
            cmp Byte[Num_Status] , 0 
            je Delete
            mov al , '.'              
            jmp write
;;;;;;;;;;;;;;;;;;;; A   R  R  O  W  S;;;;;;;;;;;;;;;;;;;;;;;;
L_Arrow:
            cmp byte[shift_pressed],0
            jnz L_High  
            call UN_Highlight_Screen
            L:              
            call goLeft
            jmp check
            
                
           
R_Arrow:
            cmp byte[shift_pressed],0
            jnz R_Highlight
            call UN_Highlight_Screen
            R:
            call readChar
            cmp  al ,  0
            je last_Of_A_line
            call goRight
            jmp check
            last_Of_A_line:
                mov ecx, [crusor_raw]
                cmp dword[last_raw] , ecx
                je check
                inc dword[crusor_raw]   
                mov dword[crusor_col] , 0 
                call setCrusorPosition
            jmp  check            
            
U_Arrow:
            cmp byte[shift_pressed],0
            jnz U_Highlight
            call UN_Highlight_Screen
            call goUp
            jmp check
D_Arrow:
            cmp byte[shift_pressed],0
            jnz D_Highlight
            call UN_Highlight_Screen
            call goDown
            jmp check
            
            
            
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                  
                               
   
       
New_Line:    
        call ShiftDown
        jmp check
    
    
    
    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;F-N-C-T-I-O-N-S;;;;;;;;;;;;;;;;
goDown:
       pushad
            mov ecx, dword[last_raw]
            cmp dword[crusor_raw] , ecx 
            je doneU 
            inc dword[crusor_raw]
            call setCrusorPosition
            call readChar
            cmp al , 0
            jne doneU
            forDn:
                call goLeft
                call readChar
                cmp al , 0 
                je forDn
           call goRight
           doneD:
        popad
        ret   
goUp:
            pushad
            cmp dword[crusor_raw] , 0 
            je doneU 
            dec dword[crusor_raw]
            call setCrusorPosition
            call readChar
            cmp al , 0
            jne doneU
            forUp:
                call goLeft
                call readChar
                cmp al , 0 
                je forUp
           call goRight
           doneU:
           popad
           ret
        
        
goLeft:
        cmp dword[crusor_col] , 0
        je go_Line        
        dec dword[crusor_col] 
        call setCrusorPosition
      r:
      ret
      
       go_Line:
            cmp dword[crusor_raw] , 0 
            je r
            dec dword[crusor_raw] 
            pushad
            call getLastCol
            mov [crusor_col] , eax
            popad
            call setCrusorPosition
            ret                                       
goRight:
        cmp dword[crusor_col] , 80
        jge goNew_Line        
        inc dword[crusor_col] 
        call setCrusorPosition        
        ret
      
       goNew_Line:
            inc dword[crusor_raw] 
            mov dword[crusor_col] , 0 
            call setCrusorPosition
            ret
    setLineToNull:
        enter 0,0
        mov ecx,80 
        push ecx
       call getCrusorPosition
        pop ecx
        for:
            mov byte[eax+ecx*2], 0
        loop for    
        
        leave 
        ret
    getCrusorPosition:
     cli 
     enter 0,0
     push ebx 
     mov bh , [pageNumber]
     mov ah , 3
     int 10h
     push edx
     xor eax ,  eax
     MOV al  , dh
     imul eax , 80
     add al , dl 
     imul eax, 2 
     add eax , 0xb8000 
     pop edx
     pop ebx 
    
     leave 
     ret
     
getLastCol:
     enter 0,0
     push dword[crusor_col] 
     call setCrusorPosition
     
     forSearch:
        call readChar 
        cmp al , 0 
        je doneSearch
        inc dword[crusor_col]
        call setCrusorPosition 
        jmp forSearch
        
     doneSearch:
     mov eax , [crusor_col]
     pop dword[crusor_col]
     call setCrusorPosition       
     leave
     ret
     
    
setCrusorPosition:
    cli 
    enter 0 ,0 
    pushad
        mov dh, [crusor_raw]
        mov dl, [crusor_col]
        mov bh, [pageNumber]
        mov ah, 2
        int 10h
        popad 
    leave
    
    ret 
    
Highlight:
    cli 
    enter 0 , 0
    inc dword[Highlight_Length]
    pushad
    call readChar
    mov cx , 1
    mov bl , 0x70
    mov bh , [pageNumber]
    mov ah , 09h
    int 10h
    popad
    leave 
    ret
    
    
Un_Highlight:
    enter 0 , 0
    dec dword[Highlight_Length]
    cli 
    pushad
    mov bh , [pageNumber]
    mov ah , 08h 
    int 10h 
    mov cx , 1
    mov bl , 0x7
    mov bh , [pageNumber]
    mov ah , 09h
    int 10h
   
    popad
    leave     
    ret
    
UN_Highlight_Screen:
    enter 0,0 
    mov dword[Highlight_Length] , 0 
    mov dword[N] ,  0 
    mov si , scString
    pushad
        push dword[crusor_raw] 
        push dword[crusor_col]
        mov dword[crusor_raw] , 0 
        mov dword[crusor_col] , 0 
        call setCrusorPosition
        mov ecx , 0
        forL:
        cmp ecx , 2000
        jge  doe
        push ecx
        call Un_Highlight
        call goRight
        call setCrusorPosition
        pop ecx
        inc ecx
        jmp forL
        doe:
         pop  dword[crusor_col] 
         pop  dword[crusor_raw] 
        call setCrusorPosition
    popad     
    leave 
    ret
    
    
    
    ;;; input a char to write in al ;; 
    
writeChar:
    pushad
    cli 
    mov ah , 0ah 
    mov bh , [pageNumber] 
    mov cx , 1 
    int 10h 
    popad
    ret
   
readChar:
        cli 
        xor eax , eax
        push ebx
        mov ah , 8h 
        mov bh , [pageNumber]
        int 10h   
        pop ebx
        ret
        
;;;;;;;;;;;;;;;;;;Monitor Ops:  uses monitor_col   , monitor_raw 

;;;;; char to display at al 

writeCharAtMonitor:
   push dword[crusor_raw] 
   push dword[crusor_col]
   mov  dl , [monitor_col]
   mov dh , [monitor_raw]
   mov [crusor_raw] , dh
   mov [crusor_col] , dl
   call setCrusorPosition
   call writeChar
   pop dword[crusor_col]
   pop dword[crusor_raw] 
   call setCrusorPosition
   ret                  

goRightInMonitor:
      cmp dword[monitor_col] , 80
      jge goNew_Line1        
      inc dword[monitor_col] 
      ret
       goNew_Line1:
            inc dword[monitor_raw] 
            mov dword[monitor_col] , 0 
            ret
goLeftInMonitor:
      cmp dword[monitor_col],0
      jle goPre_Line1
      dec dword[monitor_col]
      ret
      goPre_Line1:
            dec dword[monitor_raw]
            mov dword [monitor_col],79
            ret

readCharAtMonitor:
   
   push dword[crusor_raw] 
   push dword[crusor_col]
   mov  dl , [monitor_col]
   mov dh , [monitor_raw]
   mov [crusor_raw] , dh
   mov [crusor_col] , dl
   call setCrusorPosition
   call readChar
   ;;al = char
   pop dword[crusor_col]
   pop dword[crusor_raw] 
   call setCrusorPosition
   ret                  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SHIFTING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
shiftRight:
    pushad
    mov ecx , [crusor_raw] 
    mov [monitor_raw], ecx
    mov ecx , [crusor_col] 
    mov [monitor_col], ecx
    mov byte[tmp] , 0
    ;;;;;;;;read char 
    call readCharAtMonitor
    mov [tmp] , al
     forRs:
    ;;;go Right
    call goRightInMonitor
    ;;;;read new char
    call readCharAtMonitor
    mov bl , al
    ;;;old char in tmp , new char is in bl 
    mov al , [tmp] 
    ;;;write old char 
    call writeCharAtMonitor
    cmp bl , 0
    je doneRs
    mov [tmp] , bl
    mov al ,bl
    jmp forRs
    doneRs: 
    popad
    
    mov byte[tmp] , 0    
    
ret    


ShiftLeft:
    enter 0,0
    pushad
    mov ecx , [crusor_raw] 
    mov [monitor_raw], ecx
    mov ecx , [crusor_col] 
    mov [monitor_col], ecx
    mov ecx , 20
    forLSH:
    call readCharAtMonitor
    call goRightInMonitor
    call readCharAtMonitor
    mov bl,al
    call goLeftInMonitor
    mov al , bl
    call writeCharAtMonitor
    call goRightInMonitor  
    loop forLSH
    doneLSH:
    popad
    leave
    ret
   
    ShiftDown:
    enter 0,0
    pushad
    mov edi , st
    mov ecx ,   80
    sub ecx , [crusor_col]
    mov [a] , ecx
    forShD:
    call readChar
    push eax
    mov al , 0 
    call writeChar 
    pop eax 
    stosb 
    call goRight
    loop forShD
    
    
    inc dword[crusor_raw]
    mov dword[crusor_col] , 0
    cli 
    mov al , 0
    mov ah , 13h
    mov ecx , [a]
    mov dl , 0
    mov dh , [crusor_raw] 
    mov bp , st
    push cs 
    pop es
    mov bh , [pageNumber]
    mov bl , 0x7
    int 10h
 

    call setCrusorPosition
    
    popad
    leave
    ret
    
    
    
    ShiftUp:
    enter 0,0
    
    pushad
    push dword[crusor_raw] 
    push dword[crusor_col] 
    call goLeft
    mov eax , [crusor_col]
    pop dword[crusor_col] 
    pop dword[crusor_raw] 
    ;;;;;;last col in eax 
    mov ecx , 80 
    mov edi , st
    
    call setCrusorPosition
    
    ;;;;;;;;;;;;;;;;;;;itration
    push eax
   
    forShU:
    cli 
    call readChar
    push eax
    mov al , 0 
    call writeChar 
    pop eax 
    stosb 
    call goRight
    loop forShU
    
    pop eax
    dec dword[crusor_raw]
    mov dword[crusor_col] , eax
    mov al  , 0
    mov ah , 13h
    mov ecx , 80
    mov dl , [crusor_col]
    mov dh , [crusor_raw] 
    mov bp , st
    push cs 
    pop es
    mov bh , [pageNumber]
    mov bl , 0x7
    int 10h
    
    call setCrusorPosition
    popad
    leave
    ret
    
    ;input: eax: row number
    pullUp:
    enter  0,0
    pushad
    push dword[crusor_raw] 
    push dword[crusor_col] 
    
    mov [crusor_raw] , eax
    mov dword[crusor_col]  ,  0
    call setCrusorPosition
    mov ecx, 80
    forPullU:
    
    call readChar
    mov bl , al
    mov al , 0 
    call writeChar
    mov al , bl
    dec dword[crusor_raw]
    call setCrusorPosition
    call writeChar
    inc dword[crusor_raw]
    inc dword[crusor_col]
    call setCrusorPosition
    loop forPullU
    
    pop dword[crusor_col] 
    pop dword[crusor_raw] 
    call setCrusorPosition

    
    popad
    leave
    ret
    
    
    ;;input:  eax: row number  
    pullDown:
    enter  0,0
    pushad
    push dword[crusor_raw] 
    push dword[crusor_col] 
    
  ;  mov eax , [ebp+8] 
    mov [crusor_raw] , eax
    mov dword[crusor_col]  ,  0
    call setCrusorPosition
    mov ecx, 80
    forPullD:
    
    call readChar
    mov bl , al
    mov al , 0 
    call writeChar
    mov al , bl
    inc dword[crusor_raw]
    call setCrusorPosition
    call writeChar
    dec dword[crusor_raw]
    inc dword[crusor_col]
    call setCrusorPosition
    loop forPullD
    
    pop dword[crusor_col] 
    pop dword[crusor_raw] 
    call setCrusorPosition
    
    popad
    leave
    ret
    
;;;;;;;;;;;;;;;;    D     A       T      A;;;;;;;;;;;;;;;;;;; 
  
   
    ;;;Tables
    ScanCodeTable: db "//1234567890-=//qwertyuiop[]//asdfghjkl;//'/zxcvbnm,.//// /"
    CapsTable: db "//1234567890-=//QWERTYUIOP[]//ASDFGHJKL;//'/ZXCVBNM,.//// /"
    Caps_shifted_Table: db '//!@#$%^&*()_+//qwertyuiop{}//asdfghjkl://"/zxcvbnm<>?/// /'
    shifted_Table: db '//!@#$%^&*()_+//QWERTYUIOP{}//ASDFGHJKL://"/ZXCVBNM<>?/// /'
    ;;;;;;;;;;;;;;;;;;
    ;;;;;;cursor positioning issues;;;
    pageNumber: db 0  
    last_raw: dd 0
    last_page_raws: dd 0 ,0,0,0,0,0,0,0 
    monitor_col: dd 0 
    monitor_raw: dd 0 
    crusor_col: dd  0 
    crusor_raw: dd 0
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;status
    Num_Status: db 0 
    shift_pressed: db 0
    ctrl_pressed: dd 0   
    Enter_Counter: dd  0 
    caps_Status: db 0
    Highlight_Length: dd 0
    ;;;;;;;;;;;;;;;;
    tmp: db 0 

    a: dd 0
    st: times(25*80) db 0
     ;;;;;;;;;;copy - paste;;;
    copied_address: dw 0
    N: dd 0
    len: dd 0 
    copied: db 0
    times(2000) db 0 
    scString: times(2000) db 0
    
    ; Virtualbox disk configuration
    times       (0x400000 - 0x200) db 0
    db          0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78, 0x00, 0x00, 0x00, 0x02
    db          0x00, 0x01, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db          0x20, 0x72, 0x5D, 0x33, 0x76, 0x62, 0x6F, 0x78, 0x00, 0x05, 0x00, 0x00
    db          0x57, 0x69, 0x32, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00
    db          0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x78, 0x04, 0x11
    db          0x00, 0x00, 0x00, 0x02, 0xFF, 0xFF, 0xE6, 0xB9, 0x49, 0x44, 0x4E, 0x1C
    db          0x50, 0xC9, 0xBD, 0x45, 0x83, 0xC5, 0xCE, 0xC1, 0xB7, 0x2A, 0xE0, 0xF2
    times       (0x200 - 84) db 0
