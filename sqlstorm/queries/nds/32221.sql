
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
latest_sales AS (
    SELECT 
        s.ws_item_sk,
        MAX(s.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales s
    GROUP BY 
        s.ws_item_sk
    HAVING 
        MAX(s.ws_sold_date_sk) > (
            SELECT 
                MAX(d.d_date_sk) 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023 AND d.d_month_seq = 12
        )
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_purchases,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales_value,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit_per_order
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    sales_summary ss ON ss.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    latest_sales ls ON ls.ws_item_sk = ws.ws_item_sk
WHERE 
    ss.sales_rank <= 5 
    AND (ws.ws_ship_date_sk IS NOT NULL OR ws.ws_bill_addr_sk IS NOT NULL)
    AND EXISTS (
        SELECT 1 
        FROM store s
        WHERE s.s_store_sk = ws.ws_warehouse_sk
        AND s.s_closed_date_sk IS NULL
    )
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
ORDER BY 
    total_sales_value DESC
LIMIT 10;
