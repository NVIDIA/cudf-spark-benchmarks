
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
potential_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (cd.cd_purchase_estimate IS NULL OR cd.cd_purchase_estimate < 500) AND
        cd.cd_gender = 'F'
),
final_report AS (
    SELECT 
        pc.c_customer_sk,
        pc.c_first_name || ' ' || pc.c_last_name AS full_name,
        pc.cd_gender,
        pc.cd_marital_status,
        ss.total_sales,
        COALESCE(ss.sales_rank, 0) AS sales_rank
    FROM 
        potential_customers pc
    LEFT JOIN 
        sales_summary ss ON pc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    fr.full_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_sales,
    fr.sales_rank
FROM 
    final_report fr
WHERE 
    (fr.total_sales IS NULL OR fr.total_sales < 500) AND
    fr.sales_rank <= 5
ORDER BY 
    fr.total_sales DESC NULLS LAST;
