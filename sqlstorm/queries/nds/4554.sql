
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        COALESCE(NULLIF(i.i_item_desc, ''), 'No Description') AS item_description,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS cumulative_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalData AS (
    SELECT 
        sd.item_description,
        sd.ws_order_number,
        sd.cumulative_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        sd.ws_quantity,
        CASE 
            WHEN rd.total_returns IS NULL 
                THEN 'No Returns'
            WHEN rd.total_returns > 0 
                THEN 'Returns Exist'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    item_description,
    SUM(cumulative_sales) AS total_sales,
    SUM(ws_quantity) AS total_quantity_sold,
    AVG(total_returns) AS avg_returns,
    AVG(total_return_amount) AS avg_return_amount,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    MAX(return_status) AS return_info
FROM 
    FinalData
GROUP BY 
    item_description
HAVING 
    SUM(cumulative_sales) > 1000
ORDER BY 
    total_sales DESC;
