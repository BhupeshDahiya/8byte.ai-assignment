## General info

A CRUD REST API is an API that allows you to perform CRUD operations (Create, Read, Update, Delete) on a data resource using HTTP methods. It provides a simple and scalable way to manage data resources over the web, making it a popular choice for building web applications and mobile apps.

## Built With
What I used to build this:

* Node.js - JavaScript runtime environment.
* Express - Popular Node.js web application framework.
* Postgresql - Powerful open-source relational database system.
* Sequelize - Promise-based Node.js ORM for Postgresql, MySQL, and SQLite.
* Docker - Platform for building, shipping, and running applications in containers.
* Postman - Powerful API testing and development tool.

## To check postgre
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Bhupesh\",\"email\":\"bhupesh@example.com\"}"
```
 
```bash
curl -X PUT http://localhost:3000/users/1 \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Bhupesh Dahiya\",\"email\":\"bhupesh.dahiya@example.com\"}"
``` 

```bash
curl -X DELETE http://localhost:3000/users/1
```

```bash
curl http://localhost:3000/users
```
