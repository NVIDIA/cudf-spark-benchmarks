
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
)

SELECT 
    c.c_customer_id,
    CA.full_address,
    CD.cd_gender,
    CD.cd_marital_status,
    COALESCE(CR.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(CR.total_return_amt, 0) AS total_return_amt,
    COALESCE(SD.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(SD.total_revenue, 0) AS total_revenue,
    COALESCE(SD.average_profit, 0) AS average_profit
FROM 
    customer c
LEFT JOIN 
    CustomerDemographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
LEFT JOIN 
    CustomerAddress CA ON c.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
LEFT JOIN 
    SalesData SD ON c.c_customer_sk = SD.ws_ship_customer_sk
WHERE 
    (CD.cd_marital_status = 'M' AND CD.cd_gender = 'M' AND CD.cd_purchase_estimate > 100)
    OR (COALESCE(CR.total_returned_quantity, 0) > 5)
ORDER BY 
    total_returned_quantity DESC,
    total_revenue DESC
LIMIT 100;
