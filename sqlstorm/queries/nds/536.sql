
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ss.total_sales,
        ss.order_count,
        ss.average_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.total_sales IS NOT NULL
)
SELECT 
    cs.*,
    CASE 
        WHEN cs.average_profit IS NULL THEN 'No Profit Data'
        WHEN cs.average_profit < 50 THEN 'Low Profit'
        WHEN cs.average_profit BETWEEN 50 AND 100 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category,
    (SELECT COUNT(*) FROM store s WHERE s.s_number_employees > 50) AS store_count_with_many_employees,
    COALESCE((SELECT COUNT(*) FROM store_sales WHERE ss_customer_sk = cs.c_customer_sk GROUP BY ss_customer_sk), 0) AS personal_store_sales
FROM 
    customer_sales cs
WHERE 
    cs.total_sales > 1000 OR cs.order_count > 5
ORDER BY 
    cs.total_sales DESC;
