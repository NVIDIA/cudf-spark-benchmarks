
WITH aggregated_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
high_sales_items AS (
    SELECT 
        a.ws_item_sk,
        a.total_quantity,
        a.total_sales,
        a.avg_net_profit,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        aggregated_sales a
    JOIN 
        item i ON a.ws_item_sk = i.i_item_sk
    WHERE 
        a.total_sales > 100000
),
top_customers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 5000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hsi.i_item_desc,
    hsi.total_quantity,
    hsi.total_sales,
    hsi.avg_net_profit,
    tc.total_spent
FROM 
    top_customers tc
JOIN 
    customer c ON tc.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    high_sales_items hsi ON c.c_current_addr_sk = hsi.ws_item_sk
ORDER BY 
    tc.total_spent DESC, hsi.total_sales DESC
LIMIT 10;
