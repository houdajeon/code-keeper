# Testing the API with Postman

The collection `cloud-design.postman_collection.json` holds 14 requests that
exercise the whole API through the load balancer: sign in, security checks,
movies, billing. Each request has automatic checks (the **Test Results**
tab), so the collection doubles as an end-to-end test suite.

| Folder | Requests | Checks |
|--------|----------|--------|
| 1. Sign in | Get access token | 200, a token was returned and saved |
| 2. Security checks | `/health` without a token, movies without a token, movies with a fake token | 200, 401, 401 |
| 3. Movies | Create, list, get by id, search, update, create without a title, delete, get the deleted movie | 201, 200, 200, 200, 200, 400, 200, 404 |
| 4. Billing | Send an order, send an order with missing fields | 200 "Message posted", 400 |

## Before you start

- The project must be running: `scripts/deploy.sh` (COMMANDS.md, step 5).
  Postman talks to the real load balancer, so with nothing deployed every
  request fails to connect.
- Sign in to Postman. The website <https://go.postman.co>, the desktop app
  or the VS Code extension all work, but only when signed in: without an
  account Postman runs as a "lightweight client" that cannot hold
  collections, and every import fails with "Could not import collection".

## Steps

### 1. Create the environment file

```bash
export AWS_PROFILE=newaccount AWS_REGION=eu-north-1   # if your key is under a named profile
scripts/postman-env.sh
```

**Why:** the collection does not contain the API address or the sign-in
details, because they change at every deploy: AWS gives the load balancer a
new name and Terraform generates a new password for the test user. The
script reads the address from the Terraform output `app_url` and the client
id, username and password from the Secrets Manager secret
`cloud-design/cognito-test-user`, and writes them to
`postman/cloud-design.postman_environment.json`. `scripts/deploy.sh` already
runs it at the end, so after a deploy the file is up to date. The file holds
the password, so git ignores it: it never reaches the repository.

### 2. Import the collection

**Import** (top left of the sidebar) → choose
`postman/cloud-design.postman_collection.json`, or open the file in an
editor, copy everything and paste it into the import box.

**Why:** this loads the 14 requests, their bodies, their headers and their
checks. It only needs to be done once: the collection does not change
between deploys.

### 3. Import the environment

**Import** again → choose `postman/cloud-design.postman_environment.json`.
It appears under **Environments** in the sidebar, named `cloud-design`.

**Why:** the requests use variables such as `{{base_url}}` and
`{{cognito_client_id}}`. The environment gives them their values for the
current deployment. Repeat this step after every deploy (or edit `base_url`
and `password` in the environment by hand).

### 4. Select the environment

Click **No Environment** at the top right and choose **cloud-design**.

**Why:** an imported environment is not active until selected. Without it
the variables are empty, which shows as red `{{region}}` in the URL and as
the error `Value '' at 'clientId'` from Cognito.

### 5. Sign in: run "1. Sign in → Get access token"

Expected: `200`, a JSON with `AccessToken`, Test Results 1/1.

**Why:** the API is protected by Amazon Cognito. The gateway accepts a
request only if its `Authorization: Bearer <token>` header carries a valid
Cognito access token; everything else gets `401`. This request sends the
test user's name and password to Cognito, gets a token valid 60 minutes,
and saves it in the `access_token` variable, which every other request puts
in its header automatically. Run it again when requests start returning
`401`: the token has expired.

### 6. Security checks: run folder "2. Security checks"

Expected: `/health` 200, movies without a token 401, movies with a fake
token 401.

**Why:** it shows the two sides of the authentication. The health endpoint
is public, so the load balancer can check that the gateway is alive; the
data endpoints reject a missing or invalid token. This is the audit question
"when accessing the API Gateway without valid authentication credentials, is
the request correctly rejected?".

### 7. Movies: run folder "3. Movies" in order

Expected: Create 201 → List 200 (the new movie is in the list) → Get by id
200 → Search 200 → Update 200 → Create without a title 400 → Delete 200 →
Get the deleted movie 404.

**Why:** this is the audit's "create a movie with POST, retrieve it with
GET" check, plus the rest of the CRUD. The requests must run in this order:
Create saves the new movie's id in the `movie_id` variable, and the get,
update and delete requests use it. The collection deletes only the movie it
created, so an existing database is left as it was.

### 8. Billing: run folder "4. Billing"

Expected: Send an order 200 `{"message": "Message posted"}`; missing fields
400.

**Why:** the gateway does not write the order itself: it publishes it on the
RabbitMQ queue and answers at once, and billing-app consumes the queue and
inserts the order. `200` therefore means "queued", not "stored". To see the
order stored, read billing-app's log:

```bash
aws logs tail /ecs/cloud-design --log-stream-name-prefix billing --since 5m
# [x] Received order message: {...}  then  [✓] Order successfully inserted into orders table.
```

### 9. Run everything at once (optional)

Right-click the collection → **Run collection** → **Run**. The runner
executes the 14 requests in order and shows every check as passed or failed.

**Why:** one click for the auditor, and a quick regression test after a
code change and `scripts/push-images.sh`.

### 10. Billing resilience with Postman (optional)

Stop billing-app with the commands of COMMANDS.md 2.7 step 1, send
**4. Billing → Send a billing order** from Postman (still `200`), then start
billing-app again (2.7 step 3) and watch the log (2.7 step 4): the queued
order is processed by the new task.

**Why:** this is the audit's resilience check: an order accepted while the
billing service is down is not lost, because it waits in the durable queue.

## Problems and their meaning

| What you see | Meaning | Fix |
|--------------|---------|-----|
| `Could not import collection` | Postman is not signed in (lightweight client) | Sign in, or use <https://go.postman.co> |
| `Value '' at 'clientId'`, red `{{region}}` in the URL | No environment selected | Step 4 |
| `401 Invalid or expired token` on every request | The token is older than 60 minutes, or the environment is from a previous deploy | Step 5, or steps 1 and 3 |
| `Could not send request` / certificate error | The load balancer's certificate is self-signed | Settings → General → turn off **SSL certificate verification** |
| Connection refused or timeout | The project is not deployed, or `base_url` is from a previous deploy | `scripts/deploy.sh`, then steps 1 and 3 |
| `404` on the get/update/delete movie requests | `movie_id` is empty: Create a movie did not run first | Run the Movies folder from the top |

## After testing

The project bills per hour while it runs. When done, `scripts/destroy.sh`
(COMMANDS.md, step 12).
