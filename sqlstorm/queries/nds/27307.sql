
WITH CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip
    FROM 
        customer_address ca
), 
CustomerAndDemographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.full_address
    FROM 
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerAddressInfo ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
ReturnedSales AS (
    SELECT 
        sr.sr_customer_sk, 
        SUM(sr.sr_return_amt) AS total_returned_amount,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_ship_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    cad.full_name,
    cad.cd_gender,
    cad.cd_marital_status,
    cad.cd_education_status,
    cad.cd_purchase_estimate,
    cad.cd_credit_rating,
    cad.cd_dep_count,
    cad.full_address,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    CustomerAndDemographics cad
LEFT JOIN 
    ReturnedSales rs ON cad.c_customer_sk = rs.sr_customer_sk
LEFT JOIN 
    SalesSummary ss ON cad.c_customer_sk = ss.ws_ship_customer_sk
ORDER BY 
    total_sales_amount DESC, 
    total_returned_amount ASC
LIMIT 100;
