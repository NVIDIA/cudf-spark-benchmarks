
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_refunded
    FROM web_returns
    GROUP BY wr_refunded_customer_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand) > 0
),
SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM catalog_sales
    GROUP BY cs_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_item_desc
    FROM item
),
CombinedSales AS (
    SELECT 
        s.cs_item_sk,
        s.total_sales,
        s.total_orders,
        i.i_product_name,
        i.i_item_desc,
        COALESCE(r.total_refunded, 0) AS total_refunded,
        COALESCE(o.total_quantity, 0) AS total_inventory,
        COALESCE(r.total_refunded / NULLIF(s.total_sales, 0), 0) AS refund_ratio
    FROM SalesData s
    LEFT JOIN ItemDetails i ON s.cs_item_sk = i.i_item_sk
    LEFT JOIN CustomerReturns r ON r.wr_refunded_customer_sk = s.cs_item_sk
    LEFT JOIN InventoryStatus o ON o.inv_item_sk = s.cs_item_sk
)
SELECT 
    c.cs_item_sk AS item_sk,
    c.total_sales,
    c.total_orders,
    c.total_refunded,
    c.total_inventory,
    c.refund_ratio,
    ROW_NUMBER() OVER (ORDER BY c.refund_ratio DESC) AS refund_rank,
    RANK() OVER (PARTITION BY c.total_orders ORDER BY c.total_sales DESC) AS order_rank,
    CASE 
        WHEN c.total_refunded > 100 THEN 'High Refund'
        WHEN c.total_refunded BETWEEN 50 AND 100 THEN 'Medium Refund'
        ELSE 'Low Refund'
    END AS refund_category
FROM CombinedSales c
WHERE c.total_sales > 0
AND c.total_inventory IS NOT NULL
AND (c.refund_ratio IS NULL OR c.refund_ratio < 0.5)
ORDER BY c.total_sales DESC;
