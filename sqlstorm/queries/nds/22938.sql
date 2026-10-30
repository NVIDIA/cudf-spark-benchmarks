
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_sub.ws_sales_price) FROM web_sales ws_sub WHERE ws_sub.ws_item_sk = ws.ws_item_sk)
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(COALESCE(cur.ws_sales_price, 0)) AS total_sales,
    SUM(art.total_returns) AS total_returns
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT 
         ws_item_sk, 
         ws_sales_price
     FROM 
         RankedSales 
     WHERE 
         rank = 1
    ) cur ON cur.ws_item_sk IN (SELECT sr_item_sk FROM AggregateReturns)
LEFT JOIN 
    AggregateReturns art ON art.sr_item_sk = cur.ws_item_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ca.ca_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    )
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_sales DESC, 
    customer_count ASC;
