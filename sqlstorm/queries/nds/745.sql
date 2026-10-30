WITH customer_ranks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
recent_web_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS num_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date > cast('2002-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        rw.total_net_profit,
        rw.num_orders
    FROM 
        customer_ranks cr
    LEFT JOIN 
        recent_web_sales rw ON cr.c_customer_sk = rw.ws_bill_customer_sk
    WHERE 
        cr.rnk <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_net_profit, 0) AS total_net_profit,
    COALESCE(tc.num_orders, 0) AS num_orders,
    pb.ib_lower_bound,
    pb.ib_upper_bound
FROM 
    top_customers tc
LEFT JOIN 
    household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band pb ON hd.hd_income_band_sk = pb.ib_income_band_sk
WHERE 
    (tc.total_net_profit IS NOT NULL OR tc.num_orders > 0)
ORDER BY 
    total_net_profit DESC, 
    num_orders DESC;