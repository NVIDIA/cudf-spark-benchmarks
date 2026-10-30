
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
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
SalesAnalysis AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
DailyAnalysis AS (
    SELECT 
        dd.d_date_sk,
        dd.d_year,
        dd.d_month_seq,
        dd.d_dom,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.total_orders, 0) AS total_orders
    FROM 
        date_dim dd
    LEFT JOIN 
        SalesAnalysis sa ON dd.d_date_sk = sa.ws_ship_date_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    da.d_year,
    da.d_month_seq,
    da.d_dom,
    da.total_quantity,
    da.total_sales,
    da.total_orders
FROM 
    CustomerDetails cd
JOIN 
    DailyAnalysis da ON cd.c_customer_sk = da.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
    AND da.total_sales > 100
ORDER BY 
    da.total_sales DESC;
