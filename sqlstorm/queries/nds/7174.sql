
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ProductPerformance AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(sd.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales_value,
        COALESCE(SUM(sd.total_profit), 0) AS total_profit_value
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
),
SalesSummary AS (
    SELECT 
        pp.i_item_id,
        pp.i_item_desc,
        pp.total_quantity_sold,
        pp.total_sales_value,
        pp.total_profit_value,
        ROW_NUMBER() OVER (ORDER BY pp.total_profit_value DESC) AS rank
    FROM ProductPerformance pp
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity_sold,
    ss.total_sales_value,
    ss.total_profit_value,
    ss.rank
FROM SalesSummary ss
WHERE ss.rank <= 10
ORDER BY ss.total_profit_value DESC;
