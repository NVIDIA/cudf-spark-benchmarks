
WITH  Sales_CTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sales_price,
        ss_quantity,
        ss_ext_sales_price,
        ss_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
), 
Inventory_CTE AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM
        inventory
    GROUP BY 
        inv_item_sk
), 
Customer_Returns AS (
    SELECT 
        sr_item_sk AS item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT
    inv.inv_item_sk,
    i.i_item_desc,
    COALESCE(SUM(sc.ss_quantity), 0) AS total_sold,
    COALESCE(SUM(cr.total_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sc.ss_ext_sales_price), 0) AS total_sales,
    inv.total_quantity_on_hand,
    CASE
        WHEN SUM(sc.ss_quantity) IS NULL THEN 'No Sales'
        WHEN COALESCE(SUM(cr.total_return_quantity), 0) > COALESCE(SUM(sc.ss_quantity), 0) THEN 'High Returns'
        ELSE 'Normal'
    END AS sales_status
FROM 
    Inventory_CTE inv
LEFT JOIN 
    Sales_CTE sc ON inv.inv_item_sk = sc.ss_item_sk AND sc.rn = 1
LEFT JOIN 
    Customer_Returns cr ON inv.inv_item_sk = cr.item_sk
JOIN 
    item i ON inv.inv_item_sk = i.i_item_sk
GROUP BY 
    inv.inv_item_sk, i.i_item_desc, inv.total_quantity_on_hand
HAVING 
    COALESCE(SUM(sc.ss_ext_sales_price), 0) > 500.00 OR COALESCE(SUM(cr.total_return_quantity), 0) > 10
ORDER BY 
    total_sales DESC, total_returns ASC;
