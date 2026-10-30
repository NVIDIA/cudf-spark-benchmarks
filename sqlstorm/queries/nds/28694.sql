
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, ''), ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        CONCAT(cd.cd_gender, CASE WHEN cd.cd_marital_status = 'M' THEN ' (Married)' ELSE ' (Single)' END) AS marital_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnDetails AS (
    SELECT 
        sr_customer_sk, 
        sr_return_quantity, 
        sr_return_amt, 
        sr_return_tax
    FROM 
        store_returns
    WHERE 
        sr_return_amt > 0
),
Sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price, 
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_info,
    ac.full_address,
    rd.sr_return_quantity,
    rd.sr_return_amt,
    rd.sr_return_tax,
    s.total_sales_price,
    s.total_quantity
FROM 
    CustomerInfo ci
JOIN 
    AddressConcat ac ON ci.c_customer_sk = ac.ca_address_sk
LEFT JOIN 
    ReturnDetails rd ON ci.c_customer_sk = rd.sr_customer_sk
LEFT JOIN 
    Sales s ON s.ws_item_sk = ci.c_customer_sk
WHERE 
    rd.sr_return_quantity IS NOT NULL
ORDER BY 
    ci.c_last_name, ci.c_first_name;
