
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
sales_summary AS (
    SELECT 
        date_dim.d_year,
        SUM(ws.ws_net_paid) AS yearly_sales,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        date_dim.d_year
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        customer_stats cs
),
high_value_customers AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent
    FROM 
        top_customers tc
    WHERE 
        tc.spend_rank <= 10
),
combined_sales AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_spent,
        ss.yearly_sales,
        ss.average_order_value
    FROM 
        high_value_customers hvc
    JOIN 
        sales_summary ss ON hvc.total_spent > ss.yearly_sales / 10
)

SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.item_count, 0) AS item_count,
    gc.gender_counts
FROM 
    customer_stats cs
LEFT JOIN (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_counts
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
) AS gc ON gc.cd_gender = cs.cd_gender
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
