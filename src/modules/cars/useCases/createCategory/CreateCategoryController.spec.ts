import { app } from "@shared/infra/http/app";
import request from "supertest";
import { hash } from "bcrypt";
import { v4 as uuidV4 } from "uuid";

import createConnection from "@shared/infra/typeorm";
import { Connection } from "typeorm";

let connection: Connection;

describe("Create Category Controller", async () => {
  beforeAll(async () => {
    connection = await createConnection();
    await connection.runMigrations();

    const id = uuidV4();
    const password = await hash("admin", 8);

    await connection.query(`INSERT INTO USERS(id, name, email, password, "isAdmin", created_at, driver_license)
      VALUES('${id}', 'admin', 'admin@rentx.com.br', '${password}', true, 'now()', 'XXXXXXXX')
      `);
  });

  afterAll(() => {});

  it("Should be able to create a new category", async () => {
    const responseToken = await request(app)
      .post("/sessions")
      .send({ email: "admin@rentx.com.br", password: "admin" });

    console.log(responseToken.body);
    const response = await request(app).post("/categories").send({
      name: "Category SuperTest",
      description: "Category Supertest",
    });

    expect(response.status).toBe(201);
  });
});
