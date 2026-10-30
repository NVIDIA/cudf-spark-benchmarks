
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ss.total_tax,
        ss.total_orders,
        ss.unique_customers,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    ts.sales_rank,
    id.i_product_name,
    id.i_brand,
    id.i_category,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount,
    ts.total_tax,
    ts.total_orders,
    ts.unique_customers,
    (ts.total_sales - ts.total_discount + ts.total_tax) AS net_revenue
FROM 
    top_sales ts
JOIN 
    item_details id ON ts.ws_item_sk = id.i_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank;
