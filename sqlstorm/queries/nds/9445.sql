
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(total_quantity_sold) AS total_quantity_sold,
        SUM(total_net_profit) AS total_net_profit
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status, ib_income_band_sk
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.num_customers,
    ss.total_quantity_sold,
    ss.total_net_profit,
    CAST(ss.total_net_profit / NULLIF(ss.total_quantity_sold, 0) AS DECIMAL(10,2)) AS avg_net_profit_per_item
FROM 
    SalesSummary ss
LEFT JOIN 
    income_band ib ON ss.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ss.cd_gender, ss.cd_marital_status, ib.ib_income_band_sk;
