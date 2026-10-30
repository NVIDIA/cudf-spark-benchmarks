
WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk, 
        p.p_promo_name, 
        p.p_cost, 
        p.p_start_date_sk, 
        p.p_end_date_sk,
        COUNT(DISTINCT cs_order_number) AS promo_order_count
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_cost, p.p_start_date_sk, p.p_end_date_sk
),
TopSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        s.order_count,
        p.promo_order_count,
        CASE 
            WHEN p.promo_order_count IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS has_promotion
    FROM SalesData s
    LEFT JOIN Promotions p ON s.ws_item_sk = p.p_promo_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    ts.has_promotion,
    RANK() OVER (ORDER BY COALESCE(ts.total_sales, 0) DESC) AS sales_rank
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
WHERE i.i_current_price > 10.00 
AND EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y'))
ORDER BY sales_rank;
