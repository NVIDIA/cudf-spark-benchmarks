
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(dd.d_date) AS last_sale_date
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        id.ib_lower_bound,
        id.ib_upper_bound
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN income_band id ON i.i_item_sk = id.ib_income_band_sk
), CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_id,
        id.i_product_name,
        id.i_brand,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        sd.last_sale_date,
        id.ib_lower_bound,
        id.ib_upper_bound
    FROM SalesData sd
    JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    cb.i_item_id,
    cb.i_product_name,
    cb.i_brand,
    cb.total_quantity,
    cb.total_sales,
    cb.total_profit,
    CASE 
        WHEN cb.total_sales > 100000 THEN 'High Performer'
        WHEN cb.total_sales BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    cb.last_sale_date,
    cb.ib_lower_bound,
    cb.ib_upper_bound
FROM CombinedData cb
WHERE cb.total_quantity > 0
ORDER BY cb.total_profit DESC
LIMIT 10;
