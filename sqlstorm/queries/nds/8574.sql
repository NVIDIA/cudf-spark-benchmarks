
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
), SalesSummary AS (
    SELECT 
        cd_gender,
        hd_income_band_sk,
        COUNT(c_customer_sk) AS num_customers,
        AVG(total_orders) AS avg_orders_per_customer,
        AVG(total_spent) AS avg_spent_per_customer
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, hd_income_band_sk
)
SELECT 
    s.cd_gender,
    s.hd_income_band_sk,
    s.num_customers,
    s.avg_orders_per_customer,
    s.avg_spent_per_customer,
    d.d_year,
    d.d_month_seq
FROM 
    SalesSummary s
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_ship_customer_sk IN (SELECT c_customer_sk FROM customer))
ORDER BY 
    s.cd_gender, s.hd_income_band_sk;
