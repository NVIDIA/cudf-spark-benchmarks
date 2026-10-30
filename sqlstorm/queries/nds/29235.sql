
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip
),
TopCustomerInfo AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM CustomerInfo
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_zip,
    total_orders
FROM TopCustomerInfo
WHERE order_rank <= 10
ORDER BY total_orders DESC;
