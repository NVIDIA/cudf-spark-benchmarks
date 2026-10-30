
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS average_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
demographic_analysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.total_orders,
        si.average_order_value,
        COALESCE(ri.total_returns, 0) AS total_returns,
        (COALESCE(si.total_sales, 0) - COALESCE(ri.total_returns, 0)) AS net_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary si ON ci.c_customer_sk = si.customer_sk
    LEFT JOIN 
        returns_summary ri ON ci.c_customer_sk = ri.customer_sk
),
final_output AS (
    SELECT 
        da.c_customer_sk,
        da.c_first_name,
        da.c_last_name,
        da.cd_gender,
        da.cd_marital_status,
        da.total_sales,
        da.total_orders,
        da.average_order_value,
        da.total_returns,
        da.net_sales,
        CASE 
            WHEN da.net_sales > 10000 THEN 'Premium Customer'
            WHEN da.net_sales BETWEEN 5000 AND 10000 THEN 'Regular Customer'
            ELSE 'Low Value Customer'
        END AS customer_segment
    FROM 
        demographic_analysis da
    ORDER BY 
        da.net_sales DESC
)
SELECT 
    * 
FROM 
    final_output 
LIMIT 10;
