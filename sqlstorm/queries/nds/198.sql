
WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ib.ib_lower_bound, 0) AS lower_bound,
        COALESCE(ib.ib_upper_bound, 0) AS upper_bound
    FROM 
        item i
    LEFT JOIN 
        income_band ib ON i.i_item_sk = ib.ib_income_band_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_desc,
        id.i_current_price,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    INNER JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    ti.sales_rank,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.avg_net_profit,
    CASE 
        WHEN ti.total_sales IS NULL OR ti.total_sales = 0 THEN 'No Sales'
        ELSE 'Sales Measured'
    END AS sales_status,
    CONCAT('Total sales for ', ti.i_item_desc, ' is ', CAST(ti.total_sales AS STRING)) AS sales_message
FROM 
    TopItems ti
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
