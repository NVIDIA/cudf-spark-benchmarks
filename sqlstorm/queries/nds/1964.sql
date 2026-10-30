
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        total_sales_quantity,
        total_sales_price
    FROM 
        SalesData
    WHERE 
        item_rank <= 10
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    COALESCE(tsi.ws_item_sk, r.wr_item_sk) AS item_sk,
    tsi.total_sales_quantity,
    tsi.total_sales_price,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (tsi.total_sales_price - COALESCE(r.total_return_amount, 0)) AS net_sales
FROM 
    TopSellingItems tsi
FULL OUTER JOIN 
    ReturnsData r ON tsi.ws_item_sk = r.wr_item_sk
ORDER BY 
    net_sales DESC;
