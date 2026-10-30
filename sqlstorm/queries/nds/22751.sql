
WITH customer_sales_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_by_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        css.total_orders,
        css.total_sales,
        css.total_net_paid,
        css.avg_net_profit
    FROM 
        customer_sales_summary css
    JOIN 
        customer c ON css.c_customer_sk = c.c_customer_sk
    WHERE 
        css.rank_by_sales <= 10
),
customer_address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
),
combined_info AS (
    SELECT 
        tc.c_customer_id,
        tc.total_orders,
        tc.total_sales,
        tc.total_net_paid,
        tc.avg_net_profit,
        cai.ca_city,
        cai.ca_state
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_address_info cai ON tc.total_orders > 5 AND cai.city_rank = 1
)

SELECT 
    cii.c_customer_id,
    cii.total_orders,
    COALESCE(cii.total_sales, 0) AS total_sales,
    COALESCE(cii.total_net_paid, 0) AS total_net_paid,
    CASE 
        WHEN cii.avg_net_profit IS NULL THEN 'No Profit Data'
        ELSE CAST(cii.avg_net_profit AS STRING)
    END AS avg_net_profit,
    CASE 
        WHEN cii.ca_city IS NULL THEN 'No Address'
        ELSE cii.ca_city
    END AS primary_city,
    CASE 
        WHEN cii.ca_state IS NULL THEN 'No Address'
        ELSE cii.ca_state
    END AS primary_state
FROM 
    combined_info cii
ORDER BY 
    cii.total_sales DESC NULLS LAST
LIMIT 25;
