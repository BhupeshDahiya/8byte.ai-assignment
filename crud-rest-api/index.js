const sequelize = require("./util/database");
const app = require("./app");

sequelize
    .sync()
    .then(() => {
        console.log("Database connected");
        app.listen(3000, () => {
            console.log("Server running on port 3000");
        });
    })
    .catch((err) => console.log(err));