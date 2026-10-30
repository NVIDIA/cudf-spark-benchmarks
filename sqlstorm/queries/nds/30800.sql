
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        ws.ws_item_sk
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
RecentReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS return_count
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY sr.sr_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    id.i_item_id,
    id.total_sales,
    id.avg_price,
    COALESCE(rr.return_count, 0) AS return_count,
    CASE 
        WHEN rr.return_count IS NOT NULL AND rr.return_count > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    DENSE_RANK() OVER (ORDER BY id.avg_price DESC) AS price_rank
FROM CustomerSales cs
JOIN ItemDetails id ON cs.ws_item_sk = id.i_item_sk
LEFT JOIN RecentReturns rr ON id.i_item_sk = rr.sr_item_sk
WHERE cs.rn = 1
AND id.total_sales > 10
ORDER BY return_status, cs.c_last_name, cs.c_first_name;
