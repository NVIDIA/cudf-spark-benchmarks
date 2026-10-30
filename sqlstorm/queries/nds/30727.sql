
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
TopSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
),
CustomerReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        wr_item_sk
)
SELECT 
    ts.ws_sold_date_sk,
    it.i_item_desc,
    it.i_brand,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    ROUND((ts.total_sales - COALESCE(cr.total_return_amount, 0)) / NULLIF(ts.total_sales, 0) * 100, 2) AS return_rate
FROM 
    TopSales ts
JOIN 
    ItemDetails it ON ts.ws_item_sk = it.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON ts.ws_item_sk = cr.wr_item_sk
ORDER BY 
    ts.ws_sold_date_sk DESC, 
    ts.total_sales DESC;
