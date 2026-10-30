
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ReturnInfo AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_amount, 0) AS total_return_amount,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.total_sales_amount, 0) AS total_sales_amount
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        ReturnInfo ri ON ci.c_customer_sk = ri.sr_customer_sk
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    c.*,
    CASE 
        WHEN total_sales > total_return_amount THEN 'Low Risk'
        WHEN total_returns > total_sales THEN 'High Risk'
        ELSE 'Moderate Risk'
    END AS customer_risk_level
FROM 
    CombinedInfo c
WHERE 
    c.ca_state = 'CA' 
ORDER BY 
    c.total_sales_amount DESC
LIMIT 100;
