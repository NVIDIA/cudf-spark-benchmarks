WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ii.i_item_desc,
    ii.i_brand,
    si.total_quantity_sold,
    si.total_sales_value,
    CASE 
        WHEN si.total_sales_value > 10000 THEN 'High Value Customer'
        WHEN si.total_sales_value BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    customer_info ci 
JOIN 
    sales_info si ON si.ws_item_sk = ci.c_customer_sk
JOIN 
    item_info ii ON ii.i_item_sk = si.ws_item_sk
WHERE 
    ci.cd_gender = 'F' AND 
    ci.cd_marital_status = 'S' AND 
    ci.cd_education_status LIKE '%Bachelor%' 
ORDER BY 
    total_sales_value DESC
LIMIT 50;