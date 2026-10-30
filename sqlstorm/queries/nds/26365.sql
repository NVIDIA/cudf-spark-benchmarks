
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) END) AS full_address,
        d.d_date AS purchase_date,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY 
        c.c_customer_id,
        full_name,
        full_address,
        purchase_date
),
ranked_data AS (
    SELECT 
        full_name,
        full_address,
        purchase_date,
        total_orders,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM processed_data
)
SELECT 
    full_name,
    full_address,
    purchase_date,
    total_orders,
    total_spent,
    spending_rank
FROM ranked_data
WHERE spending_rank <= 10
ORDER BY total_spent DESC;
