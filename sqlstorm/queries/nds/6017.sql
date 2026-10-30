
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT css.c_customer_sk) AS customer_count,
        SUM(css.total_profit) AS total_profit,
        AVG(css.order_count) AS avg_orders
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary css ON cd.cd_demo_sk = css.c_customer_sk
    GROUP BY 
        cd_gender
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT hdd.hd_demo_sk) AS household_count,
        AVG(hdd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        household_demographics hdd
    JOIN 
        income_band ib ON hdd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ds.cd_gender,
    ds.customer_count,
    ds.total_profit,
    ds.avg_orders,
    id.household_count,
    id.avg_vehicle_count
FROM 
    demographics_summary ds
JOIN 
    income_distribution id ON ds.customer_count > 100
ORDER BY 
    total_profit DESC;
