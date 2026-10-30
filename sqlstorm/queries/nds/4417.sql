
WITH SalesStats AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452107 AND 2452195  
    GROUP BY 
        ws_item_sk
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_sales
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN 2452107 AND 2452195  
    GROUP BY 
        wr_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_sales, 0) AS total_returned_sales
    FROM 
        item i
    LEFT JOIN 
        SalesStats ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        ReturnStats rs ON i.i_item_sk = rs.wr_item_sk
),
FinalStats AS (
    SELECT 
        i_item_id,
        total_quantity_sold,
        total_sales,
        total_returned_quantity,
        total_returned_sales,
        (total_sales - total_returned_sales) AS net_sales,
        (total_quantity_sold - total_returned_quantity) AS net_quantity,
        CASE 
            WHEN total_sales > 1000 THEN 'High Revenue'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Revenue'
            ELSE 'Low Revenue'
        END AS revenue_category
    FROM 
        ItemSales
)
SELECT 
    fs.i_item_id,
    fs.total_quantity_sold,
    fs.total_sales,
    fs.total_returned_quantity,
    fs.total_returned_sales,
    fs.net_sales,
    fs.net_quantity,
    fs.revenue_category
FROM 
    FinalStats fs
ORDER BY 
    fs.net_sales DESC
LIMIT 10;
