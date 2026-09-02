const sequelize = require("../../util/database");
const request = require("supertest");
const app = require("../../app");

beforeAll(async () => {
    await sequelize.sync();
});

afterAll(async () => {
    await sequelize.close();
});

describe("Users API", () => {
    test("POST /users creates a user", async () => {
        const response = await request(app)
            .post("/users")
            .send({
                name: "Test User",
                email: "test@example.com"
            });

        expect(response.statusCode).toBe(201);
        expect(response.body.user.name).toBe("Test User");
        expect(response.body.user.email).toBe("test@example.com");
    });
});