
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        wd.d_year,
        wd.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ws.ws_item_sk, wd.d_year, wd.d_month_seq, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(sd.total_quantity_sold, 0) AS quantity_sold,
        COALESCE(sd.total_sales_amount, 0) AS sales_amount,
        COALESCE(sd.total_orders, 0) AS orders_count
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    item.i_item_sk,
    item.i_product_name,
    item.i_current_price,
    item.quantity_sold,
    item.sales_amount,
    item.orders_count,
    ROW_NUMBER() OVER (ORDER BY item.sales_amount DESC) AS sales_rank
FROM 
    item_stats item
WHERE 
    item.sales_amount > 5000
ORDER BY 
    item.sales_amount DESC
LIMIT 100;
