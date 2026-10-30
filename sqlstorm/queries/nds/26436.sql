
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status AS marital_status,
        cd_purchase_estimate AS purchase_estimate,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FullReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.gender,
        cd.marital_status,
        cd.purchase_estimate,
        cd.full_address,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    gender,
    marital_status,
    purchase_estimate,
    full_address,
    total_net_profit,
    order_count
FROM 
    FullReport
WHERE 
    total_net_profit > 10000
ORDER BY 
    total_net_profit DESC;
