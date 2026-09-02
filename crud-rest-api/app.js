const express = require("express");
const bodyparser = require("body-parser");

const app = express();

app.use(bodyparser.json());

app.use(bodyparser.urlencoded({ extended: false }));

app.use((req, res, next) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
    next();
});

// test route
app.get("/", (req, res) => {
    res.send("Hello World");
});

app.get("/health", (req, res) => {
    res.status(200).json({ status: "ok" });
});

// CRUD routes
app.use("/users", require("./routes/users"));

// error handling
app.use((error, req, res, next) => {
    console.log(error);

    const status = error.statusCode || 500;
    const message = error.message;

    res.status(status).json({ message: message });
});

module.exports = app;