
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year AS age
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
MergedDetails AS (
    SELECT 
        cd.*, 
        sd.total_sales, 
        sd.total_orders
    FROM CustomerDetails cd
    LEFT JOIN SalesDetails sd ON cd.c_customer_id = CAST(sd.ws_bill_customer_sk AS CHAR(16))
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    ca_city, 
    ca_state, 
    age, 
    COALESCE(total_sales, 0) AS total_sales, 
    COALESCE(total_orders, 0) AS total_orders
FROM MergedDetails
WHERE age > 18
ORDER BY total_sales DESC, full_name ASC
LIMIT 100;
