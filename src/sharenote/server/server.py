#!/usr/bin/env python3

import io
import os
import json
import socket
import threading

from flask import Flask, send_file
from PIL import Image, ImageDraw

HOST = "0.0.0.0"
PORT = 65432  # Port to listen on (non-privileged ports are > 1023)

WIDTH = 1404
HEIGHT = 1872

# TODO:
# * room messages
# * validate messages
# * init message
# * (MSG, DATA) proto

class Room:
    def __init__(self, name="default"):
        self.clients = []
        self.name = name
        self.msgs_file = "/tmp/room_"+name+"_msgs"
        self.write_handle = open(self.msgs_file, "wb")
        self.image = Image.new("L", (WIDTH, HEIGHT), 255)
        self.image_file = "/tmp/room_"+name+"_img"
        self.imgdraw = ImageDraw.Draw(self.image)
        self.lock = threading.Lock()

        if os.path.exists(self.image_file):
            self.image = Image.open(self.image_file)

        if os.path.exists(self.msgs_file):
            with open(self.msgs_file, "rb") as f:
                for line in f.readlines():
                    msg_obj = json.loads(line)
                    x, y, px, py = (
                        msg_obj["x"],
                        msg_obj["y"],
                        msg_obj["prevx"],
                        msg_obj["prevy"]
                    )
                    self.imgdraw.line(
                        [(px, py), (x, y)],
                        fill=msg_obj["color"],
                        width=msg_obj["width"]
                    )


    def __del__(self):
        with self.lock:
            self.write_handle.close()

    def add(self, client):
        with self.lock:
            self.clients.append(client)
            self.write_handle.flush()

            with open(self.msgs_file, 'rb') as f:
                client.conn.sendall(f.read())

    def remove(self, client):
        with self.lock:
            print("Removing connection", client.conn.addr)
            self.clients.remove(client)

    def send(self, msg_str):
        with self.lock:
            for client in self.clients:
                try:
                    client.conn.sendall(msg_str + b'\n\n')
                except:
                    pass

            # make thread safe?
            self.write_handle.write(msg_str + b'\n')
            self.write_handle.flush()

    def clear(self):
        print("Clearing room")
        with self.lock:
            self.image = Image.new("L", (WIDTH, HEIGHT), 255)
            self.clear_log()

        self.send(b'{"type":"clear"}')

    def clear_log(self):
        self.write_handle.truncate()



_rooms = { "default": Room(name="default")}
room_lock = threading.Lock()


class ClientThread(threading.Thread):
    def __init__(self, addr, conn):
        threading.Thread.__init__(self)
        self.conn = conn
        self.addr = addr
        self.room = None

    def __del__(self):
        with room_lock:
            if self.room in _rooms:
                _rooms[self.room].remove(self)

    def join(self, room):
        print("New connection added: ", self.addr, "to room", room)
        with room_lock:
            if room not in _rooms:
                _rooms[room] = Room(name=room)
            _rooms[room].add(self)
            self.room = room
        # TODO send URL with image download

    def handle_message(self, msg_obj):
        if msg_obj["type"] == "join":
            self.join(msg_obj["room"])

        if self.room == None:
            return

        if msg_obj["type"] == "draw":
            x, y, px, py = (
                msg_obj["x"],
                msg_obj["y"],
                msg_obj["prevx"],
                msg_obj["prevy"]
            )
            room = _rooms[self.room]
            room.imgdraw.line(
                [(px, py), (x, y)],
                fill=msg_obj["color"],
                width=msg_obj["width"]
            )
            msg_str = bytes(json.dumps(msg_obj), encoding='utf8')
            with room_lock:
                _rooms[self.room].send(msg_str)
        elif msg_obj["type"] == "clear":
            with room_lock:
                _rooms[self.room].clear()

    def run(self):
        # self.csocket.send(bytes("Hi, This is from Server..",'utf-8'))
        messages = []
        message = b""
        while True:
            try:
                data = self.conn.recv(1024)
            except ConnectionResetError:
                with room_lock:
                    _rooms[self.room].remove(self)
                return
            if not data:
                break
            chunks = data.split(b"\n")
            for chunk in chunks[:-1]:
                message += chunk
                messages.append(json.loads(message))
                message = b""
            message += chunks[-1]
            if data[-1] == "\n":
                messages.append(json.loads(message))
                message = b""

            for msg_obj in messages:
                self.handle_message(msg_obj)

            messages = []
        self.conn.close()


app = Flask(__name__)

@app.route('/room/<room>')
def get_room_image(room):
    s = io.BytesIO()
    with room_lock:
        if room not in _rooms:
            return "room not found"
        room = _rooms[room]

#    with room.lock:
#        im = room.image
#        im.save(room.image_file, format="png")
#        im.save(s, format="png")
#        room.clear_log()
    bytes = s.getvalue()
    return bytes

def listen_socket():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        print("server started")

        while True:
            s.listen()
            conn, addr = s.accept()
            newthread = ClientThread(addr, conn)
            newthread.start()

def listen_http():
    app.run(host="0.0.0.0", port=65431)

def main():
    thread_socket = threading.Thread(target=listen_socket)
    thread_http = threading.Thread(target=listen_http)

    thread_socket.start()
    thread_http.start()

    thread_socket.join()
    thread_http.join()

main()
