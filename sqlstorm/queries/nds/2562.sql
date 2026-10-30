WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451916 AND 2451980  
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
TotalReturns AS (
    SELECT 
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451916 AND 2451980
),
InventoryStats AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    COALESCE(rk.total_quantity, 0) AS total_inventory,
    COALESCE(tr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(tr.total_returned_amount, 0.00) AS total_returned_amount
FROM CustomerStats cs
LEFT JOIN InventoryStats rk ON rk.inv_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE rnk <= 5)
LEFT JOIN TotalReturns tr ON 1=1  
WHERE cs.total_customers > 10
ORDER BY cs.cd_gender, total_inventory DESC;