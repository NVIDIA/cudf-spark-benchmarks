
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        (SELECT COUNT(DISTINCT sr_ticket_number) FROM store_returns WHERE sr_customer_sk = c.c_customer_sk) AS total_returns,
        (SELECT COUNT(DISTINCT wr_order_number) FROM web_returns WHERE wr_returning_customer_sk = c.c_customer_sk) AS total_web_returns,
        ca.ca_city, 
        ca.ca_state,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
),
web_sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        cd.*, 
        wd.total_spent, 
        wd.total_orders
    FROM 
        customer_data cd
    LEFT JOIN 
        web_sales_data wd ON cd.c_customer_sk = wd.ws_bill_customer_sk
)
SELECT 
    full_name, 
    cd_gender, 
    gender_label, 
    ca_city, 
    ca_state, 
    total_returns, 
    total_web_returns, 
    COALESCE(total_spent, 0) AS total_spent, 
    COALESCE(total_orders, 0) AS total_orders
FROM 
    combined_data
ORDER BY 
    total_spent DESC, 
    total_orders DESC
LIMIT 100;
