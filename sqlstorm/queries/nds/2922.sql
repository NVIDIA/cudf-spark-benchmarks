
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY ws.ws_item_sk
),
ReturnedSales AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        sd.total_sales - COALESCE(rs.total_return_amount, 0) AS net_sales
    FROM SalesData sd
    LEFT JOIN ReturnedSales rs ON sd.ws_item_sk = rs.wr_item_sk
    WHERE sd.sales_rank = 1
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    fs.total_quantity_sold,
    fs.total_sales,
    fs.total_returns,
    fs.total_return_amount,
    fs.net_sales,
    CASE
        WHEN fs.net_sales > 1000 THEN 'High Performer'
        WHEN fs.net_sales > 500 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM FinalSales fs
JOIN item i ON fs.ws_item_sk = i.i_item_sk
ORDER BY fs.net_sales DESC;
