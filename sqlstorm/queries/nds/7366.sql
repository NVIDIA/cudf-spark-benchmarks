
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_id
), InventoryCheck AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory AS inv
    JOIN 
        item AS i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        i.i_item_id
), PromotionSummary AS (
    SELECT 
        p.p_promo_id, 
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count, 
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion AS p
    JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    inv.total_quantity,
    ps.promo_order_count,
    ps.promo_sales
FROM 
    CustomerSales AS cs
LEFT JOIN 
    InventoryCheck AS inv ON TRUE
LEFT JOIN 
    PromotionSummary AS ps ON TRUE
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
