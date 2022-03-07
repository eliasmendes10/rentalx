import { v4 as uuidV4 } from "uuid";

class Rental {
  id: string;

  car_id: string;

  user_id: string;

  start_date: string;

  end_date: string;

  expected_return_date: string;

  token: number;

  created_at: Date;

  updated_at: Date;

  constructor() {
    if (!this.id) {
      this.id = uuidV4();
    }
  }
}

export { Rental };
