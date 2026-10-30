
WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451910 AND 2451975
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_sales, 
        ss.total_quantity,
        i.i_item_desc,
        i.i_brand,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS top_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rn = 1
)
SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(s.ws_net_profit), 0) AS total_net_profit,
    COALESCE(AVG(d.d_discount), 0) AS average_discount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM 
    warehouse w
LEFT JOIN 
    web_sales s ON w.w_warehouse_sk = s.ws_warehouse_sk AND s.ws_sold_date_sk BETWEEN 2451910 AND 2451975
LEFT JOIN 
    customer c ON s.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    (SELECT 
         ws_item_sk, 
         (ws_sales_price - ws_list_price) / NULLIF(ws_list_price, 0) AS d_discount
     FROM 
         web_sales) d ON s.ws_item_sk = d.ws_item_sk
WHERE 
    w.w_state = 'CA' 
GROUP BY 
    w.w_warehouse_name
HAVING 
    COALESCE(SUM(s.ws_net_profit), 0) > 100000 
    AND COUNT(DISTINCT c.c_customer_id) > 50 
    AND EXISTS (
        SELECT 1 
        FROM top_sales ts 
        WHERE ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN 2451910 AND 2451975) 
        AND ts.total_sales > 5000
    )
ORDER BY 
    total_net_profit DESC
LIMIT 10;
