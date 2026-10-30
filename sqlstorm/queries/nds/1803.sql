
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CD.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_purchases,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),
ranked_customers AS (
    SELECT 
        cs.*,
        ss.total_spent,
        ss.unique_orders,
        ss.max_price,
        ss.min_price,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_purchases DESC) AS gender_rank,
        RANK() OVER (ORDER BY cs.total_purchases DESC) AS overall_rank
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.total_purchases,
    rc.avg_net_profit,
    rc.total_spent,
    rc.unique_orders,
    rc.max_price,
    rc.min_price,
    rc.gender_rank,
    rc.overall_rank
FROM 
    ranked_customers rc
WHERE 
    (rc.gender_rank <= 10 OR rc.overall_rank <= 20)
    AND COALESCE(rc.total_spent, 0) > 1000
ORDER BY 
    rc.gender_rank, rc.total_purchases DESC;
