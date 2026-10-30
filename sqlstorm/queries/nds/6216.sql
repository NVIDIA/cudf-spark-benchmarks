
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY c.c_customer_sk, c.c_birth_year
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer_demographics cd
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_profit,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM CustomerSales cs
    JOIN Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    ss.cd_gender, 
    ss.cd_marital_status,
    COUNT(ss.c_customer_sk) AS customer_count,
    AVG(ss.total_quantity) AS avg_quantity,
    SUM(ss.total_profit) AS total_profit,
    CASE WHEN SUM(ss.total_profit) > 1000 THEN 'High Profit' ELSE 'Low Profit' END AS profit_category
FROM SalesSummary ss
GROUP BY ss.cd_gender, ss.cd_marital_status
ORDER BY total_profit DESC;
