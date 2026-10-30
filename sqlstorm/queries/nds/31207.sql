
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    WHERE item.i_current_price IS NOT NULL
    GROUP BY item.i_item_id, item.i_item_desc
    HAVING COALESCE(SUM(ws.ws_net_profit), 0) > 1000
),
CustomerRank AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
ReturnData AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        SUM(CASE WHEN sr_returned_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS return_count
    FROM store_returns sr
),
FinalResult AS (
    SELECT 
        ts.i_item_desc,
        ts.total_net_profit,
        cr.customer_rank,
        rd.total_returns,
        rd.return_count
    FROM TopSales ts
    JOIN CustomerRank cr ON ts.total_net_profit > 2000
    CROSS JOIN ReturnData rd
)
SELECT 
    f.i_item_desc,
    f.total_net_profit,
    f.customer_rank,
    f.total_returns,
    f.return_count,
    CASE 
        WHEN f.total_net_profit > 5000 THEN 'High Profit'
        WHEN f.total_net_profit > 2000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM FinalResult f
ORDER BY f.customer_rank, f.total_net_profit DESC;
