
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS average_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    ii.i_item_desc,
    si.total_quantity,
    si.total_sales,
    si.average_sales,
    si.total_discount,
    ii.i_current_price,
    si.total_sales / NULLIF(si.total_quantity, 0) AS sales_per_unit
FROM 
    sales_data si
JOIN 
    item_info ii ON si.ws_item_sk = ii.i_item_sk
ORDER BY 
    si.total_sales DESC
LIMIT 10;
