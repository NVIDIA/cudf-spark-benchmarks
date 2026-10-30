WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_birth_year, cd.cd_gender
),
AgeGroups AS (
    SELECT 
        c_birth_year,
        cd_gender,
        CASE 
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year < 30 THEN 'Under 30'
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year BETWEEN 30 AND 60 THEN '30-60'
            ELSE '60 and above'
        END AS age_group,
        SUM(total_orders) AS total_orders,
        SUM(total_profit) AS total_profit,
        AVG(avg_order_value) AS avg_order_value
    FROM CustomerStats
    GROUP BY c_birth_year, cd_gender
),
HighValue AS (
    SELECT 
        age_group,
        cd_gender,
        total_orders,
        total_profit,
        avg_order_value
    FROM AgeGroups
    WHERE avg_order_value IS NOT NULL AND (total_profit > 1000 OR total_orders > 10)
)
SELECT 
    age_group,
    cd_gender,
    total_orders,
    total_profit,
    avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY age_group ORDER BY total_profit DESC) AS rank
FROM HighValue
ORDER BY age_group, rank;