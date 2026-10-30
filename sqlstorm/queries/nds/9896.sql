
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        MAX(ws.ws_ship_date_sk) AS last_ship_date,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_credit_rating = 'Great'
    GROUP BY 
        ws.ws_order_number
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_discount) AS avg_discount,
        MAX(last_ship_date) AS latest_ship_date,
        SUM(unique_customers) AS total_unique_customers
    FROM 
        SalesData
)
SELECT 
    avg_sales,
    avg_quantity,
    avg_discount,
    latest_ship_date,
    total_unique_customers
FROM 
    AverageSales;
