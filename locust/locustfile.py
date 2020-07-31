import random
from locust import HttpUser, task, between
from uuid import uuid4


class QuickstartUser(HttpUser):
    wait_time = between(2, 12)
    host = "192.168.100.211:8182"
    choices = ["RED", "GREEN", "YELLOW", "BLUE"]

    @task
    def vote(self):
        id = uuid4().hex
        print("User ID (%s) Generated" % self)
        r = random.randint(0, 3)
        self.client.post(
            url="/polls/11",
            data={"vote": self.choices[r]},
            headers={"Subject-UUID": id}
        )
