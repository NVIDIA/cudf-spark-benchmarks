WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_net_profit,
        MIN(ws.ws_ext_tax) AS min_ext_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        dd.d_year = 2001 
        AND it.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
ItemCategory AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(sd.total_sales) DESC) AS rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, 
        i.i_category
)
SELECT 
    ic.i_category,
    SUM(sd.total_sales) AS total_sales,
    AVG(sd.avg_net_paid) AS avg_net_paid,
    COUNT(DISTINCT sd.ws_item_sk) AS item_count
FROM 
    SalesData sd
JOIN 
    ItemCategory ic ON sd.ws_item_sk = ic.i_item_sk
WHERE 
    ic.rank <= 5 
GROUP BY 
    ic.i_category
ORDER BY 
    total_sales DESC;