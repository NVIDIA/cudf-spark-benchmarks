
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
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
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential
),
sales_summary AS (
    SELECT 
        d.d_year, 
        COUNT(DISTINCT ws.ws_order_number) AS num_orders, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.hd_income_band_sk,
    cs.hd_buy_potential,
    ss.d_year,
    ss.num_orders,
    ss.total_sales,
    cs.total_orders,
    cs.total_sales,
    cs.total_profit
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.total_orders > 0
ORDER BY 
    cs.total_sales DESC, ss.total_sales DESC
LIMIT 50;
