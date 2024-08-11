module main

import os
import strconv
import json
import veb
import net.http
import rand

fn main() {
	mut n := 10
	if os.args.len == 2 {
		n = strconv.atoi(os.args[1]) or { 10 }
	}
	port := int(rand.u32_in_range(20000, 50000) or { 23333 })
	mut app := &App{}
	spawn veb.run[App, Context](mut app, port)
	url := 'http://localhost:${port}/api'
	mut ch := chan int{cap: n}
	for i in 1 .. (n + 1) {
		spawn send(url, i, ch)
	}
	mut sum := 0
	for _ in 0 .. n {
		sum += <-ch
	}
	println(sum)
}

fn send(url string, v int, ch chan int) {
	for true {
		response := http.post_json(url, json.encode(Payload{ value: v })) or { continue }
		ch <- strconv.atoi(response.body) or { 0 }
		return
	}
}

pub struct App {}

struct Context {
	veb.Context
}

@['/api'; post]
pub fn (mut app App) api(mut ctx Context) veb.Result {
	data := json.decode(Payload, ctx.req.data) or {
		Payload{
			value: 0
		}
	}
	return ctx.text(data.value.str())
}

struct Payload {
	value int @[json: 'value']
}
