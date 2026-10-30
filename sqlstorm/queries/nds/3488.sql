
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        ss.total_sales, 
        ss.order_count, 
        ss.avg_net_paid
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.sales_rank <= 10
) 
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    CASE 
        WHEN h.hd_income_band_sk IS NOT NULL THEN CONCAT('Income Band: ', h.hd_income_band_sk)
        ELSE 'No Income Band'
    END AS income_band_info
FROM 
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
ORDER BY 
    tc.total_sales DESC;
