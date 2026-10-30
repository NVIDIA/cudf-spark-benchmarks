
WITH  sales_cte AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
top_customers AS (
    SELECT 
        c_customer_id AS customer_id,
        total_sales,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales < 100 THEN 'Low Spender'
            WHEN total_sales BETWEEN 100 AND 1000 THEN 'Medium Spender'
            ELSE 'High Spender' 
        END AS spending_category
    FROM 
        sales_cte
    WHERE 
        rank <= 10
), 
ship_counts AS (
    SELECT 
        sm.sm_type,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count,
        SUM(ws.ws_sales_price) AS total_ship_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
), 
customer_ship_data AS (
    SELECT 
        tc.customer_id,
        tc.total_sales,
        tc.spending_category,
        s.sm_type,
        sc.item_count,
        COALESCE(sc.total_ship_cost, 0) AS total_ship_cost,
        CASE 
            WHEN COALESCE(sc.total_ship_cost, 0) = 0 THEN 'Free'
            WHEN COALESCE(sc.total_ship_cost, 0) < 50 THEN 'Low'
            ELSE 'Expensive' 
        END AS shipping_category
    FROM 
        top_customers tc
    LEFT JOIN 
        ship_counts sc ON tc.spending_category IN ('Low Spender', 'Medium Spender')
    LEFT JOIN 
        ship_mode s ON s.sm_ship_mode_sk = 1 
)
SELECT 
    cs.customer_id,
    cs.total_sales,
    cs.spending_category,
    cs.sm_type,
    cs.item_count,
    cs.total_ship_cost,
    cs.shipping_category
FROM 
    customer_ship_data cs
WHERE 
    (cs.total_sales > 500 AND cs.shipping_category = 'Expensive') OR 
    (cs.spending_category = 'No Sales' AND cs.item_count <> 0)
ORDER BY 
    cs.total_sales DESC
LIMIT 10 OFFSET 5;
