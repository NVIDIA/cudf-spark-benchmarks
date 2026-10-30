
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_street_name,
        ca.ca_street_type,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY')
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    fa.ca_city,
    fa.ca_state,
    fa.full_address,
    ss.total_sales,
    ss.total_orders
FROM 
    RankedCustomers rc
JOIN 
    FilteredAddresses fa ON rc.c_customer_sk = fa.ca_address_sk
JOIN 
    SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_purchase_estimate DESC, 
    rc.c_last_name ASC;
