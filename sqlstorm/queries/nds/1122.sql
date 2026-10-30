
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
),
SalesCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        c.c_first_name,
        c.c_last_name,
        c.ca_city,
        c.ca_state
    FROM 
        RankedSales r
    JOIN 
        CustomerInfo c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.rank_sales <= 5
)
SELECT 
    s.ws_bill_customer_sk,
    s.total_sales,
    CONCAT(s.c_first_name, ' ', s.c_last_name) AS full_name,
    s.ca_city,
    s.ca_state 
FROM 
    SalesCustomers s
UNION ALL
SELECT 
    NULL AS ws_bill_customer_sk,
    SUM(ws_net_paid) AS total_sales,
    'Total Sales' AS full_name,
    NULL AS ca_city,
    NULL AS ca_state
FROM 
    web_sales
WHERE 
    ws_net_paid IS NOT NULL
GROUP BY 
    1  -- Grouping by the single NULL value since it's the only column in the SELECT
ORDER BY 
    total_sales DESC;
