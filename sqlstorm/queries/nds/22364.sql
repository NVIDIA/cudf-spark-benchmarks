
WITH RecursiveItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim)
        AND ws_sold_date_sk <= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 0
),

FilteredItems AS (
    SELECT 
        I.i_item_id,
        I.i_item_desc,
        RI.total_quantity,
        RI.total_net_profit,
        RI.order_count
    FROM 
        item I
    INNER JOIN 
        RecursiveItemSales RI ON I.i_item_sk = RI.ws_item_sk
    WHERE 
        RI.profit_rank <= 10
),

CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr_return_tax, 0)) AS total_return_tax,
        SUM(COALESCE(wr_fee, 0)) AS total_fees
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),

ReturnStatistics AS (
    SELECT 
        cr.customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_tax,
        cr.total_fees,
        CASE 
            WHEN cr.total_returns > 0 THEN 'High Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        CustomerReturns cr
),

FinalReport AS (
    SELECT 
        FI.i_item_id,
        FI.i_item_desc,
        FI.total_quantity,
        FI.total_net_profit,
        FI.order_count,
        R.total_returns,
        R.total_return_amount,
        R.total_return_tax,
        R.total_fees,
        COALESCE(R.return_category, 'No Returns') AS return_category
    FROM 
        FilteredItems FI
    LEFT JOIN 
        ReturnStatistics R ON FI.total_quantity = R.total_returns
)

SELECT 
    FR.i_item_id,
    FR.i_item_desc,
    FR.total_quantity,
    FR.total_net_profit,
    FR.order_count,
    FR.total_returns,
    FR.total_return_amount,
    FR.total_return_tax,
    FR.total_fees,
    CASE 
        WHEN FR.total_net_profit IS NULL THEN 'Profit Data Unavailable'
        ELSE 'Profit Data Available'
    END AS profit_data_status
FROM 
    FinalReport FR
WHERE 
    (FR.total_net_profit > 1000 OR FR.total_returns IS NOT NULL)
ORDER BY 
    FR.total_net_profit DESC, 
    FR.total_returns ASC;

