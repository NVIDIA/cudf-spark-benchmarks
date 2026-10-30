
WITH  SalesRank AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 100 AND 200
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
),
FrequentShippers AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        sm.sm_ship_mode_id
    HAVING 
        COUNT(ws.ws_order_number) > 5
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    sr.ws_order_number,
    sr.ws_sales_price,
    fs.total_orders,
    COALESCE(sr.ws_sales_price - (sr.ws_sales_price * 0.05), 0) AS discounted_price
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesRank sr ON cd.c_customer_sk = sr.ws_item_sk
JOIN 
    FrequentShippers fs ON sr.ws_order_number IS NOT NULL
WHERE 
    cd.cd_gender = 'F' 
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = sr.ws_item_sk 
        AND ss.ss_sold_date_sk BETWEEN 100 AND 200
    )
ORDER BY 
    cd.c_last_name, 
    sr.ws_sales_price DESC
LIMIT 100;
