
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
date_summary AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ds.c_customer_sk) AS active_customers,
        SUM(ds.total_net_profit) AS annual_net_profit
    FROM 
        date_dim d
    JOIN 
        sales_summary ds ON d.d_date_sk = (SELECT MAX(d2.d_date_sk) FROM date_dim d2 WHERE d2.d_date = DATE '2002-10-01')
    GROUP BY 
        d.d_year
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ib.ib_income_band_sk
)
SELECT 
    cd.cd_gender AS customer_gender,
    cd.cd_marital_status AS marital_status,
    cd.cd_education_status AS education,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(ds.active_customers) AS total_active_customers,
    SUM(ds.annual_net_profit) AS total_net_profit
FROM 
    customer_demographics cd 
JOIN 
    date_summary ds ON cd.customer_count > 0
JOIN 
    income_band ib ON ib.ib_income_band_sk = cd.ib_income_band_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    total_net_profit DESC;
