
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
        COALESCE(ws.ws_net_profit, 0) AS net_profit_adjusted
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.average_sales_price,
        RANK() OVER (ORDER BY cs.average_sales_price DESC) AS customer_rank
    FROM 
        customer_summary cs 
    WHERE 
        cs.order_count > 2 
        AND cs.average_sales_price IS NOT NULL
),
top_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(CASE 
            WHEN c.c_birth_year IS NULL THEN 0
            ELSE EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year
        END) AS average_age,
    SUM(COALESCE(rs.ws_sales_price, 0)) AS total_sales,
    SUM(COALESCE(tr.total_returned, 0)) AS total_returns
FROM 
    customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN ranked_sales rs ON c.c_customer_sk = rs.ws_item_sk
    LEFT JOIN high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
    LEFT JOIN top_returns tr ON rs.ws_item_sk = tr.cr_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND hvc.customer_rank IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
