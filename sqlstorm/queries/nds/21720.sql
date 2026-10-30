
WITH  potential_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS full_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        CASE WHEN cd.cd_purchase_estimate > 10000 THEN 'High Value'
             WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
             ELSE 'Low Value' END AS value_category,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month = 12 AND c.c_birth_day = 25
),
order_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_performance AS (
    SELECT 
        pc.full_name,
        pc.cd_gender,
        os.total_orders,
        os.total_profit,
        os.total_sales,
        pc.value_category
    FROM 
        potential_customers pc
    LEFT JOIN 
        order_summary os ON pc.c_customer_sk = os.ws_bill_customer_sk
    WHERE 
        (os.total_sales IS NULL OR os.total_sales < 100) 
        AND (pc.dep_count IS NOT NULL OR pc.cd_marital_status = 'S')
),
final_report AS (
    SELECT 
        cp.cd_gender,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN cp.value_category = 'High Value' THEN 1 ELSE 0 END) AS high_value_count,
        AVG(cp.total_profit) AS avg_profit,
        SUM(cp.total_sales) AS total_sales
    FROM 
        customer_performance cp
    GROUP BY 
        cp.cd_gender
    HAVING 
        SUM(cp.total_sales) IS NOT NULL
    ORDER BY 
        customer_count DESC
)
SELECT 
    fr.cd_gender,
    fr.customer_count,
    fr.high_value_count,
    COALESCE(fr.avg_profit, 0) AS avg_profit,
    COALESCE(fr.total_sales, 0) AS total_sales,
    CASE 
        WHEN fr.high_value_count > 10 THEN 'Top Segment'
        WHEN fr.customer_count BETWEEN 5 AND 10 THEN 'Middle Segment'
        ELSE 'Low Segment' 
    END AS market_segment
FROM 
    final_report fr
WHERE 
    fr.customer_count > (SELECT AVG(customer_count) FROM final_report)
UNION ALL
SELECT 
    'Overall' AS cd_gender,
    COUNT(*) AS customer_count,
    SUM(high_value_count) AS high_value_count,
    AVG(avg_profit) AS avg_profit,
    SUM(total_sales) AS total_sales,
    'Aggregate' AS market_segment
FROM 
    (
        SELECT 
            fr.cd_gender,
            COUNT(*) AS customer_count,
            SUM(fr.high_value_count) AS high_value_count,
            AVG(fr.avg_profit) AS avg_profit,
            SUM(fr.total_sales) AS total_sales
        FROM 
            final_report fr
        GROUP BY 
            fr.cd_gender
    ) AS subquery
ORDER BY 
    customer_count DESC;
