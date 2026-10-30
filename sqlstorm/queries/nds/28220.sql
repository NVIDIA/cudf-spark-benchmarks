
WITH Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Item_Stats AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
Sales_Stats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    it.i_item_id,
    it.total_sales,
    it.total_revenue,
    it.avg_price,
    ss.total_quantity_sold,
    ss.total_sales_value
FROM 
    Customer_Info ci
LEFT JOIN 
    Item_Stats it ON ci.c_customer_id = it.i_item_id
LEFT JOIN 
    Sales_Stats ss ON ss.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    ci.cd_gender = 'M' AND ci.cd_marital_status = 'S'
ORDER BY 
    it.total_revenue DESC
LIMIT 100;
