
WITH  sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(cs_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ss.total_net_profit) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.total_net_profit) DESC) AS customer_rank
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_summary ss ON ws.ws_item_sk = ss.cs_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(ss.total_net_profit) > 1000
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_item_sk IN (SELECT ss.cs_item_sk FROM sales_summary ss WHERE ss.rank_profit <= 5)) AS popular_items_count
FROM 
    top_customers tc
WHERE 
    tc.total_spent IS NOT NULL
ORDER BY 
    tc.total_spent DESC
LIMIT 20;
