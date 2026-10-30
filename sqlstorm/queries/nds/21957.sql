
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > (
            SELECT AVG(ws_sales_price) 
            FROM web_sales 
            WHERE ws_item_sk IS NOT NULL
        )
    OR
        ws_net_paid < (
            SELECT MAX(ws_net_paid) 
            FROM web_sales 
            WHERE ws_item_sk IS NOT NULL
        )
), 
recent_sales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        DENSE_RANK() OVER (ORDER BY rs.ws_sold_date_sk DESC) as sales_rank
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn = 1
)
SELECT 
    COALESCE(CONCAT(c.c_first_name, ' ', c.c_last_name), 'Unknown Customer') AS customer_name,
    cd.cd_gender,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales_value,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
FROM 
    web_sales ws 
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    recent_sales rs ON ws.ws_item_sk = rs.ws_item_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city, rs.sales_rank
HAVING 
    SUM(ws.ws_sales_price) > (
        SELECT AVG(ws_sales_price) 
        FROM web_sales 
        WHERE ws_ship_date_sk IS NOT NULL
    )
    AND sales_rank <= 10
ORDER BY 
    total_sales_value DESC;
