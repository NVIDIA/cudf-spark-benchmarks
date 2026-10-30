
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    dd.cd_demo_sk,
    dd.cd_gender,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity,
    (COALESCE(cr.total_returned_amount, 0) - COALESCE(ss.total_sales_amount, 0)) AS net_revenue,
    dd.ca_city,
    dd.ca_state
FROM 
    DemographicDetails dd
LEFT JOIN 
    CustomerReturns cr ON dd.cd_demo_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesSummary ss ON dd.cd_demo_sk = ss.ws_bill_customer_sk
WHERE 
    dd.cd_purchase_estimate > 1000
    AND (dd.cd_gender = 'F' OR (dd.cd_marital_status = 'S' AND dd.ca_state = 'NY'))
ORDER BY 
    net_revenue DESC
LIMIT 50;
