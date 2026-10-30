
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_list_price) AS average_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND i.i_brand = 'BrandX'
        AND ws.ws_sold_date_sk BETWEEN 2458832 AND 2458838
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        s.ws_item_sk, 
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ss.average_list_price,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        web_sales s ON ss.ws_item_sk = s.ws_item_sk
)
SELECT 
    t.sales_rank,
    i.i_item_id,
    i.i_item_desc,
    t.total_quantity,
    t.total_sales,
    t.total_discount,
    t.average_list_price,
    t.total_orders
FROM 
    top_sales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.sales_rank;
