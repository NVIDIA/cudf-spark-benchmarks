
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        d.d_month_seq AS purchase_month,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, full_name, first_purchase_date, purchase_month, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
)
SELECT 
    full_name,
    purchase_month,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer_data
ORDER BY 
    total_spent DESC
LIMIT 100;
