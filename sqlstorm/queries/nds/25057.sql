
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        da.ca_city,
        da.ca_state,
        da.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
return_info AS (
    SELECT 
        wr.wr_returning_customer_sk AS customer_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_amt, 0) AS total_return_amt
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.customer_sk
LEFT JOIN 
    return_info ri ON ci.c_customer_sk = ri.customer_sk
WHERE 
    ci.cd_purchase_estimate > 500 AND 
    ci.cd_gender = 'F' AND 
    ci.ca_state = 'CA'
ORDER BY 
    total_sales DESC
LIMIT 100;
