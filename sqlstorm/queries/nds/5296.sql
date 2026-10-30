
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ws.ws_ship_date_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_ship_date_sk, 
        d.d_year, 
        d.d_month_seq
), 
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_category, 
        i.i_brand
    FROM 
        item i
), 
sales_summary AS (
    SELECT 
        sd.ws_item_sk, 
        id.i_item_desc, 
        id.i_category,
        id.i_brand,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.d_year,
        sd.d_month_seq
    FROM 
        sales_data sd
    JOIN 
        item_details id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    ss.i_brand,
    ss.i_category,
    ss.d_year,
    ss.d_month_seq,
    AVG(ss.total_sales) AS avg_sales,
    SUM(ss.total_discount) AS total_discount
FROM 
    sales_summary ss
GROUP BY 
    ss.i_brand, 
    ss.i_category, 
    ss.d_year, 
    ss.d_month_seq
ORDER BY 
    ss.i_brand, 
    ss.i_category, 
    ss.d_year, 
    ss.d_month_seq;
