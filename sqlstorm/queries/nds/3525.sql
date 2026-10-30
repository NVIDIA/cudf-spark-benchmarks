WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amt
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458486 AND 2458496 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.ca_city,
    ca.total_returned,
    sa.total_orders,
    sa.total_spent
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    CustomerReturns AS ca ON ci.c_customer_sk = ca.cr_returning_customer_sk
LEFT JOIN 
    SalesAnalysis AS sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    (ca.total_returned IS NULL OR ca.total_returned > 0)
    AND (sa.total_orders IS NOT NULL AND sa.total_orders > 5)
ORDER BY 
    sa.total_spent DESC NULLS LAST
LIMIT 50;