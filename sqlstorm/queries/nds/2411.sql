
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
income_analysis AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(total_spent) AS total_income,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_info c
    JOIN 
        household_demographics hd ON c.hd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
top_sales_dates AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ss.total_revenue DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    d.d_date, 
    ci.cd_gender,
    ia.total_income,
    ia.customer_count,
    ts.total_revenue
FROM 
    date_dim d
LEFT JOIN 
    top_sales_dates ts ON d.d_date_sk = ts.ws_sold_date_sk
LEFT JOIN 
    customer_info ci ON ci.num_orders > 100
LEFT JOIN 
    income_analysis ia ON ia.ib_income_band_sk = ci.hd_income_band_sk
WHERE 
    ts.sales_rank <= 10 
    AND d.d_year = 2023
ORDER BY 
    ts.total_revenue DESC, 
    d.d_date;
