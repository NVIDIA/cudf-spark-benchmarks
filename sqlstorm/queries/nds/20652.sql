
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        (cd_dep_count - COALESCE(cd_dep_employed_count, 0)) AS unemployed_deps
    FROM customer_demographics
    LEFT JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
),
ItemProfitAnalysis AS (
    SELECT 
        i_item_sk,
        i_item_id,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales 
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    GROUP BY i_item_sk, i_item_id
),
ItemWithReturns AS (
    SELECT 
        iia.i_item_sk,
        iia.i_item_id,
        COALESCE(ar.total_returns, 0) AS total_returns,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount,
        ia.total_profit
    FROM ItemProfitAnalysis ia
    LEFT JOIN AggregatedReturns ar ON ia.i_item_sk = ar.sr_item_sk
    JOIN item iia ON ia.i_item_sk = iia.i_item_sk
)
SELECT 
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ia.total_profit,
    ia.total_returns,
    ia.total_return_amount,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN ws.ws_quantity > COALESCE(ia.total_returns, 0) THEN 'Sales Exceeds Returns'
        ELSE 'Returns Exceeds Sales'
    END AS sales_return_comparison,
    CASE 
        WHEN RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) <= 5 THEN 'Top 5 Selling Item'
        ELSE 'Not in Top 5'
    END AS item_rank_status
FROM web_sales ws
JOIN ItemWithReturns ia ON ws.ws_item_sk = ia.i_item_sk
LEFT JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
WHERE ws.ws_sold_date_sk IN (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_holiday = 'Y'
)
AND ws.ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_item_sk = ws.ws_item_sk)
ORDER BY ws.ws_sold_date_sk, ws.ws_item_sk;
