
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
Sales_Averages AS (
    SELECT 
        cd_gender,
        AVG(total_spent) AS avg_spent,
        AVG(total_orders) AS avg_orders
    FROM 
        Customer_Sales
    GROUP BY 
        cd_gender
),
Sales_Comparison AS (
    SELECT 
        cs.cd_gender,
        cs.total_spent,
        sa.avg_spent,
        CASE 
            WHEN cs.total_spent > sa.avg_spent THEN 'Above Average'
            ELSE 'Below Average'
        END AS spending_category
    FROM 
        Customer_Sales cs
    JOIN 
        Sales_Averages sa ON cs.cd_gender = sa.cd_gender
)
SELECT 
    sc.cd_gender,
    COUNT(sc.spending_category) AS count_above_below_avg,
    sc.spending_category
FROM 
    Sales_Comparison sc
GROUP BY 
    sc.cd_gender, sc.spending_category
ORDER BY 
    sc.cd_gender, count_above_below_avg DESC;
