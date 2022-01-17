import "reflect-metadata";
import express, { Request, Response, NextFunction } from "express";
import "express-async-errors";
import { router } from "./routes";
import swaggerUI from "swagger-ui-express";
import swaggerFile from "../../../swagger.json";

import "@shared/infra/typeorm";
import "@shared/container";
import { AppError } from "@shared/errors/AppError";

const app = express();

app.use(express.json());

app.use("/docs", swaggerUI.serve, swaggerUI.setup(swaggerFile));

app.use(router);

app.use(
  (err: Error, request: Request, response: Response, next: NextFunction) => {
    if (err instanceof AppError) {
      return response.status(err.statusCode).json({ message: err.message });
    }
    return response.status(500).json({
      status: "error",
      message: `Internal server error - ${err.message}`,
    });
  }
);

app.listen(3333, () => console.log("server is running!"));
