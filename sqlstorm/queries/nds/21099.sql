
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
SalesSummary AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        i.i_item_sk
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
),
FilteredReturns AS (
    SELECT 
        sr_item_sk,
        SUM(CASE WHEN sr_return_quantity > 0 THEN 1 ELSE 0 END) AS valid_returns_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalResults AS (
    SELECT
        ss.i_item_id,
        ss.i_item_desc,
        ss.total_quantity_sold,
        ss.total_sales_amount,
        COALESCE(fr.valid_returns_count, 0) AS valid_returns_count,
        CASE 
            WHEN ss.total_quantity_sold = 0 THEN NULL
            ELSE ROUND(COALESCE(fr.valid_returns_count, 0) * 1.0 / ss.total_quantity_sold, 4)
        END AS returns_ratio
    FROM 
        SalesSummary ss
    LEFT JOIN 
        FilteredReturns fr ON ss.i_item_sk = fr.sr_item_sk
    WHERE 
        ss.total_sales_amount > 1000
)
SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.total_quantity_sold,
    fr.total_sales_amount,
    fr.valid_returns_count,
    fr.returns_ratio,
    ROW_NUMBER() OVER (ORDER BY fr.returns_ratio DESC, fr.total_sales_amount DESC) AS rank
FROM 
    FinalResults fr
WHERE 
    fr.returns_ratio IS NOT NULL
ORDER BY 
    fr.returns_ratio DESC, fr.total_sales_amount DESC
LIMIT 10;
