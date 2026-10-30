
WITH  Sales_CTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rn
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    HAVING 
        SUM(ss_net_profit) > 10000
),
Demographic_CTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
),
Top_Sales AS (
    SELECT 
        ss_store_sk,
        total_net_profit,
        total_sales_count
    FROM 
        Sales_CTE 
    WHERE rn <= 5
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(demo.cd_gender, 'N/A') AS gender,
    ts.total_net_profit,
    ts.total_sales_count,
    demo.customer_count,
    demo.avg_purchase_estimate
FROM 
    warehouse w
LEFT JOIN 
    Top_Sales ts ON w.w_warehouse_sk = ts.ss_store_sk
LEFT JOIN 
    Demographic_CTE demo ON ts.ss_store_sk = demo.cd_demo_sk
WHERE 
    w.w_warehouse_sq_ft > 1000
ORDER BY 
    ts.total_net_profit DESC, gender;
