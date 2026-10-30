
WITH  sales_cte AS (
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_quantity, 
        cs_sales_price, 
        cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2458464 AND 2458480  
),
inventory_cte AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_item_sk
),
promotional_data AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name, 
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales
    FROM promotion p
    LEFT JOIN store_sales s ON p.p_promo_sk = s.ss_promo_sk
    WHERE p.p_start_date_sk < 2458480 
        AND (p.p_end_date_sk IS NULL OR p.p_end_date_sk > 2458464)
    GROUP BY p.p_promo_id, p.p_promo_name
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    cs.cs_item_sk, 
    cs.cs_order_number, 
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_sales_price,
    inv.total_quantity,
    COALESCE(pr.total_sales, 0) AS promotional_sales,
    COALESCE(cr.total_returns, 0) AS customer_returns,
    COALESCE(cr.total_return_amount, 0) AS return_amount
FROM sales_cte cs
LEFT JOIN inventory_cte inv ON cs.cs_item_sk = inv.inv_item_sk
LEFT JOIN promotional_data pr ON cs.cs_order_number = pr.total_sales
LEFT JOIN customer_returns cr ON cs.cs_order_number = cr.sr_customer_sk
WHERE cs.rn <= 10  
ORDER BY cs.cs_item_sk, cs.cs_order_number;
