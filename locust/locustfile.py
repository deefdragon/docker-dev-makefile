import random
from locust import HttpUser, task, between
from uuid import uuid4
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class QuickstartUser(HttpUser):
	wait_time = between(1,1)
	host = "https+insecure://192.168.100.211:4201/polls/3"

	
	@task
	def vote(self):
		id = uuid4().hex
		#print("User ID (%s) Generated" % self)
		r = random.randint(1, 5)
		Items = [ random.randint(0,6) ]
		Poll = 3
		self.client.post(
			url="/polls/"+ str(Poll) +"/v",
			data={"Items": Items, "Poll": Poll},
			headers={"Subject-UUID": id, "Cookie": "sub="+id},
			verify=False,
		)
