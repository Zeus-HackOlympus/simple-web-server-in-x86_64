#!/usr/bin/env python3 
import requests 
import tempfile 
import string 
import os 
from random import randint, choice 

url = "http://localhost" 

def get(path):
    print(url + path, end=" ")
    return requests.get(url + path)

def post(path, d):
    print(url + path, end=" ")
    return requests.post(url + path, data=d) 

def get_random_data(len):
    return "".join([choice(string.ascii_letters) for i in range(len)]).encode()


def main():
    for _ in range(100):
        op = randint(0,1)
        if (op == 0) :
            print("GET request ", end="") 
            randdata = get_random_data(10) 
            f = tempfile.NamedTemporaryFile()
            f.write(randdata) 
            f.flush()
            req = get(f.name)
            print(f"Got: {req.text}", end=" ")
            if req.status_code == 200 and req.text.encode() == randdata: 
                print("Success")
            else: 
                print("Failed")          
              
        else : 
            print("POST request ", end="")
            randdata = get_random_data(10) 
            path = "/tmp/" + get_random_data(5).decode()
            req = post(path, randdata) 

            if req.status_code == 200 and open(path,"rb").read() == randdata: 
                print("Success")
            else:
                print("Failed") 

main()
