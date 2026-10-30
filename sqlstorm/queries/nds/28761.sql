
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSaleStats AS (
    SELECT
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        iss.total_sales,
        iss.total_quantity,
        iss.total_revenue,
        ROW_NUMBER() OVER (ORDER BY iss.total_revenue DESC) AS rank
    FROM 
        item i
    JOIN 
        ItemSaleStats iss ON i.i_item_sk = iss.ws_item_sk
    WHERE
        iss.total_sales > 0
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_quantity,
    ti.total_revenue
FROM 
    CustomerDetails cd
JOIN 
    TopItems ti ON cd.c_customer_sk % 100 = ti.rank % 100
ORDER BY 
    cd.cd_gender, ti.total_revenue DESC
LIMIT 100;
