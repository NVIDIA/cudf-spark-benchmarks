
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebSalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    COALESCE(ws.total_quantity, 0) AS purchased_quantity,
    COALESCE(ws.total_net_profit, 0) AS net_profit,
    COALESCE(r.total_returns, 0) AS return_count,
    COALESCE(r.total_return_amount, 0) AS return_amount
FROM 
    AddressInfo a
JOIN 
    CustomerInfo c ON a.ca_address_sk = c.c_customer_sk
LEFT JOIN 
    WebSalesInfo ws ON c.c_customer_sk = ws.ws_item_sk
LEFT JOIN 
    ReturnSummary r ON ws.ws_item_sk = r.sr_item_sk
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    c.cd_marital_status DESC,
    ws.total_net_profit DESC
LIMIT 100;
