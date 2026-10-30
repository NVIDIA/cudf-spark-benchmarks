WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        DATE_PART('year', cast('2002-10-01' as date)) - c.c_birth_year AS age
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, c.c_birth_year
),
AgeSegment AS (
    SELECT 
        CASE 
            WHEN age < 18 THEN 'Under 18'
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            WHEN age BETWEEN 56 AND 65 THEN '56-65'
            ELSE '65+'
        END AS age_segment,
        COUNT(c_customer_id) AS customer_count,
        SUM(total_net_profit) AS total_profit,
        AVG(avg_order_value) AS avg_order_value
    FROM 
        CustomerSales
    GROUP BY 
        age_segment
)
SELECT 
    age_segment,
    customer_count,
    total_profit,
    avg_order_value
FROM 
    AgeSegment
ORDER BY 
    age_segment;