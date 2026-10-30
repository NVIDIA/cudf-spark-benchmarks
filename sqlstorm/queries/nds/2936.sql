
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(NULLIF(s.sum_sales, 0), 0) AS total_sales
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            s.ss_item_sk,
            SUM(s.ss_ext_sales_price) AS sum_sales
        FROM 
            store_sales s
        INNER JOIN 
            date_dim dd ON s.ss_sold_date_sk = dd.d_date_sk
        WHERE 
            dd.d_year = 2023
        GROUP BY 
            s.ss_item_sk
    ) AS s ON i.i_item_sk = s.ss_item_sk
)
SELECT 
    ii.i_product_name,
    ii.i_current_price,
    sd.total_quantity,
    sd.total_profit,
    RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
FROM 
    ItemInfo ii
JOIN 
    SalesData sd ON ii.i_item_sk = sd.ws_item_sk
WHERE 
    ii.total_sales >= 1000 AND
    ii.i_current_price > (SELECT AVG(i_current_price) FROM item)
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
