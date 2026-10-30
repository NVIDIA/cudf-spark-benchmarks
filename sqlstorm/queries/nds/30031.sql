
WITH  SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        MIN(ws_sold_date_sk) AS first_sale_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        MIN(cs_sold_date_sk) AS first_sale_date
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_item_sk
),
CombinedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SD.total_quantity, 0) AS total_quantity,
        COALESCE(SD.total_profit, 0) AS total_profit,
        sd.first_sale_date
    FROM 
        item
    LEFT JOIN SalesData SD ON item.i_item_sk = SD.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS sales_rank
    FROM 
        CombinedSales
    WHERE 
        total_profit > 1000
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    tsi.sales_rank,
    CASE 
        WHEN tsi.first_sale_date IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    TopSellingItems tsi
WHERE 
    tsi.sales_rank <= 10
ORDER BY 
    tsi.sales_rank;
