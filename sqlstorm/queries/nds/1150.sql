
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, ws.ws_ship_date_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_sales
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned_sales, 0) AS total_returned_sales,
        sd.sales_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    t.total_quantity,
    t.total_sales,
    t.total_returns,
    t.total_returned_sales,
    CASE 
        WHEN t.total_sales > 0 THEN (t.total_returns / CAST(t.total_sales AS decimal)) * 100
        ELSE NULL 
    END AS return_percentage
FROM 
    item ti
JOIN 
    TopSellingItems t ON ti.i_item_sk = t.ws_item_sk
ORDER BY 
    t.total_sales DESC;
