
WITH Processed_Data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        p.p_promo_name,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ca.ca_country = 'USA'
    GROUP BY 
        c.c_customer_id, CONCAT(c.c_first_name, ' ', c.c_last_name), ca.ca_city, 
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END, 
        cd.cd_marital_status, cd.cd_education_status, 
        p.p_promo_name, COALESCE(i.i_item_desc, 'Unknown Item')
)
SELECT 
    ca_city AS city,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(total_sales_amount) AS avg_sales_amount,
    MAX(total_quantity_sold) AS max_quantity_sold
FROM 
    Processed_Data
GROUP BY 
    ca_city
ORDER BY 
    avg_sales_amount DESC
LIMIT 10;
