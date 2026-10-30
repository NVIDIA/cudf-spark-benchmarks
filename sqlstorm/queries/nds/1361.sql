
WITH ReturnInfo AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CombinedInfo AS (
    SELECT 
        COALESCE(sales.ws_item_sk, returns.sr_item_sk) AS item_sk,
        COALESCE(total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(total_sales_amount, 0) AS total_sales_amount,
        COALESCE(total_return_quantity, 0) AS total_return_quantity,
        COALESCE(total_return_amount, 0) AS total_return_amount
    FROM 
        SalesInfo sales
    FULL OUTER JOIN 
        ReturnInfo returns ON sales.ws_item_sk = returns.sr_item_sk
),
FinalMetrics AS (
    SELECT 
        item_sk,
        total_sales_quantity,
        total_sales_amount,
        total_return_quantity,
        total_return_amount,
        (total_sales_amount - total_return_amount) AS net_sales_amount,
        (total_sales_quantity - total_return_quantity) AS net_sales_quantity,
        CASE 
            WHEN (total_sales_amount - total_return_amount) < 0 THEN 'Negative Revenue'
            WHEN (total_sales_quantity - total_return_quantity) < 0 THEN 'Negative Quantity'
            ELSE 'Positive Metrics'
        END AS sales_status
    FROM 
        CombinedInfo
),
RankedMetrics AS (
    SELECT 
        item_sk,
        total_sales_quantity,
        total_sales_amount,
        total_return_quantity,
        total_return_amount,
        net_sales_amount,
        net_sales_quantity,
        sales_status,
        RANK() OVER (ORDER BY net_sales_amount DESC) AS revenue_rank,
        RANK() OVER (ORDER BY net_sales_quantity DESC) AS quantity_rank
    FROM 
        FinalMetrics
)
SELECT 
    item_sk,
    total_sales_quantity,
    total_sales_amount,
    total_return_quantity,
    total_return_amount,
    net_sales_amount,
    net_sales_quantity,
    sales_status,
    revenue_rank,
    quantity_rank
FROM 
    RankedMetrics
WHERE 
    net_sales_amount > 0 
    AND net_sales_quantity > 0
ORDER BY 
    revenue_rank, quantity_rank
LIMIT 100;
