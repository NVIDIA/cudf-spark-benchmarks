
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),

CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS unique_customers_returned,
        CASE 
            WHEN SUM(wr.wr_return_quantity) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),

CombinedSalesAndReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.unique_customers_returned, 0) AS unique_customers_returned,
        sd.sales_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
)

SELECT 
    cs.ws_item_sk,
    i.i_item_desc,
    cs.total_quantity_sold,
    cs.total_sales,
    cs.total_returned_quantity,
    cs.unique_customers_returned,
    cs.sales_rank,
    (cs.total_sales / NULLIF(cs.total_quantity_sold, 0)) AS avg_price_per_item,
    (CAST(cs.total_returned_quantity AS FLOAT) / NULLIF(cs.total_quantity_sold, 0)) * 100 AS return_percentage
FROM 
    CombinedSalesAndReturns cs
JOIN 
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC;
