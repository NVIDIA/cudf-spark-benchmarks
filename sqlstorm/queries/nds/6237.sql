
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        cu.c_first_name,
        cu.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour
    FROM 
        web_sales ws
    JOIN 
        customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN 
        customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        d.d_year = 2022
        AND t.t_hour BETWEEN 9 AND 17
),
AggregatedSales AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        SalesData
    GROUP BY 
        ca_state
)
SELECT 
    asales.ca_state,
    asales.total_orders,
    asales.total_quantity,
    asales.total_sales,
    asales.total_discount,
    CONCAT(ROUND((asales.total_sales / NULLIF(asales.total_orders, 0)), 2), ' (Avg Sales/Order)') AS avg_sales_per_order,
    CONCAT(ROUND((asales.total_discount / NULLIF(asales.total_orders, 0)), 2), ' (Avg Discount/Order)') AS avg_discount_per_order
FROM 
    AggregatedSales asales
ORDER BY 
    asales.total_sales DESC;
