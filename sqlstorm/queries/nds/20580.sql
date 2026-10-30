
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
HighValueSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity,
        CASE 
            WHEN r.price_rank = 1 THEN 'Highest Price'
            WHEN r.price_rank > (SELECT COUNT(*) / 2 FROM RankedSales) THEN 'Mid-range Price'
            ELSE 'Lower Price'
        END AS price_category
    FROM 
        RankedSales r
    WHERE 
        r.total_quantity > 100 OR r.total_sales > 1000.00
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unspecified'
            ELSE cd.cd_gender
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.cd_marital_status,
    SUM(hs.ws_sales_price * hs.ws_quantity) AS total_spent,
    COUNT(DISTINCT hs.ws_order_number) AS order_count
FROM 
    HighValueSales hs
JOIN 
    CustomerInfo ci ON hs.ws_item_sk = ci.c_customer_sk
LEFT JOIN 
    store s ON hs.ws_item_sk = s.s_store_sk
WHERE 
    (ci.gender = 'M' OR ci.gender = 'F')
    AND (ci.cd_purchase_estimate IS NOT NULL AND ci.cd_purchase_estimate > 500)
GROUP BY 
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.cd_marital_status
HAVING 
    SUM(hs.ws_sales_price * hs.ws_quantity) > (SELECT AVG(total_spent) FROM (
        SELECT SUM(ws_sales_price) AS total_spent 
        FROM web_sales 
        GROUP BY ws_order_number) AS subquery)
    OR SUM(hs.ws_sales_price * hs.ws_quantity) IS NULL
ORDER BY 
    total_spent DESC
LIMIT 10 OFFSET 5;
