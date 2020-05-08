import string

def parse_ip (input_str):
    ip = input_str.split('.')
    ip_addr = '0x'
    if (len(ip) != 4):
        return('',-1)
    for element in ip:
        if (element.strip().isdigit() and int(element) <= 255):
            new_elem = '' + hex(int(element))
            if (len(new_elem) == 3):
                ip_addr = ip_addr + '0' + new_elem[2].upper()
            else:
                ip_addr = ip_addr + new_elem[2:4].upper()
        else:
            return('',-1)
    return(ip_addr,0)

def parse_ip_subnet (input_str):
    split_ip = input_str.split('/')
    a,b = parse_ip(split_ip[0])
    if (b!= 0):
        return ('','',-1)
    if (split_ip[1].strip().isdigit() and (int(split_ip[1]) <= 32) ):
        mask = int(split_ip[1])
        sub_ip = '0x'
        for i in range(4):
            if (mask >= 8):
                sub_ip = sub_ip + 'FF'
                mask = mask - 8
            elif (mask == 7):
                sub_ip = sub_ip + 'FE'
                mask = 0
            elif (mask == 6):
                sub_ip = sub_ip + 'FC'
                mask = 0
            elif (mask == 5):
                sub_ip = sub_ip + 'F8'
                mask = 0
            elif (mask == 4):
                sub_ip = sub_ip + 'F0'
                mask = 0
            elif (mask == 3):
                sub_ip = sub_ip + 'E0'
                mask = 0
            elif (mask == 2):
                sub_ip = sub_ip + 'C0'
                mask = 0
            elif (mask == 1):
                sub_ip = sub_ip + '80'
                mask = 0
            elif (mask == 0):
                sub_ip = sub_ip + '00'
                mask = 0
        return (a,sub_ip,0)
    return('','',-1)

def mac_parser(input_str):
    a = input_str.upper().strip()
    final_mac = '0x'
    mac_arr = ['','','','','','']
    if (a.find(":") != -1):
        a = a.split(":")
        if (len(a)!=6):
            return ('',-1)
        mac_arr = a
    elif (a[0:2] == '0X'):
        if (len(a) < 14):
            a = a[0:2]+'0'*(14-len(a))+a[2:]
        elif (len(a) > 14):
            return('',-1)
        index = 2
        for i in range(6):
            mac_arr[i] = a[index:index + 2]
            index = index + 2
    else:
        if (len(a) < 12):
            a = '0'*(12-len(a))+a
        elif (len(a) > 12):
            return('',-1)
        index = 0
        for i in range(6):
            mac_arr[i] = a[index:index + 2]
            index = index + 2
    for i in mac_arr:
        if len(i) == 0:
            i = '00'
        elif len(i) == 1:
            i = '0'+i
        elif (len(i) > 2 or (i[0] not in string.hexdigits) or (i[1] not in string.hexdigits)):
            return ('',-1)
        final_mac = final_mac + i
    return (final_mac, 0)


print("Enter the ip address and subnet mask of the storage server as x.x.x.x/x (eg 10.0.0.2/24):")

ret_val = -1
ip = ""
subnet = ""
while (ret_val != 0):
    input1 = str(raw_input())
    (ip,subnet,ret_val)=parse_ip_subnet(input1)
    if (ret_val != 0):
        print("Invalid value, try again:")

f=open('ip_addr.txt','w')

f.write(ip)

f.close()

f=open('subnet.txt','w')

f.write(subnet)

print("Enter the address of the gateway as x.x.x.x (eg 10.0.0.1):")

ret_val = -1
ip = ""
while (ret_val != 0):
    input1 = str(raw_input())
    (ip,ret_val)=parse_ip(input1)

    if (ret_val != 0):
        print("Invalid value, try again:")

f=open('gateway_addr.txt','w')

f.write(ip)

f.close()

print("Enter the mac address as either a hex number or mac address format (AABBCCDDEEFF or 0xAABBCCDDEEFF or AA:BB:CC:DD:EE:FF all work):")

ret_val = -1
ip = ""

while (ret_val != 0):
    input1 = str(raw_input())
    (ip,ret_val)=mac_parser(input1)

    if (ret_val != 0):
        print("Invalid value, try again:")

f=open('mac_addr.txt','w')

f.write(ip)

f.close()

