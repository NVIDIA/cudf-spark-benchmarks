
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ReturnsInfo AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS number_of_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
FinalInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.full_address,
        ci.ca_country,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.number_of_orders, 0) AS number_of_orders,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.number_of_returns, 0) AS number_of_returns
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        ReturnsInfo ri ON ci.c_customer_sk = ri.wr_returning_customer_sk
)
SELECT 
    *,
    (total_sales - total_returns) AS net_sales,
    (number_of_orders - number_of_returns) AS net_orders
FROM 
    FinalInfo
WHERE 
    cd_gender = 'F'
ORDER BY 
    net_sales DESC
LIMIT 10;
