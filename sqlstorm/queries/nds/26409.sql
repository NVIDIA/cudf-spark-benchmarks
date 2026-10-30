
WITH LastYearSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
CurrentYearSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
Comparison AS (
    SELECT 
        COALESCE(l.ws_item_sk, c.ws_item_sk) AS item_sk,
        COALESCE(l.total_quantity, 0) AS last_year_quantity,
        COALESCE(c.total_quantity, 0) AS current_year_quantity,
        COALESCE(l.total_sales, 0) AS last_year_sales,
        COALESCE(c.total_sales, 0) AS current_year_sales,
        CASE 
            WHEN COALESCE(l.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(c.total_sales, 0) - COALESCE(l.total_sales, 0)) / COALESCE(l.total_sales, 0) * 100
        END AS sales_growth_percentage
    FROM 
        LastYearSales l
    FULL OUTER JOIN 
        CurrentYearSales c ON l.ws_item_sk = c.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cmp.last_year_quantity,
    cmp.current_year_quantity,
    cmp.last_year_sales,
    cmp.current_year_sales,
    cmp.sales_growth_percentage
FROM 
    Comparison cmp
JOIN 
    item i ON cmp.item_sk = i.i_item_sk
ORDER BY 
    cmp.sales_growth_percentage DESC
LIMIT 10;
