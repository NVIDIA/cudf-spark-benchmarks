
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER(PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY', 'TX')
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        RankedAddresses a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        d.cd_marital_status = 'M' 
        AND d.cd_gender = 'F'
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458597 AND 2458627 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    fc.full_name,
    fc.ca_city,
    fc.ca_state,
    sd.total_net_profit,
    sd.total_orders
FROM 
    FilteredCustomers fc
LEFT JOIN 
    SalesData sd ON fc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    sd.total_orders IS NOT NULL
ORDER BY 
    sd.total_net_profit DESC
LIMIT 50;
