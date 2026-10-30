
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_within_item
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2022
    GROUP BY 
        ws.ws_item_sk
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_amt) > 1000
),
StoreSalesAggregated AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        RankedSales rs ON ss.ss_item_sk = rs.ws_item_sk
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(hvr.return_count, 0) AS return_count,
    COALESCE(hvr.total_return_amount, 0) AS total_return_amount,
    COALESCE(rsa.total_quantity, 0) AS total_web_sales_quantity,
    COALESCE(rsa.total_revenue, 0) AS total_web_sales_revenue,
    COALESCE(sa.total_store_sales, 0) AS total_store_sales
FROM 
    item i
LEFT JOIN 
    HighValueReturns hvr ON i.i_item_sk = hvr.sr_item_sk
LEFT JOIN 
    RankedSales rsa ON i.i_item_sk = rsa.ws_item_sk AND rsa.rank_within_item = 1
LEFT JOIN 
    StoreSalesAggregated sa ON i.i_item_sk = sa.ss_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    total_web_sales_quantity DESC, 
    total_web_sales_revenue DESC, 
    i.i_item_id
LIMIT 100;
