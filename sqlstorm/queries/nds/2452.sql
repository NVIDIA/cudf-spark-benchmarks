
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_coupons,
        i.i_item_id,
        i.i_product_name,
        i.i_brand
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.sales_rank <= 10
),
ReturnedItems AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ts.i_item_id,
    ts.i_product_name,
    ts.i_brand,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_returned_amount, 0) AS total_returned_amount,
    (ts.total_sales - COALESCE(ri.total_returned_amount, 0)) AS net_sales,
    CASE 
        WHEN ts.total_sales > 0 THEN (COALESCE(ri.total_returned_amount, 0) / ts.total_sales) * 100
        ELSE 0
    END AS return_percentage
FROM 
    TopSales ts
LEFT JOIN 
    ReturnedItems ri ON ts.ws_item_sk = ri.wr_item_sk
ORDER BY 
    net_sales DESC;
