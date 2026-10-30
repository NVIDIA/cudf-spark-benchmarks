
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        COALESCE(rd.total_returned, 0) AS total_returned,
        sd.total_quantity - COALESCE(rd.total_returned, 0) AS net_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
RankedSales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY s.net_sales DESC) AS sales_rank
    FROM 
        SalesWithReturns s
    WHERE 
        s.net_sales > 0
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.total_quantity,
    s.total_net_paid,
    s.total_returned,
    s.net_sales,
    s.sales_rank,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top Seller'
        WHEN s.sales_rank <= 50 THEN 'Mid Seller'
        ELSE 'Low Seller'
    END AS seller_category
FROM 
    RankedSales s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price BETWEEN 10 AND 100
ORDER BY 
    s.sales_rank;
