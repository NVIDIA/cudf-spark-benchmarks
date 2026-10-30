
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        ris.total_quantity,
        ris.total_net_paid,
        i.i_item_desc,
        i.i_brand,
        i.i_class
    FROM 
        RankedSales AS ris
    JOIN 
        item AS i ON ris.ws_item_sk = i.i_item_sk
    WHERE 
        ris.rank <= 10
)
SELECT 
    ti.i_item_desc,
    ti.i_brand,
    ti.i_class,
    ti.total_quantity,
    ti.total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders
FROM 
    TopItems AS ti
LEFT JOIN 
    catalog_sales AS cs ON ti.ws_item_sk = cs.cs_item_sk
GROUP BY 
    ti.i_item_desc, ti.i_brand, ti.i_class, ti.total_quantity, ti.total_net_paid
ORDER BY 
    ti.total_net_paid DESC;
