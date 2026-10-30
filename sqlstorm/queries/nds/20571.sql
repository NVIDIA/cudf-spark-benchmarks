
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
HighValueReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 10
),
ValidPromotions AS (
    SELECT 
        p.p_item_sk, 
        p.p_promo_name
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y' 
        AND p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01')
        AND (p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01') OR p.p_end_date_sk IS NULL)
),
FinalResult AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.sale_rank, 0) AS sale_rank,
        COALESCE(returns.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(returns.total_returned_amount, 0) AS total_returned_amount,
        promotions.p_promo_name AS promo_name
    FROM 
        item
    LEFT JOIN 
        RankedSales sales ON item.i_item_sk = sales.ws_item_sk AND sales.sale_rank = 1
    LEFT JOIN 
        HighValueReturns returns ON item.i_item_sk = returns.sr_item_sk
    LEFT JOIN 
        ValidPromotions promotions ON item.i_item_sk = promotions.p_item_sk
)
SELECT 
    f.i_item_id, 
    f.i_item_desc, 
    f.sale_rank, 
    f.total_returned_quantity, 
    f.total_returned_amount, 
    f.promo_name,
    CASE 
        WHEN f.total_returned_quantity > 0 THEN 'High Return'
        ELSE 'Normal'
    END AS return_status
FROM 
    FinalResult f
WHERE 
    COALESCE(f.sale_rank, 0) > 0
ORDER BY 
    f.total_returned_amount DESC
LIMIT 100;
