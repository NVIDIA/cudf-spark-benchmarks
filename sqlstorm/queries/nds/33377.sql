
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        t.ws_item_sk,
        t.total_sales,
        s.i_item_desc,
        s.i_brand,
        COALESCE(s.i_current_price, 0) AS current_price,
        CASE 
            WHEN s.i_current_price > 0 THEN 
                (t.total_sales / s.i_current_price) 
            ELSE 
                NULL 
        END AS quantity_sold
    FROM 
        sales_summary t
    JOIN 
        item s ON t.ws_item_sk = s.i_item_sk
    WHERE 
        t.rn <= 10
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.order_count,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rnk
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.order_count > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.order_count,
    tc.total_profit,
    ts.total_sales,
    ts.i_item_desc,
    ts.i_brand,
    ts.quantity_sold
FROM 
    top_customers tc
LEFT JOIN 
    top_sales ts ON tc.order_count > 0
WHERE 
    tc.rnk <= 5
ORDER BY 
    tc.total_profit DESC, 
    tc.order_count DESC;
