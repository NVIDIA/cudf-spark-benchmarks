
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (5, 6)
        )
),
filtered_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_ext_sales_price) AS total_sales
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        cs.ws_item_sk,
        cs.total_quantity,
        cs.total_sales
    FROM 
        filtered_sales cs
    JOIN web_sales ws ON cs.ws_item_sk = ws.ws_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count
    FROM 
        customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    SUM(cs.total_quantity) AS total_quantity,
    SUM(cs.total_sales) AS total_sales,
    ai.customer_count
FROM 
    address_info ai
LEFT JOIN customer_sales cs ON cs.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk IS NOT NULL
)
GROUP BY 
    ai.ca_city, ai.ca_state, ai.customer_count
HAVING 
    SUM(cs.total_sales) > 100000
ORDER BY 
    total_sales DESC;
