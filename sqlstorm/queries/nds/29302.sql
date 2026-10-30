
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
BestCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.total_orders,
        cs.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerStats cs
)
SELECT 
    bc.c_customer_sk,
    CONCAT(bc.c_first_name, ' ', bc.c_last_name) AS full_name,
    bc.cd_gender,
    ai.full_address,
    ai.ca_zip,
    bc.total_orders,
    bc.total_profit
FROM 
    BestCustomers bc
JOIN 
    AddressInfo ai ON bc.c_customer_sk = ai.ca_address_sk
WHERE 
    bc.rank <= 10
ORDER BY 
    bc.cd_gender, bc.total_profit DESC;
