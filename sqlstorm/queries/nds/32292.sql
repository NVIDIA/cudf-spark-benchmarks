
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales_price,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        cs_item_sk
), filtered_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales_price,
        s.order_count,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_sales_price DESC) AS rank
    FROM 
        sales_summary s
)
SELECT 
    a.ca_country,
    SUM(f.total_sales_price) AS total_sales,
    AVG(f.total_quantity) AS avg_quantity,
    MAX(f.order_count) AS max_orders,
    MIN(f.order_count) AS min_orders
FROM 
    filtered_sales f
JOIN 
    customer c ON c.c_customer_sk IN (SELECT wr_returning_customer_sk FROM web_returns WHERE wr_order_number IS NOT NULL)
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
GROUP BY 
    a.ca_country
HAVING 
    SUM(f.total_sales_price) > 0
ORDER BY 
    total_sales DESC;
