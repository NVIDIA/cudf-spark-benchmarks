
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
),
SalesSummary AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.i_brand,
        sd.total_quantity,
        sd.total_sales,
        sd.total_tax,
        sd.average_profit
    FROM 
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    ss.i_item_sk,
    ss.i_item_desc,
    ss.i_current_price,
    ss.i_brand,
    ss.total_quantity,
    ss.total_sales,
    ss.total_tax,
    ss.average_profit,
    CASE 
        WHEN ss.average_profit > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    SalesSummary ss
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
