
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank,
        i.i_brand
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(RS.sales_rank, 0) AS item_rank,
    COALESCE(AR.total_returns, 0) AS returns_count,
    COALESCE(AR.total_return_amt, 0.00) AS total_return_value,
    (CASE 
        WHEN COALESCE(RS.sales_rank, 0) > 10 THEN 'High'
        WHEN COALESCE(RS.sales_rank, 0) <= 0 THEN 'No Sales'
        ELSE 'Moderate'
     END) AS sales_performance,
    SUBSTRING(i.i_product_name FROM 1 FOR 20) AS short_product_name
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.ws_item_sk
LEFT JOIN 
    AggregatedReturns AR ON i.i_item_sk = AR.sr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
GROUP BY 
    i.i_item_id, RS.sales_rank, AR.total_returns, AR.total_return_amt, i.i_product_name
ORDER BY 
    item_rank DESC, returns_count ASC
LIMIT 50;
