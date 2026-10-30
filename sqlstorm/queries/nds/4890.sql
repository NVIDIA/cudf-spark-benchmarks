
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
IncomeDistribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS income_count,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics h
    LEFT JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.order_count,
    id.income_count,
    id.total_sales,
    id.avg_purchase_estimate
FROM 
    CustomerStats cs
JOIN 
    IncomeDistribution id ON cs.c_customer_sk = id.hd_income_band_sk
WHERE 
    cs.rank_profit <= 10
ORDER BY 
    cs.d_year, cs.total_profit DESC;
