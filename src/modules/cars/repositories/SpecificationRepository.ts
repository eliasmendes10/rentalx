import { Specification } from "../model/Specification";
import {
  ISpecificationsRepository,
  ICreateSpecificationDTO,
} from "./ISpecificationRepository";

//DTO => Data Transfer Object

class SpecificationRepository implements ISpecificationsRepository {
  private categories: Specification[];

  constructor() {
    this.categories = [];
  }

  create({ name, description }: ICreateSpecificationDTO): void {
    const category = new Specification();

    Object.assign(category, { name, description, created_at: new Date() });

    this.categories.push(category);
  }

  list(): Specification[] {
    return this.categories;
  }

  findByName(name: string): Specification {
    const category = this.categories.find((Category) => Category.name === name);

    return category;
  }
}

export { SpecificationRepository };
