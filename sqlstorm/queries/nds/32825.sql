
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
Promotions AS (
    SELECT 
        p_promo_sk,
        p_discount_active,
        SUM(ws_net_paid) AS total_discounted_sales
    FROM web_sales
    JOIN promotion ON ws_promo_sk = p_promo_sk
    WHERE p_discount_active = 'Y'
    GROUP BY p_promo_sk, p_discount_active
),
TopItems AS (
    SELECT 
        i_item_sk,
        i_item_id,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM (
        SELECT 
            ws_item_sk,
            SUM(ws_net_paid) AS total_sales
        FROM web_sales
        GROUP BY ws_item_sk
    ) AS SalesSum
    JOIN item ON SalesSum.ws_item_sk = item.i_item_sk
)
SELECT 
    t1.ws_sold_date_sk,
    t1.ws_item_sk,
    t1.total_quantity,
    t1.total_sales,
    COALESCE(t2.total_discounted_sales, 0) AS total_discounted_sales,
    ti.i_item_id
FROM SalesCTE t1
LEFT JOIN Promotions t2 ON t1.ws_item_sk = t2.p_promo_sk
JOIN TopItems ti ON t1.ws_item_sk = ti.i_item_sk
WHERE ti.rank <= 10
AND t1.total_sales > (SELECT AVG(total_sales) FROM SalesCTE) 
ORDER BY t1.total_sales DESC;
