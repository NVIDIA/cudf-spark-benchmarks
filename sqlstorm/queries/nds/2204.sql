
WITH ranked_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 4000
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_amount_spent
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.order_count,
        cs.total_amount_spent,
        RANK() OVER (ORDER BY cs.total_amount_spent DESC) AS rank
    FROM
        customer_stats cs
    WHERE
        cs.total_amount_spent IS NOT NULL
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    COALESCE(tc.total_amount_spent, 0) AS total_amount_spent,
    MAX(rs.ws_sales_price) AS max_sales_price
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    top_customers tc ON c.c_customer_sk = tc.c_customer_sk
LEFT JOIN 
    ranked_sales rs ON rs.ws_item_sk IN (
        SELECT 
            i_item_sk
        FROM 
            item
        WHERE
            i_current_price > 50
    ) AND rs.rn = 1
WHERE 
    COALESCE(tc.rank, 0) <= 10 
GROUP BY 
    ca.ca_address_sk, ca.ca_city, ca.ca_state, tc.total_amount_spent
ORDER BY 
    total_amount_spent DESC
LIMIT 50;
