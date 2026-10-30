WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        i.i_current_price > 50 AND 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    ts.total_quantity, 
    ts.total_sales, 
    (SELECT SUM(ws.ws_net_profit) FROM web_sales ws WHERE ws.ws_item_sk = ts.ws_item_sk) AS total_net_profit 
FROM 
    TopSales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
ORDER BY 
    ts.total_sales DESC;