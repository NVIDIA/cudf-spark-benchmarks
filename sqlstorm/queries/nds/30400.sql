
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_returned_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
final_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_returned_amt, 0) AS total_returned_amt,
        sd.total_sales - COALESCE(rd.total_returned_amt, 0) AS net_sales,
        sd.sales_rank
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_quantity,
    fs.total_sales,
    fs.total_returned,
    fs.total_returned_amt,
    fs.net_sales,
    fs.sales_rank
FROM 
    final_sales fs
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
WHERE 
    fs.net_sales > 1000
    AND fs.sales_rank <= 10
ORDER BY 
    fs.net_sales DESC;
