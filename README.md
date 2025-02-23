# Online Services

This project is a database system designed to simulate an **online services marketplace** (similar to platforms like Acharah or Sanjagh). The system allows experts to offer services in specific categories, and customers can request services based on their needs. The database handles service categorization, expert certifications, service requests, pricing, and customer feedback.

---

## Project Overview

The marketplace consists of the following key components:

1. **Service Categories and Subcategories**: Services are organized into categories and subcategories. Experts can offer services within specific categories.
2. **Experts**: Each expert can provide multiple services within their category. They can also upload licenses (both mandatory and optional) for each service they offer.
3. **Service Requests**: Customers can request services by answering specific questions related to the service. Experts can filter requests based on customer responses, location, and other criteria.
4. **Pricing and Advertising**: Experts set a price range for their services, and the system uses this information to rank and display experts to customers.
5. **Feedback and Ratings**: After a service is completed, customers can rate the expert (on a scale of 1 to 5) and leave feedback.

---

## Database Schema

The database schema includes the following tables:

- **category**: Stores service categories.
- **subset_category**: Stores subcategories for each category.
- **service**: Lists all services offered, including their availability (at customer or expert location) and pricing range.
- **expert**: Contains information about experts, their location, and service radius.
- **license_type**: Stores types of licenses (e.g., certifications) and their worth.
- **license**: Tracks licenses held by experts, including status and expiration date.
- **providing_services**: Maps experts to the services they provide, including advertising cost and location availability.
- **question_forms**: Stores questions related to services (multiple-choice, textual, or numerical).
- **customers**: Tracks customer information, including name, email, and phone number.
- **orders**: Records customer requests for services.
- **answers**: Stores customer answers to service-related questions.
- **suggestions**: Tracks service suggestions made by experts for customer orders.
- **feedbacks**: Stores customer feedback and ratings for completed services.

---

## Features

- **Service Filtering**: Customers can filter services based on location, licenses, and other criteria.
- **Dynamic Pricing**: Experts can set advertising costs within a predefined range for their services.
- **Feedback System**: Customers can rate and provide feedback for experts after service completion.
- **License Management**: Experts can upload and manage licenses for their services.

---

## Queries

The project includes **8 complex SQL queries** to demonstrate the functionality of the database. These queries cover various scenarios related to services, experts, customers, and feedback.

---

## Indexing

Proper indexing has been applied to optimize query performance. The results of indexing, including performance improvements, are documented in the project.

---

## How to Use

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/AidaJalali/online-services-system.git
   ```

2. **Set Up the Database**:
   - Run the `online_services_system.sql` script to create the database and tables:
     ```bash
     psql -U your-username -d your-database -f online_services_system.sql
     ```

3. **Insert Random Data**:
   - Use the provided script to insert random data into the database for testing.

4. **Run Queries**:
   - Execute the 8 complex queries to explore the database functionality.

5. **Check Indexing Results**:
   - Review the indexing results and performance improvements in the project documentation.
