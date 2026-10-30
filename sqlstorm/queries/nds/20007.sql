
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM 
        customer_sales cs
    WHERE 
        cs.rnk <= 10
),
sales_with_ship_mode AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(SUM(ws.ws_net_paid_inc_ship), 0) AS total_sales_with_ship,
        sm.sm_type 
    FROM 
        top_customers tc
    LEFT JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        tc.c_customer_sk, tc.c_first_name, tc.c_last_name, sm.sm_type
),
final_output AS (
    SELECT 
        sw.c_customer_sk AS customer_sk,
        sw.c_first_name AS first_name,
        sw.c_last_name AS last_name,
        sw.total_sales_with_ship,
        sw.sm_type,
        CASE 
            WHEN sw.total_sales_with_ship IS NULL THEN 'No Sales'
            WHEN sw.total_sales_with_ship = 0 THEN 'Zero Sales'
            ELSE 'Active Sales'
        END AS sales_status
    FROM 
        sales_with_ship_mode sw
)
SELECT 
    fo.customer_sk,
    fo.first_name,
    fo.last_name,
    fo.total_sales_with_ship,
    fo.sm_type,
    fo.sales_status,
    DENSE_RANK() OVER (ORDER BY fo.total_sales_with_ship DESC) AS sales_rank
FROM 
    final_output fo
WHERE 
    fo.total_sales_with_ship > 0
ORDER BY 
    fo.total_sales_with_ship DESC
LIMIT 5;
