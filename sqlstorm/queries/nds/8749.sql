
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2458603 AND 2458608  
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_item_desc,
        sales_summary.total_quantity_sold,
        sales_summary.total_sales,
        RANK() OVER (PARTITION BY sales_summary.ws_sold_date_sk ORDER BY sales_summary.total_quantity_sold DESC) AS rank
    FROM 
        sales_summary
    JOIN 
        item ON sales_summary.ws_item_sk = item.i_item_sk
),
customer_details AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        customer.c_email_address,
        sales_summary.total_orders,
        sales_summary.total_sales
    FROM 
        customer
    JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    JOIN 
        sales_summary ON web_sales.ws_item_sk = sales_summary.ws_item_sk
)
SELECT 
    t.ws_sold_date_sk,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales,
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.total_orders,
    cd.total_sales
FROM 
    top_items ti
JOIN 
    customer_details cd ON ti.total_sales = cd.total_sales
JOIN 
    web_sales t ON ti.i_item_sk = t.ws_item_sk
WHERE 
    ti.rank <= 10  
ORDER BY 
    t.ws_sold_date_sk, ti.total_quantity_sold DESC;
