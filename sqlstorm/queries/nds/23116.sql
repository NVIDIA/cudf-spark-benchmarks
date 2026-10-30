
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 1010
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_revenue
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow = 1 OR d_weekend = 'Y')
    GROUP BY 
        ss_sold_date_sk, 
        ss_item_sk
),
inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS available_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    it.i_item_id,
    it.i_product_name,
    ss.total_quantity AS web_sales_quantity,
    ts.total_quantity AS store_sales_quantity,
    ic.available_stock,
    COALESCE(ss.total_revenue, 0) AS web_sales_revenue,
    COALESCE(ts.total_revenue, 0) AS store_sales_revenue,
    CASE 
        WHEN ic.available_stock IS NULL THEN 'No Stock Info' 
        ELSE CASE 
            WHEN ic.available_stock < 10 THEN 'Low Stock'
            WHEN ic.available_stock BETWEEN 10 AND 50 THEN 'Moderate Stock' 
            ELSE 'High Stock' 
        END 
    END AS stock_status
FROM 
    item it
LEFT JOIN 
    sales_summary ss ON it.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    top_sales ts ON it.i_item_sk = ts.ss_item_sk
LEFT JOIN 
    inventory_check ic ON it.i_item_sk = ic.inv_item_sk
WHERE 
    (ss.sales_rank <= 10 OR ts.total_quantity IS NOT NULL)
    AND (it.i_current_price IS NOT NULL OR it.i_current_price > 0)
ORDER BY 
    web_sales_revenue DESC, 
    store_sales_revenue DESC
LIMIT 25;
