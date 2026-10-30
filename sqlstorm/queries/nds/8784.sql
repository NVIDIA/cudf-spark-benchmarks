WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00 
        AND i.i_rec_start_date <= cast('2002-10-01' as date)
        AND i.i_rec_end_date >= cast('2002-10-01' as date)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
top_selling_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_sales_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        ranked_sales rs
    JOIN 
        customer c ON rs.ws_order_number = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    top_selling_items ti
JOIN 
    customer c ON ti.ws_item_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ti.ws_item_sk, ti.total_quantity_sold, ti.total_sales_amount, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    ti.total_sales_amount DESC;