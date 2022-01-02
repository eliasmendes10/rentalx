import { Specification } from "../../entities/Specification";
import {
  ISpecificationsRepository,
  ICreateSpecificationDTO,
} from "../ISpecificationsRepository";

//DTO => Data Transfer Object

class SpecificationsRepository implements ISpecificationsRepository {
  private specifications: Specification[];

  //#####Singleton Pattern (Para evitar multiplas instancias de objeto)
  private static INSTANCE: SpecificationsRepository;

  private constructor() {
    this.specifications = [];
  }

  public static getInstance(): SpecificationsRepository {
    if (!SpecificationsRepository.INSTANCE) {
      SpecificationsRepository.INSTANCE = new SpecificationsRepository();
    }
    return SpecificationsRepository.INSTANCE;
  }
  //#####Singleton Pattern
  create({ name, description }: ICreateSpecificationDTO): void {
    const category = new Specification();

    Object.assign(category, { name, description, created_at: new Date() });

    this.specifications.push(category);
  }

  list(): Specification[] {
    return this.specifications;
  }

  findByName(name: string): Specification {
    const specification = this.specifications.find(
      (specification) => specification.name === name
    );

    return specification;
  }
}

export { SpecificationsRepository };
