
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
),
top_items AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        SUM(sd.total_sales_price) AS total_sales
    FROM 
        sales_data sd
    JOIN 
        item item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk, item.i_product_name
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ti.i_product_name,
    ti.total_sales,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country
FROM 
    top_items ti
JOIN 
    sales_data sd ON ti.i_item_sk = sd.ws_item_sk
JOIN 
    address_info ai ON sd.ws_sold_date_sk IN (
        SELECT 
            dd.d_date_sk 
        FROM 
            date_dim dd 
        WHERE 
            dd.d_year = 2023
    )
ORDER BY 
    ti.total_sales DESC;
