
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', d.d_date) ORDER BY SUM(ws.ws_net_profit) DESC) AS month_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_date
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_discount,
        ss.total_net_profit
    FROM SalesSummary ss
    WHERE ss.month_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ti.ws_item_sk,
    COALESCE(ti.total_quantity_sold, 0) AS qty_sold,
    COALESCE(ti.total_sales, 0) AS sales_amount,
    COALESCE(ti.total_discount, 0) AS discount_amount,
    COALESCE(ti.total_net_profit, 0) AS profit_amount,
    COALESCE(cr.total_returns, 0) AS returns_count,
    COALESCE(cr.total_return_amount, 0) AS returns_amount,
    CASE 
        WHEN COALESCE(cr.total_return_amount, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM TopItems ti
LEFT JOIN CustomerReturns cr ON ti.ws_item_sk = cr.sr_item_sk
ORDER BY ti.total_net_profit DESC, ti.total_sales DESC;
