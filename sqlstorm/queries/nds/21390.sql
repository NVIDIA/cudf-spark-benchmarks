
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_item_sk
),
AggregateData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(rs.total_quantity, 0) AS total_sold,
        COALESCE(cr.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 
                SUM(rs.ws_sales_price * rs.ws_quantity) OVER (PARTITION BY i.i_item_sk)
            ELSE 
                NULL 
        END AS total_revenue_with_returns,
        AVG(CASE 
            WHEN rs.price_rank = 1 THEN rs.ws_sales_price
            ELSE NULL 
        END) OVER (PARTITION BY i.i_item_sk) AS max_sales_price
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
),
FinalAnalysis AS (
    SELECT 
        a.i_item_id,
        a.total_sold,
        a.total_returns,
        a.total_revenue_with_returns,
        a.max_sales_price,
        CASE 
            WHEN a.total_sold > 1000 THEN 'High Demand'
            WHEN a.total_sold BETWEEN 500 AND 1000 THEN 'Medium Demand'
            ELSE 'Low Demand' 
        END AS demand_category
    FROM 
        AggregateData a
    WHERE 
        a.total_revenue_with_returns IS NOT NULL
)

SELECT 
    fa.i_item_id,
    fa.total_sold,
    fa.total_returns,
    fa.total_revenue_with_returns,
    fa.max_sales_price,
    fa.demand_category
FROM 
    FinalAnalysis fa
ORDER BY 
    fa.total_revenue_with_returns DESC 
LIMIT 100;
