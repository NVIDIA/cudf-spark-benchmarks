WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        item i
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CombinedDetails AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        id.i_item_desc,
        id.i_brand,
        id.i_category,
        sd.total_sales_quantity,
        sd.total_sales_amount,
        sd.last_sale_date
    FROM 
        CustomerDetails cd
    JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_item_sk  
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    i_item_desc,
    i_brand,
    i_category,
    total_sales_quantity,
    total_sales_amount,
    last_sale_date
FROM 
    CombinedDetails
WHERE 
    ca_state IN ('CA', 'NY') 
    AND total_sales_amount > 1000
ORDER BY 
    total_sales_amount DESC;