
WITH CustomerInfo AS (
    SELECT c.c_customer_id, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
           ca.ca_city, 
           ca.ca_state, 
           ca.ca_zip, 
           ca.ca_country,
           d.d_date AS last_purchase_date,
           COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id, 
             c.c_first_name, 
             c.c_last_name, 
             cd.cd_gender, 
             cd.cd_marital_status, 
             cd.cd_education_status,
             ca.ca_street_number, 
             ca.ca_street_name, 
             ca.ca_street_type, 
             ca.ca_city, 
             ca.ca_state, 
             ca.ca_zip, 
             ca.ca_country, 
             d.d_date
),
MostActiveCustomers AS (
    SELECT full_name, 
           total_orders 
    FROM CustomerInfo 
    WHERE total_orders > 5
    ORDER BY total_orders DESC
)
SELECT full_name, 
       total_orders, 
       CASE 
           WHEN total_orders > 10 THEN 'Very Active'
           WHEN total_orders > 5 THEN 'Active'
           ELSE 'Less Active' 
       END AS customer_activity_level
FROM MostActiveCustomers
LIMIT 10;
