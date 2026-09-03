const morgan = require("morgan");
const client = require("@prometheus-io/client");

const register = new client.Registry();

client.collectDefaultMetrics({
    register
});

const httpRequestsTotal = new client.Counter({
    name: "http_requests_total",
    help: "Total HTTP requests",
    labelNames: ["method", "route", "status_code"],
    registers: [register]
});

const httpRequestDuration = new client.Histogram({
    name: "http_request_duration_seconds",
    help: "HTTP request duration in seconds",
    labelNames: ["method", "route", "status_code"],
    buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5],
    registers: [register]
});
const express = require("express");
const bodyparser = require("body-parser");

const app = express();
app.use(morgan("combined"));

app.use((req, res, next) => {
    const start = process.hrtime.bigint();

    res.on("finish", () => {
        const duration = Number(process.hrtime.bigint() - start) / 1e9;
        const route = req.route?.path || req.path;
        const status = String(res.statusCode);

        httpRequestsTotal.inc({
            method: req.method,
            route,
            status_code: status
        });

        httpRequestDuration.observe(
            {
                method: req.method,
                route,
                status_code: status
            },
            duration
        );
    });

    next();
});

app.get("/metrics", async (req, res) => {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
});

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