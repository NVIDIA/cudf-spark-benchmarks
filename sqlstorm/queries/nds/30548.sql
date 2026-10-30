
WITH  sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ws.ws_bill_customer_sk,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_sales_price,
        cs.cs_bill_customer_sk,
        ROW_NUMBER() OVER(PARTITION BY cs.cs_order_number ORDER BY cs.cs_quantity DESC)
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
ranked_sales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.ws_sales_price,
        sd.ws_bill_customer_sk,
        RANK() OVER (PARTITION BY sd.ws_bill_customer_sk ORDER BY sd.ws_ext_sales_price DESC) as sales_rank
    FROM 
        sales_data sd
    WHERE 
        sd.rn = 1
)
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN sales_rank <= 5 THEN ws_ext_sales_price END) as top_5_sales,
    AVG(ws_sales_price) AS avg_sales_price,
    MAX(ws_ext_sales_price) AS max_sales_price
FROM 
    ranked_sales
WHERE 
    ws_bill_customer_sk IS NOT NULL
GROUP BY 
    ws_bill_customer_sk 
HAVING 
    COUNT(*) > 3
ORDER BY 
    total_orders DESC
LIMIT 10;
