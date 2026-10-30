
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_item_sk
),
TopSales AS (
    SELECT 
        sales.ws_item_sk,
        sales.ws_net_profit,
        COALESCE(returns.total_returns, 0) AS total_returns,
        COALESCE(returns.total_return_amount, 0) AS total_return_amount
    FROM SalesData sales
    LEFT JOIN CustomerReturns returns ON sales.ws_item_sk = returns.wr_item_sk
    WHERE sales.profit_rank <= 5
)
SELECT 
    i_item_id,
    i_product_name,
    total_returns,
    total_return_amount,
    ws_net_profit
FROM TopSales ts
JOIN item i ON ts.ws_item_sk = i.i_item_sk
ORDER BY ws_net_profit DESC, total_return_amount ASC;
