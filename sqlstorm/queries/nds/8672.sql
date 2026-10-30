
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_quantity) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
TopProducts AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tp.total_quantity,
    tp.total_sales,
    (SELECT SUM(ws.ws_net_profit) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = tp.cs_item_sk) AS total_web_profit,
    (SELECT SUM(ss.ss_net_profit) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = tp.cs_item_sk) AS total_store_profit
FROM 
    TopProducts tp
JOIN 
    item i ON tp.cs_item_sk = i.i_item_sk
ORDER BY 
    tp.total_sales DESC;
