
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS average_price,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_first_name, c.c_last_name, ca.ca_city
), RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    total_quantity,
    average_price,
    total_sales,
    c_first_name,
    c_last_name,
    ca_city
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;
