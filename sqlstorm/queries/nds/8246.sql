
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returned_transactions
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS demographic_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)

SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_id) AS number_of_customers,
    SUM(sa.total_orders) AS total_orders,
    SUM(cu.total_returned_qty) AS total_returned_qty,
    AVG(demo.avg_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    SalesAnalysis sa ON c.c_customer_sk = sa.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cu ON c.c_customer_id = cu.c_customer_id
LEFT JOIN 
    Demographics demo ON c.c_current_cdemo_sk = demo.cd_demo_sk
WHERE 
    ca.ca_state = 'NY'
GROUP BY 
    ca.ca_country
ORDER BY 
    number_of_customers DESC;
