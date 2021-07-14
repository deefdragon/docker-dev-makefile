#!/usr/bin/python

import random
import gevent
import urllib3
import ssl
import time


from locust import HttpUser, task, between, events
from websocket import create_connection

from uuid import uuid4

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


host = "192.168.100.153:4201"
print("Default host: %s" % (host))
class QuickstartUser(HttpUser):
	wait_time = between(1,1)
#get poll
#get vote
#post vote
#get poll
#get vote
#get results
	def on_start(self):
		self.wsLoop = True
		print("test")
		if not self.host:
			self.host = host
			print("setting host to %s" % self.host)

	def on_stop(self):
		print("closing WS. %s" % self.id)
		self.wsLoop = False
		time.sleep(1)
		self.ws.close()

	@task
	def userFlow(self):
		print("loop status: %s" % self.wsLoop)
		id = uuid4().hex
		self.id = id
		poll = 3
		self.httpEndpoint = "https://" + self.host + "/polls/" + str(poll)
		self.wsEndpoint = "wss://" + self.host + "/polls/" + str(poll)
		getPoll(self, id, poll)
		getVote(self, id, poll)
		postVote(self, id, poll)
		getPoll(self, id, poll)
		getVote(self, id, poll)
		getResults(self, id, poll)


def getPoll(self, id, poll):
	dest = self.httpEndpoint

	print("getPoll: (%d)" % poll)
	self.client.get(url=dest,
		headers={"subject-uuid": id},
		verify=False,
	)

def getVote(self, id, poll):
	dest = self.httpEndpoint + "/v"

	print("getVote: (%d)" % poll)
	self.client.get(
		url=dest,
		headers={"subject-uuid": id},
		verify=False,
	)

def postVote(self, id, poll):
	Items = [ random.randint(0,1) ]
	voteData = {"Items": Items, "Poll": poll}
	dest = self.httpEndpoint + "/v"

	print("postVote: (%d), (%s)" % (poll, voteData))
	self.client.post(
		url=dest,
		json=voteData,
		headers={"subject-uuid": id},
		verify=False,
	)

def getResults(self, id, poll):

	dest = self.wsEndpoint + "/r"
	print("wsResults: (%d)" % poll)
	ws = create_connection(dest, 
		sslopt={"cert_reqs": ssl.CERT_NONE},
		header={"subject-uuid": id, "Cookie": "dev_sub="+id}
	)
	self.ws = ws
	# TODO should actually be adding these to an array, and closing ALL of them.

	def _receive():
		while True:
			res = ws.recv()
			# data = json.loads(res)
			events.request_success.fire(
				request_type='WebSocket Recv',
				name="polls/" + str(poll)+"/results",
				response_time=0,
				response_length=len(res),
			)
			ws.send("PONG")
			print("data back (%s) %s" % (id, res))

		print("done watching data.")

	
	_receive()
	# gevent.spawn(_receive)

