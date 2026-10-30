
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
),
AggregatedSales AS (
    SELECT 
        year,
        month,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        (SELECT 
             d_year AS year, 
             d_month_seq AS month, 
             ws_quantity, 
             ws_ext_sales_price,
             ws_order_number
         FROM 
             SalesData
         ) AS Sales
    GROUP BY 
        year, month
)
SELECT 
    a.year,
    a.month,
    a.total_quantity,
    a.total_sales,
    a.total_orders,
    RANK() OVER (PARTITION BY a.year ORDER BY a.total_sales DESC) AS sales_rank
FROM 
    AggregatedSales a
ORDER BY 
    a.year, a.month;
