
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20000101 AND 20201231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeLevels AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_paid) AS income
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
CustomerIncome AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        il.ib_lower_bound,
        il.ib_upper_bound,
        il.income
    FROM CustomerSales cs
    JOIN IncomeLevels il ON cs.c_customer_sk = il.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    ci.income,
    CASE 
        WHEN ci.income < 50000 THEN 'Low Income'
        WHEN ci.income >= 50000 AND ci.income < 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_bracket
FROM CustomerIncome ci
WHERE ci.income IS NOT NULL
ORDER BY ci.income DESC
LIMIT 10;
