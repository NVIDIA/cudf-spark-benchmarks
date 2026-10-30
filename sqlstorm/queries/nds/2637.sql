
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) as income_band,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
order_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(*) AS order_count,
        SUM(ws.ws_net_paid) AS total_net_paid,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_bill_customer_sk
),
profit_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.order_count,
        cs.total_net_paid,
        cs.max_sales_price,
        cs.min_sales_price,
        (CASE 
            WHEN cs.order_count IS NULL THEN 0 
            ELSE ROUND(cs.total_net_paid / cs.order_count, 2) 
         END) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        order_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    COALESCE(ord.order_count, 0) AS total_order_count,
    COALESCE(ord.total_net_paid, 0) AS total_net_paid,
    ord.max_sales_price,
    ord.min_sales_price,
    ord.avg_order_value,
    RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
FROM 
    customer_summary cs
LEFT JOIN 
    profit_analysis ord ON cs.c_customer_sk = ord.c_customer_sk
WHERE 
    cs.total_profit > (SELECT AVG(total_profit) FROM customer_summary)
ORDER BY 
    profit_rank, cs.total_orders DESC;
