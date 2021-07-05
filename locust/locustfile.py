import random
from locust import HttpUser, task, between
from uuid import uuid4
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class QuickstartUser(HttpUser):
	wait_time = between(1,1)
	host = "https://192.168.100.153:4201/polls/3"

	@task
	def getPoll(self):
		id = uuid4().hex
		Poll = 3
		u = "https://192.168.100.153:4201/polls/3"
		self.client.get(url=u,
			headers={"subject-uuid": id, "Cookie": "sub="+id},
			verify=False,
		)

	# @task
	def vote(self):
		id = uuid4().hex
		#print("User ID (%s) Generated" % self)
		# r = random.randint(1, 5)
		Items = [ random.randint(0,1) ]
		Poll = 3
		#Poll = random.randint(3,103)
		d = {"Items": Items, "Poll": 3}
		u = "https://192.168.100.153:4201/polls/3/v"
		print("Data: ", u , d)
		self.client.post(
			url=u,
			json={"Items": Items, "Poll": 3},
			headers={"subject-uuid": id, "Cookie": "sub="+id},
			verify=False,
		)

