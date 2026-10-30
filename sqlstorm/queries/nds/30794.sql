
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_marital_status, cd.cd_gender, cd.cd_credit_rating
),
SalesStats AS (
    SELECT 
        cd_gender AS gender,
        AVG(total_net_profit) AS avg_profit,
        SUM(total_net_profit) AS total_profit,
        COUNT(*) AS customer_count
    FROM 
        SalesHierarchy
    GROUP BY 
        cd_gender
),
CurrencyConversions AS (
    SELECT 
        'USD' AS currency,
        CAST(1.0 AS FLOAT) AS exchange_rate
    UNION ALL
    SELECT 
        'EUR', CAST(0.85 AS FLOAT)
    UNION ALL
    SELECT 
        'GBP', CAST(0.75 AS FLOAT)
),
FinalProfit AS (
    SELECT 
        ss.gender,
        ss.avg_profit * cc.exchange_rate AS avg_profit_converted,
        ss.total_profit * cc.exchange_rate AS total_profit_converted,
        ss.customer_count
    FROM 
        SalesStats ss
    CROSS JOIN 
        CurrencyConversions cc
    WHERE 
        cc.currency = 'EUR' 
)

SELECT 
    gender,
    COALESCE(ROUND(avg_profit_converted, 2), 0) AS avg_profit_eur,
    COALESCE(ROUND(total_profit_converted, 2), 0) AS total_profit_eur,
    customer_count
FROM 
    FinalProfit
ORDER BY 
    avg_profit_converted DESC;
