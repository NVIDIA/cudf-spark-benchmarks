
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category
    FROM 
        item i
), CombinedData AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        id.i_brand,
        id.i_category,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        (sd.total_sales - sd.total_discount) AS net_sales
    FROM 
        ItemDetails id
    LEFT JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
)
SELECT 
    cd.i_brand,
    cd.i_category,
    COUNT(cd.i_item_id) AS total_items,
    SUM(cd.total_quantity) AS grand_total_quantity,
    SUM(cd.net_sales) AS grand_total_sales
FROM 
    CombinedData cd
GROUP BY 
    cd.i_brand,
    cd.i_category
ORDER BY 
    grand_total_sales DESC
LIMIT 10;
