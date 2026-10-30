
WITH 
    SalesData AS (
        SELECT 
            ws_sold_date_sk, 
            ws_item_sk, 
            SUM(ws_quantity) AS total_quantity, 
            SUM(ws_net_paid) AS total_sales, 
            ws_ship_mode_sk
        FROM web_sales
        GROUP BY ws_sold_date_sk, ws_item_sk, ws_ship_mode_sk
    ),
    ItemDetails AS (
        SELECT 
            i_item_sk, 
            i_item_desc, 
            i_current_price, 
            i_brand 
        FROM item
    ),
    DateDetails AS (
        SELECT 
            d_date_sk, 
            d_year, 
            d_month_seq 
        FROM date_dim 
        WHERE d_year = 2023
    ),
    ShipModeDetails AS (
        SELECT 
            sm_ship_mode_sk, 
            sm_type 
        FROM ship_mode
    )
SELECT 
    dd.d_year,
    dd.d_month_seq,
    im.i_item_desc,
    im.i_brand,
    sd.total_quantity,
    sd.total_sales,
    smd.sm_type
FROM 
    SalesData sd
JOIN 
    ItemDetails im ON sd.ws_item_sk = im.i_item_sk
JOIN 
    DateDetails dd ON sd.ws_sold_date_sk = dd.d_date_sk
JOIN 
    ShipModeDetails smd ON sd.ws_ship_mode_sk = smd.sm_ship_mode_sk
WHERE 
    sd.total_sales > 5000
ORDER BY 
    dd.d_year, dd.d_month_seq, sd.total_sales DESC
LIMIT 100;
