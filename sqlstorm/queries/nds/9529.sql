
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        C.c_first_name, 
        C.c_last_name,
        CA.ca_city,
        D.d_year
    FROM 
        web_sales ws
    JOIN 
        customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE 
        D.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_item_sk, C.c_first_name, C.c_last_name, CA.ca_city, D.d_year
), TopSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    d_year,
    total_quantity_sold,
    total_sales,
    total_orders,
    c_first_name,
    c_last_name,
    ca_city
FROM 
    TopSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;
