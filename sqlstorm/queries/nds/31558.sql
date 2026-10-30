
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
aggregated_returns AS (
    SELECT 
        wr_returning_customer_sk AS customer_id,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.customer_id
    LEFT JOIN 
        aggregated_returns ar ON c.c_customer_sk = ar.customer_id
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_sales,
    ci.total_return_amount,
    CASE 
        WHEN ci.total_sales > ci.total_return_amount THEN 'Profitable'
        WHEN ci.total_sales < ci.total_return_amount THEN 'Unprofitable'
        ELSE 'Break Even'
    END AS profitability_status,
    RANK() OVER (ORDER BY ci.total_sales - ci.total_return_amount DESC) AS profitability_rank
FROM 
    customer_info ci
WHERE 
    ci.total_sales > 0
    AND (ci.cd_gender = 'M' OR ci.cd_marital_status = 'S')
ORDER BY 
    profitability_rank
LIMIT 100;
