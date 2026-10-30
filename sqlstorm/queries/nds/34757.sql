
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_item_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(SUM(ws.total_sales), 0) AS total_sales,
        COALESCE(SUM(cr.total_return_amount), 0) AS total_returns,
        (COALESCE(SUM(ws.total_sales), 0) - COALESCE(SUM(cr.total_return_amount), 0)) AS net_sales,
        SUM(ws.total_quantity) AS quantity_sold
    FROM 
        SalesData ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_item_sk = cr.wr_item_sk
    GROUP BY 
        ws.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        isales.net_sales,
        isales.quantity_sold,
        RANK() OVER (ORDER BY isales.net_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        ItemSales isales ON i.i_item_sk = isales.ws_item_sk
)
SELECT 
    bsi.i_item_id,
    bsi.i_item_desc,
    bsi.net_sales,
    bsi.quantity_sold
FROM 
    BestSellingItems bsi
WHERE 
    bsi.sales_rank <= 10
ORDER BY 
    bsi.net_sales DESC;
