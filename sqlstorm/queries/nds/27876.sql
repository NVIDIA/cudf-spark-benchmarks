
WITH SalesSummary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DATE_TRUNC('month', d.d_date) AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        DATE_TRUNC('month', d.d_date)
),
RankedSales AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY s.sales_month ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary s
)
SELECT 
    rs.sales_month,
    rs.c_first_name,
    rs.c_last_name,
    rs.ca_city,
    rs.total_sales,
    rs.total_orders
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_month,
    rs.sales_rank;
