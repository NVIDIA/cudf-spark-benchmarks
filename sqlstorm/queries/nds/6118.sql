
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_store_sales_price,
        MAX(ss.ss_quantity) AS max_sales_quantity
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
),
date_summary AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.income_band,
    ss.total_store_sales,
    ss.avg_store_sales_price,
    ds.total_orders,
    ds.total_revenue
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_id = ss.s_store_id
LEFT JOIN 
    date_summary ds ON ds.total_orders > 0
ORDER BY 
    cs.total_web_spent DESC
LIMIT 100;
