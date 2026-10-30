
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(ws.ws_net_paid_inc_tax, 0) AS net_paid
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighSpenderCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.avg_net_paid,
        CASE 
            WHEN cs.avg_net_paid IS NULL 
            THEN 'No Spending'
            WHEN cs.avg_net_paid > 1000 THEN 'High Spender'
            ELSE 'Regular Spender'
        END AS spending_category
    FROM CustomerStats cs
    WHERE cs.total_orders > 0
),
ItemPriceReturns AS (
    SELECT 
        inv.inv_item_sk,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_returns,
        AVG(cr.cr_return_amount) AS avg_return_amt
    FROM inventory inv
    LEFT JOIN catalog_returns cr ON inv.inv_item_sk = cr.cr_item_sk
    GROUP BY inv.inv_item_sk
),
FinalReport AS (
    SELECT 
        hsc.c_customer_sk,
        ipr.inv_item_sk,
        ipr.total_returns,
        hsc.spending_category,
        CASE 
            WHEN ipr.total_returns IS NULL THEN 'No Returns'
            WHEN ipr.total_returns > 10 THEN 'High Returns'
            ELSE 'Low Returns'
        END AS return_category,
        ir.ws_sales_price AS latest_price
    FROM HighSpenderCustomers hsc
    JOIN ItemPriceReturns ipr ON hsc.c_customer_sk = ipr.inv_item_sk
    JOIN RankedSales ir ON ipr.inv_item_sk = ir.ws_item_sk AND ir.price_rank = 1
)
SELECT 
    fr.c_customer_sk,
    fr.inv_item_sk,
    fr.total_returns,
    fr.spending_category,
    fr.return_category,
    fr.latest_price
FROM FinalReport fr
WHERE fr.spending_category = 'High Spender' AND fr.return_category = 'Low Returns'
ORDER BY fr.total_returns DESC NULLS LAST;
