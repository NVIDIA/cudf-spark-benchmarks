
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_profit) AS avg_profit
    FROM customer_demographics cd
    JOIN CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY cd.cd_demo_sk
),
SalesByIncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(cs.total_profit) AS income_band_total_profit
    FROM income_band ib
    JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN CustomerSales cs ON hd.hd_demo_sk = cs.c_customer_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    cd.cd_gender,
    dba.customer_count,
    dba.avg_profit,
    ib.income_band_total_profit
FROM DemographicAnalysis dba
JOIN customer_demographics cd ON dba.customer_count = cd.cd_demo_sk
JOIN SalesByIncomeBand ib ON cd.cd_demo_sk = ib.ib_income_band_sk
WHERE dba.avg_profit > (SELECT AVG(avg_profit) FROM DemographicAnalysis)
ORDER BY dba.avg_profit DESC;
