
WITH RankedSales AS (
    SELECT
        ws_day.d_date AS Sale_Date,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS Sale_Rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS Total_Quantity_Sold,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS Order_Count
    FROM
        web_sales ws
    JOIN
        date_dim ws_day ON ws.ws_sold_date_sk = ws_day.d_date_sk
),
ReturnAnalysis AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS Total_Returns,
        SUM(sr_return_amt_inc_tax) AS Total_Return_Amount,
        COUNT(DISTINCT sr_ticket_number) AS Return_Count
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IS NOT NULL
    GROUP BY
        sr_item_sk
),
FilteredSales AS (
    SELECT
        r.Sale_Date,
        r.ws_item_sk,
        r.ws_sales_price,
        r.Sale_Rank,
        r.Total_Quantity_Sold,
        r.Order_Count,
        ra.Total_Returns,
        ra.Total_Return_Amount,
        ra.Return_Count
    FROM
        RankedSales r
    LEFT JOIN
        ReturnAnalysis ra ON r.ws_item_sk = ra.sr_item_sk
    WHERE
        r.Sale_Rank = 1
        AND (ra.Total_Returns IS NULL OR ra.Total_Returns < r.Total_Quantity_Sold / 10)
)
SELECT
    fs.Sale_Date,
    fs.ws_item_sk,
    fs.ws_sales_price,
    COALESCE(fs.Total_Returns, 0) AS Returns,
    fs.Total_Quantity_Sold,
    fs.Order_Count,
    (fs.ws_sales_price * fs.Total_Quantity_Sold) AS Gross_Sales,
    COALESCE(fs.Total_Return_Amount, 0) AS Total_Return_Amount,
    ((fs.ws_sales_price * fs.Total_Quantity_Sold) - COALESCE(fs.Total_Return_Amount, 0)) AS Net_Sales
FROM
    FilteredSales fs
JOIN
    item i ON fs.ws_item_sk = i.i_item_sk
WHERE
    i.i_current_price > 0 AND i.i_item_desc NOT LIKE '%deprecated%'
ORDER BY
    Net_Sales DESC
LIMIT 100;
