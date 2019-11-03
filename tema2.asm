extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main

xor_strings:
       push ebp
       mov ebp, esp
       
       ; extragem adresa sirului si cheii
       mov eax, dword[ebp + 8] 
       mov esi, dword[ebp + 12]
       xor edi, edi ; indexul din sir
task1_loop:
       ; parcurgem sirul byte cu byte, pana la null
       xor edx, edx
       mov dl, byte[eax + edi]
       cmp dl, 0
       je exit1
       xor ebx, ebx
       ; parcurgem cheia byte cu byte
       mov bl, byte[esi + edi]
       xor dl, bl
       ; decodificam sirul
       mov byte[eax + edi], dl
       inc edi
       jmp task1_loop
exit1:
       mov ecx, eax
       leave
       ret

rolling_xor:
       push ebp
       mov ebp, esp
       
       mov eax, dword[ebp + 8]
       xor edi, edi
       xor edx, edx
       ; primul byte nu este codificat
       mov dl, byte[eax + edi]
task2_loop:
       inc edi
       xor ebx, ebx
       mov bl, byte[eax + edi]
       cmp bl, 0
       je exit2
       ; folosim secvenial byte-ul codificat anterior pentru
       ; a decodifica byte-ul curent
       xor bl, dl
       mov dl, byte[eax + edi]
       mov byte[eax + edi], bl
       jmp task2_loop       
exit2:
       mov ecx, eax
       leave
       ret

; functie care converteste un string de hex
; in string de binary
hex_to_binary:
       push ebp
       mov ebp, esp
       
       mov ecx, dword[ebp + 8]
       xor esi, esi
       xor edi, edi
convert:
       xor eax, eax
       xor edx, edx
       xor ebx, ebx
       mov edi, esi
convert_loop:
       ; se iau cate doua caractere hex pentru
       ; a forma un byte (deci 2 halfbytes)
       mov edx, edi
       sub edx, esi
       cmp edx, 2
       je exit_convert
       mov dl, byte[ecx + edi]
       cmp dl, 0
       je exit_convert
       cmp dl, '9'
       ; are cod ASCII mai mare, atunci e litera
       ja letter
       ; obtinem cifra in sine
       mov al, dl
       sub al, '0'
       jmp add_to_number
letter:
       ; obtinem numarul din spatele literei
       mov al, dl
       sub al, 'a'
       add al, 10
add_to_number:
       ; obtinem un byte prin shiftarea la stanga cu 4 biti
       ; si efectuarea SAU cu al doilea halfbyte obtinut
       shl bl, 4
       or bl, al
       inc edi
       jmp convert_loop
exit_convert:
       dec edi
       ; mut byte-ul obtinut in sirul initial
       mov esi, edi
       mov byte[ecx + edi], bl
move_bytes:
       ; am inlocuit 2 caractere (2 bytes) cu unul singur
       ; mut tot ce am obtinut pana acum cu o pozitie la dreapta
       ; peste pozitia primului din cele 2 caractere tocmai analizate
       dec edi
       test edi, edi
       jz exit3
       xor ebx, ebx
       mov ebx, edi
       dec ebx
       xor eax, eax
       mov al, byte[ecx + ebx]
       mov byte[ecx + edi], al
       jmp move_bytes
exit3:
       add ecx, 1
       mov dl, byte[ecx + esi]
       cmp dl, 0
       jne convert
       leave
       ret

xor_hex_strings:
       push ebp
       mov ebp, esp
       
       ; transform ambele siruri din hex in binar
       mov eax, dword[ebp + 8]
       push eax
       call hex_to_binary
       add esp, 4
       push ecx
        
       mov eax, dword[ebp + 12]
       push eax
       call hex_to_binary
       add esp, 4
       mov esi, ecx
       pop ecx
       
       ; apelez functia de la Task 1 pe rezultate
       push esi
       push ecx
       call xor_strings
       add esp, 8
       
       leave
       ret

base32decode:
       push ebp
       mov ebp, esp
       
       xor edx, edx
       xor esi, esi ; indice in sirul initial
       mov ecx, dword[ebp + 8]
       
       ; obtinem valoarea reala din spatele
       ; codurilor ASCII
real_value:
       mov dl, byte[ecx + esi]
       cmp dl, 0
       je real_obtained
       ; egalul e inlocuit cu octetul zero
       cmp dl, '='
       je egal
       cmp dl, 'Z'
       jg continue4
       cmp dl, 'A'
       jl cifra
       ; literele si cifrele sunt transformate conform
       ; codificarii
       sub dl, 65
       jmp continue4
egal:
       sub dl, 61
       jmp continue4
cifra:
       cmp dl, '7'
       jg continue4
       cmp dl, '2'
       jl continue4
       sub dl, 24
continue4:
       mov byte[ecx + esi], dl
       inc esi
       jmp real_value
real_obtained:  
       xor esi, esi
       xor eax, eax
       xor ebx, ebx ; contor pentru cele 5 cazuri
       xor edi, edi ; contor in sirul final
       ; din fiecare octet, trebuie sa eliminam
       ; cate 3 biti de zero
restructure:
       mov dl, byte[ecx + esi]
       cmp dl, 0
       je exit4
       ; cazurile se repeta din 8 in 8 octeti
       cmp ebx, 0
       je caz_zero
       cmp ebx, 1
       je caz_unu
       cmp ebx, 2
       je caz_doi
       cmp ebx, 3
       je caz_trei
       cmp ebx, 4
       je caz_patru
       
       ; obtinem octetii doriti prin shift si OR
       ; pe cate 2 sau 3 octeti vecini
caz_zero:
       mov dl, byte[ecx + esi]
       mov al, byte[ecx + esi + 1]
       shl dl, 3
       shr al, 2
       or dl, al
       mov byte[ecx + edi], dl
       inc edi
       inc ebx
       jmp restructure
caz_unu:
       mov dl, byte[ecx + esi + 1]
       mov al, byte[ecx + esi + 2]
       push ebx
       mov bl, byte[ecx + esi + 3]
       shl dl, 6
       shl al, 1
       shr bl, 4
       or dl, al
       or dl, bl
       mov byte[ecx + edi], dl
       inc edi
       pop ebx
       inc ebx
       jmp restructure
caz_doi:
       mov dl, byte[ecx + esi + 3]
       mov al, byte[ecx + esi + 4]
       shl dl, 4
       shr al, 1
       or dl, al
       mov byte[ecx + edi], dl
       inc edi
       inc ebx
       jmp restructure
caz_trei:
       mov dl, byte[ecx + esi + 4]
       mov al, byte[ecx + esi + 5]
       push ebx
       mov bl, byte[ecx + esi + 6]
       shl dl, 7
       shl al, 2
       shr bl, 3
       or dl, al
       or dl, bl
       mov byte[ecx + edi], dl
       inc edi
       pop ebx
       inc ebx
       jmp restructure
caz_patru:
       mov dl, byte[ecx + esi + 6]
       mov al, byte[ecx + esi + 7]
       shl dl, 5
       or dl, al
       mov byte[ecx + edi], dl
       inc edi
       xor ebx, ebx ; resetam contorul de caz
       add esi, 8 ; inaintam in sirul initial
       jmp restructure
       
exit4:
       leave
       ret

bruteforce_singlebyte_xor: 
       push ebp
       mov ebp, esp
       
       mov ecx, dword[ebp + 8]
       xor eax, eax
       xor ebx, ebx
       xor edx, edx
       ; aplic metoda bruteforce: parcurg toate 
       ; cheile de la 0 la 255 - un octet complet
task5_loop:
       cmp bl, 255
       ja found5
       xor edi, edi
find_force:
       ; caut pentru fiecare cheie aparitia cuvantului
       ; "force" in sirul decriptat
       mov dl, byte[ecx + edi]
       cmp dl, 0
       jne continue 
       inc bl
       jmp task5_loop
continue:
       xor dl, bl
       cmp dl, 'f'
       jne increment5
       mov esi, edi
       inc esi
       mov dl, byte[ecx + esi]
       xor dl, bl
       cmp dl, 'o'
       jne increment5
       inc esi
       mov dl, byte[ecx + esi]
       xor dl, bl
       cmp dl, 'r'
       jne increment5
       inc esi
       mov dl, byte[ecx + esi]
       xor dl, bl
       cmp dl, 'c'
       jne increment5
       inc esi
       mov dl, byte[ecx + esi]
       xor dl, bl
       cmp dl, 'e'
       je found5
increment5:
       inc edi
       jmp find_force
found5:
       ; cand il gasesc => cheie buna
       xor edi, edi
decode5:
       ; decodific acum intregul sir
       mov dl, byte[ecx + edi]
       cmp dl, 0
       je exit5
       xor dl, bl
       mov byte[ecx + edi], dl
       inc edi
       jmp decode5
       xor ebx, ebx
exit5:
       mov eax, ebx
       leave
       ret

decode_vigenere:
       push ebp
       mov ebp, esp
       
       mov ecx, dword[ebp + 8] 
       mov eax, dword[ebp + 12]
       xor edi, edi
       xor esi, esi
       xor edx, edx
       xor ebx, ebx
task6_loop:
       ; parcurg sirul si modific doar literele mici
       mov dl, byte[ecx + edi]
       cmp dl, 0
       je exit6
       cmp dl, 'a'
       jb increment6
       cmp dl, 'z'
       ja increment6
       mov bl, byte[eax + esi]
       cmp bl, 0
       jne continue6
       ; cand ma aflu la finalul cheii, repozitionez
       ; indexul la inceput pentru a o reparcurge
       ; pentru restul sirului
       xor esi, esi
       mov bl, byte[eax + esi]
continue6:
       inc esi
       ; obtin diferenta cu care s-a incrementat codul ASCII
       sub bl, 'a'
       
       ; nu mai aveam registrii liberi :))
       push eax
       
       ; probez daca, prin scaderea diferentei de la codificare
       ; raman in intervalul literelor mici
       mov al, dl
       sub al, bl
       sub al, 'a'
       jb depasire
       ; daca da, am obtinut caracterul initial
       add al, 'a'
       mov dl, al
       pop eax
       mov byte[ecx + edi], dl
       jmp increment6
depasire:
       ; daca nu, la codificare a existat o trecere peste Z
       mov bl, 'z'
       ; "adun" la codul lui Z diferenta negativa + 1 trecerea 
       ; de la A la Z
       add bl, al
       inc bl
       ; acum am obtinut caracterul initial
       mov dl, bl
       pop eax
       mov byte[ecx + edi], dl
increment6:
       inc edi
       jmp task6_loop     
exit6:
       leave
       ret

main:
       mov ebp, esp; for correct debugging
	push ebp
	mov ebp, esp
	sub esp, 2300

	; test argc
	mov eax, [ebp + 8]
	cmp eax, 2
	jne exit_bad_arg

	; get task no
	mov ebx, [ebp + 12]
	mov eax, [ebx + 4]
	xor ebx, ebx
	mov bl, [eax]
	sub ebx, '0'
	push ebx

	; verify if task no is in range
	cmp ebx, 1
	jb exit_bad_arg
	cmp ebx, 6
	ja exit_bad_arg

	; create the filename
	lea ecx, [filename + 7]
	add bl, '0'
	mov byte [ecx], bl

	; fd = open("./input{i}.dat", O_RDONLY):
	mov eax, 5
	mov ebx, filename
	xor ecx, ecx
	xor edx, edx
	int 0x80
	cmp eax, 0
	jl exit_no_input

	; read(fd, ebp - 2300, inputlen):
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80
	cmp eax, 0
	jl exit_cannot_read

	; close(fd):
	mov eax, 6
	int 0x80

	; all input{i}.dat contents are now in ecx (address on stack)
	pop eax
	cmp eax, 1
	je task1
	cmp eax, 2
	je task2
	cmp eax, 3
	je task3
	cmp eax, 4
	je task4
	cmp eax, 5
	je task5
	cmp eax, 6
	je task6
	jmp task_done

task1:
       ; Simple XOR between two byte streams

       ; inceputul cheii a fost identificat prin gasirea pozitiei
       ; caracterului terminator + 1
       mov ebx, ecx
       xor eax, eax
       mov al, 0
       mov edi, ecx
       repne scasb
       mov ecx, ebx
       sub edi, ecx
        
       ; call the xor_strings function
       mov eax, ecx
       add eax, edi
       push eax
       push ecx
       call xor_strings
       add esp, 8
       
       push ecx
       ; print resulting string
       call puts                   
       add esp, 4

       jmp task_done

task2:
       ; Rolling XOR

       ; call the rolling_xor function
       push ecx
       call rolling_xor
       add esp, 4
       
       push ecx
       call puts
       add esp, 4

       jmp task_done

task3:
       ; XORing strings represented as hex strings

       ; find the addresses of both strings
       mov ebx, ecx
       xor eax, eax
       mov al, 0
       mov edi, ecx
       repne scasb
       mov ecx, ebx
       sub edi, ecx
       
       ; call the xor_hex_strings function
       mov eax, ecx
       add eax, edi
       push eax
       push ecx
       call xor_hex_strings
       add esp, 8

       push ecx    
       ; print resulting string                 
       call puts
       add esp, 4

       jmp task_done

task4:
       ; Decoding a base32-encoded string

       ; call the base32decode function
       push ecx
       call base32decode
       add esp, 4
	
       push ecx
       ; print resulting string
       call puts                    
       pop ecx
	
       jmp task_done

task5:
       ; Find the single-byte key used in a XOR encoding

       ; call the bruteforce_singlebyte_xor function
       push ecx
       call bruteforce_singlebyte_xor
       add esp, 4
       
       
       push eax
       push ecx        
       ; print resulting string            
       call puts
       pop ecx
       
       pop eax
       ; eax = key value
       push eax                    
       push fmtstr
       ; print key value
       call printf                 
       add esp, 8

       jmp task_done

task6:  
       ; Decode Vignere cipher

       ; find the addresses for the input string and key
       ; call the decode_vigenere function
       
       ; prima parte din task era deja rezolvata..
	push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax

	push eax
       ; ecx = address of input string 
	push ecx                   
	call decode_vigenere
	pop ecx
	add esp, 4

	push ecx
	call puts
	add esp, 4

task_done:
	xor eax, eax
	jmp exit

exit_bad_arg:
	mov ebx, [ebp + 12]
	mov ecx , [ebx]
	push ecx
	push usage
	call printf
	add esp, 8
	jmp exit

exit_no_input:
	push filename
	push error_no_file
	call printf
	add esp, 8
	jmp exit

exit_cannot_read:
	push filename
	push error_cannot_read
	call printf
	add esp, 8
	jmp exit

exit:
	mov esp, ebp
	pop ebp
	ret
