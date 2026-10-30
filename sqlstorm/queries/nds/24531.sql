
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk, 
        cs.cs_order_number, 
        cs.cs_quantity, 
        cs.cs_sales_price, 
        cs.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_ext_sales_price DESC) as rn
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
), 
DistinctCustomers AS (
    SELECT 
        DISTINCT ws_bill_customer_sk, 
        ws_ship_customer_sk 
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
), 
SalesWithReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        store_returns sr
    LEFT JOIN 
        web_sales ws ON sr.sr_item_sk = ws.ws_item_sk AND sr.sr_store_sk = ws.ws_ship_addr_sk 
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cu.ca_city,
    cu.ca_state,
    COALESCE(SUM(s.ws_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(sr.total_returns), 0) AS total_returns,
    COUNT(DISTINCT cu.ca_zip) AS address_count,
    COUNT(DISTINCT d.ws_bill_customer_sk) AS distinct_web_sales_customers
FROM 
    customer c
LEFT JOIN 
    customer_address cu ON c.c_current_addr_sk = cu.ca_address_sk
LEFT JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    SalesWithReturns sr ON sr.sr_item_sk = s.ws_item_sk
LEFT JOIN 
    DistinctCustomers d ON d.ws_bill_customer_sk = c.c_customer_sk OR d.ws_ship_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000 
    AND (
        SELECT COUNT(*) 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
          AND cd.cd_credit_rating IN ('Good', 'Excellent')
    ) > 0
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cu.ca_city, cu.ca_state
HAVING 
    COALESCE(SUM(s.ws_quantity), 0) > 10 
    OR COALESCE(SUM(sr.total_returns), 0) > 5
ORDER BY 
    total_quantity_sold DESC,
    total_returns DESC
LIMIT 50;
