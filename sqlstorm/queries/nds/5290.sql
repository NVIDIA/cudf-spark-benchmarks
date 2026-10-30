
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2022 AND d_moy BETWEEN 6 AND 8)
        AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2022 AND d_moy = 8)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_profit,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS rank_sales
    FROM 
        SalesData sd
) 
SELECT 
    item.i_item_id,
    item.i_item_desc,
    rs.total_quantity,
    rs.total_sales,
    rs.avg_profit
FROM 
    RankedSales rs
JOIN 
    item ON rs.ws_item_sk = item.i_item_sk
WHERE 
    rs.rank_sales <= 10
ORDER BY 
    rs.total_sales DESC;
