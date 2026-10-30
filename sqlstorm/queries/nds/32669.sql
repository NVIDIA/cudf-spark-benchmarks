WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
FilteredSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity,
        total_profit
    FROM 
        SalesCTE
    WHERE 
        rn <= 5
),
TopItems AS (
    SELECT 
        i_item_id, 
        i_item_desc, 
        SUM(fs.total_quantity) AS total_sales_quantity,
        SUM(fs.total_profit) AS total_sales_profit
    FROM 
        FilteredSales fs
    JOIN 
        item i ON fs.ws_item_sk = i.i_item_sk
    GROUP BY 
        i_item_id, i_item_desc
)
SELECT 
    t.total_sales_quantity,
    t.total_sales_profit,
    COALESCE(d.d_year, 2001) AS sales_year, 
    d.d_holiday,
    CASE 
        WHEN d.d_holiday = 'Y' THEN 'Holiday Sales'
        ELSE 'Regular Sales'
    END AS sales_type,
    CASE 
        WHEN t.total_sales_profit < 0 THEN 'Loss'
        WHEN t.total_sales_profit BETWEEN 0 AND 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    TopItems t
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date < cast('2002-10-01' as date))
WHERE 
    t.total_sales_quantity > 100
ORDER BY 
    total_sales_profit DESC;