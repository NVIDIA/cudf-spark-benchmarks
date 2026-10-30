
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        S.total_quantity,
        S.total_sales,
        S.avg_profit,
        S.order_count,
        ROW_NUMBER() OVER (ORDER BY S.total_sales DESC) AS sales_rank
    FROM 
        SalesData S
    JOIN 
        item I ON S.cs_item_sk = I.i_item_sk
)
SELECT 
    T.i_item_id,
    T.i_item_desc,
    T.total_quantity,
    T.total_sales,
    T.avg_profit,
    T.order_count
FROM 
    TopItems T
WHERE 
    T.sales_rank <= 10
ORDER BY 
    T.total_sales DESC;
