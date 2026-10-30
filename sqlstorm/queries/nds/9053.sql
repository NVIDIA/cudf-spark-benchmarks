
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
IncomeSegment AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        CASE 
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_band,
        cs.avg_net_profit,
        cs.order_count
    FROM 
        CustomerStats cs
    JOIN 
        household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
),
FinalReport AS (
    SELECT 
        income_band,
        COUNT(*) AS customer_count,
        AVG(avg_net_profit) AS avg_profit,
        SUM(order_count) AS total_orders
    FROM 
        IncomeSegment
    GROUP BY 
        income_band
)
SELECT 
    income_band,
    customer_count,
    avg_profit,
    total_orders,
    (SELECT SUM(customer_count) FROM FinalReport) AS total_customers
FROM 
    FinalReport
ORDER BY 
    income_band;
