
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
BenchmarkResults AS (
    SELECT 
        cd.full_name,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_profit,
        sd.total_orders,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS rank
    FROM 
        CustomerDetails cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    CONCAT(rank, ': ', full_name, ' - ', gender, ' | ', cd_marital_status, ' | ', cd_education_status, 
           ' | Total Profit: $', ROUND(total_profit, 2), ' | Total Orders: ', total_orders) AS benchmark_result
FROM 
    BenchmarkResults
WHERE 
    total_orders > 5
ORDER BY 
    total_profit DESC;
