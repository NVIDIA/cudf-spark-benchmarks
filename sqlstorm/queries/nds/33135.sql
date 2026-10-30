
WITH  sales_totals AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_mode_sk
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
        AVG(ws.ws_net_profit) AS avg_order_value,
        COUNT(DISTINCT CASE WHEN ws.ws_net_profit IS NOT NULL THEN ws.ws_order_number END) AS non_null_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.number_of_orders,
        cs.avg_order_value,
        COALESCE(st.total_profit, 0) AS total_profit
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_totals st ON cs.c_customer_sk = st.ws_ship_mode_sk
), ranked_customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        sales_summary
)
SELECT 
    r.c_customer_sk,
    r.total_spent,
    r.number_of_orders,
    r.avg_order_value,
    r.total_profit,
    CASE 
        WHEN r.total_profit IS NULL THEN 'No Profit'
        WHEN r.total_profit > 1000 THEN 'High Profit'
        ELSE 'Moderate Profit'
    END AS profit_category,
    (SELECT COUNT(*) FROM ranked_customers WHERE spend_rank < r.spend_rank) AS customers_above
FROM 
    ranked_customers r
WHERE 
    r.spend_rank <= 10
ORDER BY 
    r.total_spent DESC;
