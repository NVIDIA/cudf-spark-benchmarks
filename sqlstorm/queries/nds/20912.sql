
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn,
        cs_quantity,
        cs_net_profit,
        cs_ext_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_year = 'Y')
    AND cs_quantity > 0
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amt
    FROM catalog_returns
    GROUP BY cr_item_sk
),
StoreRevenue AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS transactions_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_month = 'Y') 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY ss_item_sk
),
FinalReport AS (
    SELECT 
        r.cs_item_sk,
        r.cs_order_number,
        r.cs_quantity,
        r.cs_net_profit,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0.00) AS total_return_amt,
        COALESCE(s.total_net_paid, 0.00) AS total_store_net_paid,
        COALESCE(s.transactions_count, 0) AS total_transactions,
        CASE 
            WHEN r.cs_net_profit - COALESCE(c.total_return_amt, 0) < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_or_loss
    FROM RankedSales r
    LEFT JOIN CustomerReturns c ON r.cs_item_sk = c.cr_item_sk
    LEFT JOIN StoreRevenue s ON r.cs_item_sk = s.ss_item_sk
    WHERE r.rn = 1
    ORDER BY r.cs_net_profit DESC
)
SELECT 
    fs.cs_item_sk,
    fs.cs_order_number,
    fs.cs_quantity,
    fs.cs_net_profit,
    fs.total_returns,
    fs.total_return_amt,
    fs.total_store_net_paid,
    fs.total_transactions,
    fs.profit_or_loss,
    (SELECT AVG(cs_ext_sales_price) FROM RankedSales WHERE cs_item_sk = fs.cs_item_sk) AS avg_ext_sales_price,
    (SELECT AVG(cs_quantity) FROM RankedSales WHERE cs_item_sk = fs.cs_item_sk) AS avg_quantity,
    CASE 
        WHEN fs.total_transactions > (SELECT COUNT(DISTINCT ss_ticket_number) FROM store_sales WHERE ss_item_sk = fs.cs_item_sk) * 0.5 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM FinalReport fs
WHERE fs.profit_or_loss = 'Profit'
AND fs.total_store_net_paid > 0
ORDER BY fs.cs_net_profit DESC
LIMIT 100;
