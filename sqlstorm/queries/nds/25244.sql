
WITH customer_info AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', 
                ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_info AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    ci.customer_id,
    ci.full_name,
    ci.address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.return_count, 0) AS return_count,
    (COALESCE(si.total_sales, 0) - COALESCE(ri.total_returns, 0)) AS net_sales
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.customer_id = si.ws_bill_customer_sk
LEFT JOIN 
    returns_info ri ON ci.customer_id = ri.wr_returning_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    net_sales DESC
LIMIT 100;
