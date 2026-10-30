
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk AS sold_date,
        ws_item_sk AS item_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
returns_data AS (
    SELECT 
        wr_returned_date_sk AS return_date,
        wr_item_sk AS item_id,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY 
        wr_returned_date_sk,
        wr_item_sk
),
item_analysis AS (
    SELECT 
        sd.sold_date,
        sd.item_id,
        sd.total_quantity,
        sd.total_sales,
        rd.total_return_quantity,
        rd.total_return_amount,
        (sd.total_sales - COALESCE(rd.total_return_amount, 0)) AS net_sales
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.sold_date = rd.return_date AND sd.item_id = rd.item_id
)
SELECT 
    ia.item_id,
    SUM(ia.total_quantity) AS overall_quantity_sold,
    SUM(ia.total_sales) AS overall_sales,
    SUM(ia.total_return_quantity) AS overall_return_quantity,
    SUM(ia.total_return_amount) AS overall_return_amount,
    SUM(ia.net_sales) AS overall_net_sales
FROM 
    item_analysis ia
GROUP BY 
    ia.item_id
ORDER BY 
    overall_net_sales DESC
LIMIT 10;
