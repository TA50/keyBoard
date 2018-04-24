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
    
    mov dword[cursor_col] , 0 
    mov dword[cursor_row] , 0 
    call setCursorPosition
    
   
    inc ebx 
jmp cls
doneCls:
pop ebx
mov dword[pageNumber] , 0 
call setCursorPosition
;;;;;; set cursor shape

    check:
        in      al , 0x64 
        and     al ,1
        jz      check
    
   
    Read:
        in  al , 0x60
        cmp al , 0x9D
        je disable_ctrl
        cmp     al , 0x3A
        je      Caps
        wr:
        cmp     al,0x1c
        je      Press_Enter

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
         cmp al , 0x3d
         je F3
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
       jg replaceWord
        pushad
        cmp dword[cursor_col] , 79
        je moveWord
        wwwr:
        call shiftRight
        popad
        call writeChar
        call goRight
       
        cmp dword[cursor_col]  , 79
        je New
        jmp check
        New:
            
            inc dword[last_row] 
            jmp check
       moveWord:
            cmp al , 0x20 
            je cantDo
            push eax
            xor ecx , ecx 
            forBack:
            call goLeft
            call readChar 
            inc ecx 
            cmp dword[cursor_col] , 0 
            je cantDo
            cmp al , 0x20
            jne forBack
            push ecx
            forForward:
                call shiftRight
                mov al , 0x0 
                call writeChar 
                call goRight
            loop forForward
            pop ecx
            forFor:
                call goRight
            loop forFor
            endMove:
            pop eax 
            inc dword[last_row]
            call shiftRight
            call writeChar 
            call goRight
            mov al , 0x20
            call writeChar 
            call goRight
            jmp check
            
            cantDo:
            pop eax
            mov dword[cursor_col] , 79 
            call setCursorPosition
            call writeChar 
            inc dword[cursor_row]
            mov dword[cursor_col] , 0 
            call setCursorPosition
            inc dword[last_row]
            jmp check
         replaceWord:
            mov ecx , [Highlight_Length]
            cmp esi , scString
            je rightDel
            forDelete:
              call ShiftLeft
            loop forDelete
            call shiftRight
            call writeChar
            call goRight
            call UN_Highlight_Screen
            jmp check   
            
            rightDel:
            push eax
            forRDel:
            call BackSpace
            loop forRDel
            pop eax
            call shiftRight
            call writeChar
            call goRight
            call UN_Highlight_Screen
            jmp check     
setE0:
       
            in al , 0x60 
            cmp al , 0x1D
            je enable_ctrl
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
        cmp     al , 0xBA
        je      Caps
        cmp     al ,0xAA
        je  Break_SHIFT
        cmp     al , 0xB6
        je  Break_SHIFT
        jmp     check
        cmp al , 0x9d
        je disable_ctrl
        
        jmp check

 
         
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
         jmp capsFor
         
;;;;;;;;;;;;;;;;;;;;;;;;BackSpace;;;;;;;;;;;;;;;;;         
         
BckSp:
    cmp byte[ctrl_pressed] , 0 
    jne removeWord
    cmp dword[Highlight_Length] , 0 
    jg removHighlight
    call BackSpace
    jmp check    
    BackSpace:
         mov al , [cursor_col] 
         mov ah , [cursor_row]
         cmp  ax , 0 
         je eR
         cmp dword[cursor_col] , 0
         jz  Begin_of_A_Line
         dec dword[cursor_col]
     erase:
        call setCursorPosition
        call ShiftLeft
        eR:  ret
        
     Begin_of_A_Line:
       push  dword[cursor_col]
       push  dword[cursor_row]
       call goLeft
       cmp dword[cursor_col] , 79
       je cant_do_shiftUp
       pop  dword[cursor_row]
       pop dword[cursor_col] 
       call setCursorPosition
       call ShiftUp       
       push dword[cursor_col]
       push dword[cursor_row]
       inc dword[cursor_row]
       mov dword[cursor_col] , 0 
       call setCursorPosition
       call readChar
       pop dword[cursor_row]
       pop dword[cursor_col]
       call setCursorPosition
       cmp al , 0
       je pullingUp
       dec dword[last_row]
      cant_do_shiftUp:
      pop  dword[cursor_row]
      pop dword[cursor_col]
      call ShiftLeft 
      dec dword[last_row]
      ret
     
     pullingUp:
        mov eax ,[cursor_row] 
        add eax , 2 
        forPulling:
            cmp eax , [last_row]
            jg donePulling
            call pullUp
            inc eax
            jmp forPulling
            
        donePulling:

       ret
            
    removeWord:
         
           loopRemWrd:
                mov al , 20 
               
                call ShiftLeft
                call goLeft
                call readChar 
                cmp al , 0 
                je check
                cmp al , 0x20
                je check
                cmp dword[cursor_col] , 0 
                jz check 
                jmp loopRemWrd
                
             
    removHighlight:        
              cmp byte[ all_selected] , 0 
               jne clscreen
               cmp esi , scString
               je rightBackHi
               mov ecx , [Highlight_Length] 
               forDEl:
               call ShiftLeft
               loop forDEl
               call UN_Highlight_Screen
               jmp check
               rightBackHi:
                     mov ecx , [Highlight_Length] 
                     forBAAA:
                        call BackSpace
                     loop forBAAA
                     call UN_Highlight_Screen
                     jmp check
              clscreen:
               mov al , 0
    mov ecx , 80*25
    push ecx
   forCl:
        call writeChar 
        call goRight
    loop forCl
    pop ecx
   mov byte[ all_selected] , 0 
    jmp check
                     
                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Press_Enter:
        cmp dword[Highlight_Length] , 0
        jne clH
        return:
       cmp dword[cursor_row] , 24
       je check
       mov ecx , [last_row]
       forEn:
       cmp ecx , [cursor_row]
       je doneEn
       mov eax , ecx
       call pullDown
       dec ecx
       jmp forEn
       doneEn:
       cmp dword[cursor_col] , 0 
       je fir
       call ShiftDown
       inc dword[last_row]
       jmp check
       
       fir:
       mov eax ,  [cursor_row] 
       call pullDown  
       
       mov dword[cursor_col] , 0 
       call setCursorPosition
       inc dword[last_row] 
       jmp check
       clH:
       call UN_Highlight_Screen
       jmp  return
enable_ctrl:
    mov dword[ctrl_pressed] , 1 
    jmp check     
disable_ctrl:
    mov dword[ctrl_pressed] ,  0
    jmp check   
Delete: 
     cmp dword[cursor_col] , 79 
     je last_Line
     call ShiftLeft
     jmp check   
     last_Line:
     call ShiftLeft
     call goRight 
     call ShiftLeft
     call goLeft
     jmp check
Home:
        mov cl , [pageNumber]
        mov dword[cursor_col] , 0 
        call setCursorPosition
        jmp check 
End:
        xor ecx , ecx
        call getLastCol
        mov cl , [pageNumber]
        mov [cursor_col] , eax
        
        call setCursorPosition
       
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
           push dword[cursor_col] 
           push dword[cursor_row]
           call goUp 
           mov dl , [cursor_col]
           mov dh , [cursor_row]  
           pop dword[cursor_row] 
           pop dword[cursor_col] 
           call setCursorPosition
           
           forUH:
                mov cl , [cursor_col] 
                mov ch, [cursor_row] 
                cmp cx , dx  
                je doneUH
                call L_Highlight
                call goLeft
                jmp forUH
            doneUH:
                jmp check
        D_Highlight:
           mov dl , [cursor_col]
           mov dh , [cursor_row]  
           call goDown 
           forDH:
                mov cl , [cursor_col] 
                mov ch, [cursor_row] 
                cmp cx , dx  
                je doneDH
                call L_Highlight
                call goLeft
                jmp forDH
            doneDH:
                call goDown
                jmp check
        R_Highlight:
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
        call R
        jmp check   
            
        L_High:
        call goLeft
        call L_Highlight
        
        jmp check
        L_Highlight:
        call readChar
        cmp al , 0x0 
        je LD
        cmp ah , highlight_color
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
              call R
              dec dword[Highlight_Length]
              jmp check
                  
        L_Un_Highlight:
                mov dl , [cursor_col] 
                mov dh , [cursor_row] 
                cmp dx  , 0 
                je LUH
                mov [esi] , al 
                dec dword[N] 
                inc esi
                dec dword[Highlight_Length]
                call Un_Highlight
               LUH:ret                                      
;;;;;;;;;;;;;;;;;;;;;; M-U-L-T-I   -T-A-B-S;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       
F2:
       cli 
      pushad
      mov edx, [last_row]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_rows+ecx*4] , edx 
      mov al , 1
      mov ah , 5
      int 10h 
      popad
      pushad
      mov byte[pageNumber] ,1 
      pushad
      call getCrusorPosition
      mov byte[cursor_row] , dh
      mov byte[cursor_col] , dl
      popad
        xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_rows+ecx*4]
      mov [last_row] , edx 
      jmp check 
      
      
F1:
      cli 
      push ebx
      mov edx, [last_row]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_rows+ecx*4] , edx 
      
      mov al , 0
      mov ah , 5
      int 10h
     
      mov byte[pageNumber] ,0 
      push edx 
      call getCrusorPosition
      mov byte[cursor_row] , dh
      mov byte[cursor_col] , dl
      pop edx
      xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_rows+ecx*4]
      mov [last_row] , edx 
      jmp check 
       pop ebx
       
       
F3:
      cli 
      pushad
      mov edx, [last_row]
      xor ecx ,  ecx
      mov cl , [pageNumber] 
      mov [last_page_rows+ecx*4] , edx 
      
      mov al , 2
      mov ah , 5
      int 10h 
      popad
      pushad
      mov byte[pageNumber] ,2 
      
      xor ecx, ecx 
      mov cl , [pageNumber] 
      mov edx , [last_page_rows+ecx*4]
      mov [last_row] , edx 
      jmp check
      
     
;;;;;;;;;;;;;;;;;;;;;;COPY _ PASTE ;;;;;;;;;;;;;;;;;;;;;;

paste:
   cli 
   pushad
   cmp dword[len] , 0 
   je check
   mov esi , [copied_address]
   cld
   for_paste:
   push ecx
   call shiftRight
   lodsb
   call writeChar
   call goRight
   pop ecx
   inc ecx 
   cmp ecx , [len] 
   jl for_paste
   popad 
   mov esi , scString
   jmp check
   
   
copy:
   cmp dword[Highlight_Length] , 0 
   je check
   mov ecx , [N] 
   mov [len] , ecx
   mov [copied_address] , si
   mov si , scString
   mov dword[N] , 0
   jmp check
   
cut:
    cmp dword[Highlight_Length] , 0 
    je check
   cmp dword[N] ,  0 
   je copied_befor
   mov ecx , [N] 
   mov [len] , ecx
   mov [copied_address] , si
   mov si , scString
   mov dword[N] , 0
   copied_befor:
   cmp word[copied_address] , scString 
   je right 
   mov ecx , [len]
   call R
   call R
   forF:
    push ecx
    call R
    pop ecx
    loop forF   
    
    jmp right
  
   right:
   
    mov ecx , [len] 
    forB:
    pushad
    call BackSpace
    popad
    loop forB
    call BackSpace
    call UN_Highlight_Screen  
    jmp check     
    
    
selectAll:
    pushad
     mov byte[ all_selected] , 1
    push dword[cursor_col]
    push dword[cursor_row]
     mov ecx , [last_row] 
    mov dword[cursor_row] , 0
    call getLastCol
    mov dword[cursor_col] , 0  
    call setCursorPosition
    mov edi , scString
    cld
    for_select:
            call readChar         
            inc dword[N]
            stosb
            call Highlight
            call R
            mov dl , [cursor_col] 
            mov dh , [cursor_row]
            call getLastCol
            mov cl , al 
            mov ch , [last_row]
            cmp dx , cx
            jne for_select
    mov esi , edi        
    pop dword[cursor_row]
    pop dword[cursor_col]
    call setCursorPosition
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
    jnz cut
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
        
        mov dword[cursor_row] , 0
        call setCursorPosition
        jmp check
pg_dn:
        mov ecx , [last_row]
        mov dword[cursor_row] , ecx
        call setCursorPosition
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
            mov al , '6'              
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
            call R
            jmp check
            R:
            call readChar
            cmp  al ,  0
            je last_Of_A_line
            call goRight
            ret
            last_Of_A_line:
                mov ecx, [cursor_row]
                cmp dword[last_row] , ecx
                je dRr
                
                inc dword[cursor_row]   
                mov dword[cursor_col] , 0 
                call setCursorPosition
                
                
            dRr:
                ret            
            
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
            mov ecx, dword[last_row]
            cmp dword[cursor_row] , ecx 
            je doneD 
            inc dword[cursor_row]
            call setCursorPosition
            call readChar
            cmp al , 0
            jne doneD
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
            cmp dword[cursor_row] , 0 
            je doneU 
            dec dword[cursor_row]
            call setCursorPosition
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
        cmp dword[cursor_col] , 0
        je go_Line        
        dec dword[cursor_col] 
        call setCursorPosition
      r:
      ret
      
       go_Line:
            cmp dword[cursor_row] , 0 
            je r
            dec dword[cursor_row] 
            pushad
            call getLastCol
            mov [cursor_col] , eax
            
            call setCursorPosition
            popad
            ret                                       
goRight:
        pushad
        cmp dword[cursor_col] , 79
        jge goNew_Line        
        inc dword[cursor_col] 
        call setCursorPosition        
        popad
        ret
      
       goNew_Line:
            inc dword[cursor_row] 
            mov dword[cursor_col] , 0 
            call setCursorPosition
            popad
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
     push dword[cursor_col] 
     call setCursorPosition
     
     forSearch:
        call readChar 
        cmp al , 0 
        je doneSearch
        inc dword[cursor_col]
        call setCursorPosition 
        jmp forSearch
        
     doneSearch:
     mov eax , [cursor_col]
     pop dword[cursor_col]
     call setCursorPosition       
     leave
     ret
     
    
setCursorPosition:
    cli 
    enter 0 ,0 
    pushad
        mov dh, [cursor_row]
        mov dl, [cursor_col]
        mov bh, [pageNumber]
        mov ah, 2
        int 10h
     popad     
    leave
    
    ret 
    
Highlight:
    cli 
    enter 0 , 0
    pushad
    call readChar
    mov cx , 1
    mov bl , highlight_color
    mov bh , [pageNumber]
    mov ah , 09h
    int 10h
    inc dword[Highlight_Length]
    popad
    leave 
    ret
    
    
Un_Highlight:
    enter 0 , 0
    cli 
    pushad
    mov bh , [pageNumber]
    mov ah , 08h 
    int 10h 
    mov cx , 1
    mov bl , normal_color
    mov bh , [pageNumber]
    mov ah , 09h
    int 10h
    ;dec dword[Highlight_Length]
    popad
    leave     
    ret
    
UN_Highlight_Screen:
    enter 0,0
     mov byte[ all_selected] , 0  
    mov dword[N] ,  0 
    mov  dword[Highlight_Length] , 0
    mov si , scString
    pushad
        push dword[cursor_row] 
        push dword[cursor_col]
        mov dword[cursor_row] , 0 
        mov dword[cursor_col] , 0 
        call setCursorPosition
        mov ecx , 0
        forL:
        cmp ecx , 2000
        jge  doe
        push ecx
        call Un_Highlight
        call goRight
        call setCursorPosition
        pop ecx
        inc ecx
        jmp forL
        doe:
         pop  dword[cursor_col] 
         pop  dword[cursor_row] 
        call setCursorPosition
    popad     
    leave 
    ret
    
    
    
    ;;; input a char to write in al ;; 
    
writeChar:
    pushad
    cli 
    mov ah , 09h 
    mov bh , [pageNumber] 
    mov bl , normal_color
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
        
;;;;;;;;;;;;;;;;;;Monitor Ops:  uses monitor_col   , monitor_row 

;;;;; char to display at al 

writeCharAtMonitor:
   push dword[cursor_row] 
   push dword[cursor_col]
   mov  dl , [monitor_col]
   mov dh , [monitor_row]
   mov [cursor_row] , dh
   mov [cursor_col] , dl
   call setCursorPosition
   call writeChar
   pop dword[cursor_col]
   pop dword[cursor_row] 
   call setCursorPosition
   ret                  

goRightInMonitor:
      cmp dword[monitor_col] , 79
      jge goNew_Line1        
      inc dword[monitor_col] 
      ret
       goNew_Line1:
            inc dword[monitor_row] 
            mov dword[monitor_col] , 0 
            ret
goLeftInMonitor:
      cmp dword[monitor_col],0
      jle goPre_Line1
      dec dword[monitor_col]
      ret
      goPre_Line1:
            dec dword[monitor_row]
            mov dword [monitor_col],79
            ret

readCharAtMonitor:
   
   push dword[cursor_row] 
   push dword[cursor_col]
   mov  dl , [monitor_col]
   mov dh , [monitor_row]
   mov [cursor_row] , dh
   mov [cursor_col] , dl
   call setCursorPosition
   call readChar
   ;;al = char
   pop dword[cursor_col]
   pop dword[cursor_row] 
   call setCursorPosition
   ret                  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SHIFTING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
shiftRight:
    pushad
    mov ecx , [cursor_row] 
    mov [monitor_row], ecx
    mov ecx , [cursor_col] 
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
    mov ecx , [cursor_row] 
    mov [monitor_row], ecx
    mov ecx , [cursor_col] 
    mov [monitor_col], ecx
    mov eax , [cursor_col] 
    mov ecx , 80
    sub ecx , eax
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
    mov ecx ,   80
    mov [a] , ecx
    mov edi , st
    cld 
   forShD:
        call readChar 
        stosb
        mov al , 0 
        call writeChar
        call goRight
   loop forShD
    mov al  , 0
    mov ah , 13h
    mov ecx , [a]
    mov dl , 0
    mov dh , [cursor_row] 
    mov bp , st
    push cs 
    pop es
    mov bh , [pageNumber]
    mov bl , normal_color
    int 10h
   mov dword[cursor_col] ,  0
   call setCursorPosition
   popad
   leave
   ret
    
    
    
ShiftUp:
    enter 0,0 
    pushad
    push dword[cursor_row] 
    push dword[cursor_col] 
    call goLeft
    mov eax , [cursor_col]
    pop dword[cursor_col] 
    pop dword[cursor_row] 
    ;;;;;;last col in eax       
    call setCursorPosition
    ;;;;;;;;;;;;;;;;;;;itration
    push eax
    xor  edx , edx
    cld
    mov ecx , 80
    mov edi , st
 forShU:
    call readChar
    push eax
    mov al , 0 
    call writeChar 
    pop eax 
    stosb 
    call goRight
    inc edx
 loop forShU
    cli 
    pop eax
    mov dword[cursor_col] , eax
    dec dword[cursor_row]
    dec dword[cursor_row]
    mov al  , 0
    mov ah , 13h
    mov ecx , edx
    mov dl , [cursor_col]
    mov dh , [cursor_row] 
    mov bp , st
    push cs 
    pop es
    mov bh , [pageNumber]
    mov bl , normal_color
    int 10h
    
    call setCursorPosition
    popad
    leave
    ret
    
    ;input: eax: row number
pullUp:
    enter  0,0
    pushad
    push dword[cursor_row] 
    push dword[cursor_col] 
    
    mov [cursor_row] , eax
    mov dword[cursor_col]  ,  0
    call setCursorPosition
    mov ecx, 80
forPullU:
    
    call readChar
    mov bl , al
    mov al , 0 
    call writeChar
    mov al , bl
    dec dword[cursor_row]
    call setCursorPosition
    call writeChar
    inc dword[cursor_row]
    inc dword[cursor_col]
    call setCursorPosition
    loop forPullU
    
    pop dword[cursor_col] 
    pop dword[cursor_row] 
    call setCursorPosition

    
    popad
    leave
    ret
    
    
    ;;input:  eax: row number  
    pullDown:
    enter  0,0
    pushad
    push dword[cursor_row] 
    push dword[cursor_col] 
    
  ;  mov eax , [ebp+8] 
    mov [cursor_row] , eax
    mov dword[cursor_col]  ,  0
    call setCursorPosition
    mov ecx, 80
    forPullD:
    
    call readChar
    mov bl , al
    mov al , 0 
    call writeChar
    mov al , bl
    inc dword[cursor_row]
    call setCursorPosition
    call writeChar
    dec dword[cursor_row]
    inc dword[cursor_col]
    call setCursorPosition
    loop forPullD
    
    pop dword[cursor_col] 
    pop dword[cursor_row] 
    call setCursorPosition
    
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
    last_row: dd 0
    last_page_rows: dd 0 ,0,0,0,0,0,0,0 
    monitor_col: dd 0 
    monitor_row: dd 0 
    cursor_col: dd  0 
    cursor_row: dd 0
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;status
    Num_Status: db 0 
    shift_pressed: db 0
    ctrl_pressed: dd 0   
    Enter_Counter: dd  0 
    caps_Status: db 0
    Highlight_Length: dd  0 
    all_selected: db 0
    ;;;;;;;;;;;;;;;;
    tmp: db 0 
    highlight_color equ 0x30
    normal_color equ 0xf0
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
