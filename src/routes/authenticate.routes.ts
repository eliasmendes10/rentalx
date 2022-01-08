import { Router } from "express";
import { AuthenticateUserController } from "../modules/accounts/useCases/authenticateUser/AuthenticateUserController";

const authenticateRoutes = Router();

const authenticate = new AuthenticateUserController();

authenticateRoutes.post("/sessions", authenticate.handle);

export { authenticateRoutes };
