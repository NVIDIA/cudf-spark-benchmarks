
WITH SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 24586 AND 24596
    GROUP BY 
        ws_item_sk
),
ReturnsCTE AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN 24586 AND 24596
    GROUP BY 
        wr_item_sk
),
InventoryCTE AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    WHERE 
        inv_date_sk = 24595
    GROUP BY 
        inv_item_sk
),
ItemInfo AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_current_price
    FROM 
        item
)

SELECT 
    ii.i_product_name,
    ii.i_brand,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_return_amt, 0) AS total_return_amount,
    i.total_inventory,
    ((COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0)) / NULLIF(i.total_inventory, 0)) AS sales_to_inventory_ratio
FROM 
    ItemInfo ii
LEFT JOIN 
    SalesCTE s ON ii.i_item_sk = s.ws_item_sk
LEFT JOIN 
    ReturnsCTE r ON ii.i_item_sk = r.wr_item_sk
LEFT JOIN 
    InventoryCTE i ON ii.i_item_sk = i.inv_item_sk
WHERE 
    ii.i_current_price IS NOT NULL
ORDER BY 
    sales_to_inventory_ratio DESC
LIMIT 10;
