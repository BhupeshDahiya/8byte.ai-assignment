const { getUser } = require("../../controllers/users");
const User = require("../../models/user");

jest.mock("../../models/user");

describe("getUser", () => {
    test("returns 404 when user does not exist", async () => {

        User.findByPk.mockResolvedValue(null);

        const req = {
            params: {
                userId: 999
            }
        };

        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        await getUser(req, res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith({
            message: "User not found!"
        });
    });
});