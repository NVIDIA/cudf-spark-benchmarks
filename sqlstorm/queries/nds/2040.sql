
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq = 8
    )
    GROUP BY ws_item_sk
),
ReturnData AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND (d_month_seq = 8 OR d_month_seq = 9)
    )
    GROUP BY wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        rd.total_returned,
        rd.total_return_amt,
        (sd.total_sales - COALESCE(rd.total_return_amt, 0)) AS net_sales
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
RankedItems AS (
    SELECT 
        cd.ws_item_sk,
        cd.total_quantity_sold,
        cd.total_sales,
        cd.total_returned,
        cd.net_sales,
        RANK() OVER (ORDER BY cd.net_sales DESC) AS sales_rank
    FROM CombinedData cd
)
SELECT 
    ri.ws_item_sk,
    ri.total_quantity_sold,
    ri.total_sales,
    ri.total_returned,
    ri.net_sales,
    ri.sales_rank,
    COALESCE(i.i_item_desc, 'Unknown Item') AS item_description
FROM RankedItems ri
LEFT JOIN item i ON ri.ws_item_sk = i.i_item_sk
WHERE ri.sales_rank <= 10
ORDER BY ri.sales_rank;
