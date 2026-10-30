
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ws_bill_customer_sk
), 
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.total_quantity) AS total_items_purchased,
        MAX(ss.avg_net_profit) AS highest_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), 
top_customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_items_purchased DESC) AS purchase_rank
    FROM 
        customer_stats
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    COALESCE(tc.total_items_purchased, 0) AS total_items_purchased,
    COALESCE(tc.highest_net_profit, 0) AS highest_net_profit,
    CASE 
        WHEN tc.total_items_purchased IS NULL THEN 'No Purchases' 
        ELSE 'Active Customer' 
    END AS customer_status
FROM 
    top_customers tc
WHERE 
    purchase_rank <= 10
ORDER BY 
    tc.total_items_purchased DESC;
