
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
),
FinalSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount,
        (sd.total_sales - COALESCE(rd.total_returned_amount, 0)) AS net_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
RankedSales AS (
    SELECT 
        fs.ws_item_sk, 
        fs.total_quantity, 
        fs.total_sales, 
        fs.total_returned_quantity,
        fs.total_returned_amount,
        fs.net_sales,
        RANK() OVER (ORDER BY fs.net_sales DESC) AS sales_rank
    FROM 
        FinalSales fs
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    rs.total_quantity, 
    rs.total_sales, 
    rs.total_returned_quantity, 
    rs.total_returned_amount, 
    rs.net_sales, 
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
