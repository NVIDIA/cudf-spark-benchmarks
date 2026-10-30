
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452054 AND 2452413
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
CustomerDemog AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_dep_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
    AND 
        cd.cd_marital_status IN ('M', 'S')
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
    MAX(RankedSales.ws_sales_price) AS max_sales_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    HighValueCustomers hv ON c.c_customer_id = hv.c_customer_id
JOIN 
    CustomerDemog cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedSales ON ws.ws_item_sk = RankedSales.ws_item_sk AND ws.ws_order_number = RankedSales.ws_order_number
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    unique_customers DESC, total_sales DESC
LIMIT 100;
