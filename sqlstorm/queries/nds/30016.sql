
WITH  sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws.ws_item_sk
),
top_items AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        ss.total_sales,
        ss.total_revenue,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High'
            WHEN ss.total_sales BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM sales_summary ss
    JOIN item si ON ss.ws_item_sk = si.i_item_sk
    WHERE ss.rank <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ta.i_item_id,
    ta.i_item_desc,
    ta.total_sales,
    ta.total_revenue,
    ta.sales_category,
    ca.ca_city,
    ca.ca_state,
    ca.customer_count
FROM top_items ta
JOIN customer_addresses ca ON ca.ca_city IS NOT NULL
WHERE ca.customer_count > 5
ORDER BY ta.total_revenue DESC, ca.ca_city ASC;
