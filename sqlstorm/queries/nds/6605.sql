
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price > 50
), 
max_sales AS (
    SELECT 
        cs.cs_item_sk AS item_sk, 
        MAX(cs.cs_sales_price) AS max_price 
    FROM 
        ranked_sales cs
    WHERE 
        sales_rank <= 5
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ms.max_price,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    item i
JOIN 
    max_sales ms ON i.i_item_sk = ms.item_sk
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    i.i_item_id, i.i_item_desc, ms.max_price
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    ms.max_price DESC
LIMIT 
    10;
