
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT min(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                             AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        s.total_quantity,
        s.total_sales,
        s.avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesData s
    JOIN 
        item i ON s.cs_item_sk = i.i_item_sk
)
SELECT 
    t.i_item_id,
    t.total_quantity,
    t.total_sales,
    t.avg_net_profit
FROM 
    TopItems t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
