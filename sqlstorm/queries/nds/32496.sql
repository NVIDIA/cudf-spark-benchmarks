WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2459631 AND 2459635 
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS top_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.item_rank = 1
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN s.top_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_classification
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    top_sales s ON c.c_customer_sk = s.ws_item_sk
WHERE 
    (c.c_birth_year BETWEEN 1970 AND 1990 OR c.c_first_name LIKE '%John%')
    AND ca.ca_state IN ('CA', 'NY')
ORDER BY 
    total_sales DESC
LIMIT 100;