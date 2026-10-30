
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        EXTRACT(YEAR FROM d.d_date) AS sale_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2000-01-01' AND '2000-12-31'
),
YearlySales AS (
    SELECT 
        sale_year,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        sale_year
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ys.total_quantity,
    ys.total_sales
FROM 
    CustomerInfo ci
JOIN 
    YearlySales ys ON 2002 = ys.sale_year
WHERE 
    ci.cd_marital_status = 'M' 
    AND ci.cd_purchase_estimate > 1000
ORDER BY 
    ys.total_sales DESC
LIMIT 10;
