
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_info AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    si.total_sales,
    si.order_count,
    COALESCE(ri.return_count, 0) AS return_count,
    COALESCE(ri.total_returns, 0) AS total_returns,
    CASE 
        WHEN si.total_sales IS NOT NULL THEN 
            ROUND(100.0 * COALESCE(ri.total_returns, 0) / si.total_sales, 2) 
        ELSE 0 
    END AS return_rate_percentage
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN 
    returns_info ri ON ci.c_customer_sk = ri.wr_returning_customer_sk
ORDER BY 
    return_rate_percentage DESC
LIMIT 100;
