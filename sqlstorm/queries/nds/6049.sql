
WITH SalesSummary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
        AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
    GROUP BY
        d.d_year,
        d.d_month_seq,
        ca.ca_state
),
TopSales AS (
    SELECT 
        d_year,
        d_month_seq,
        ca_state,
        total_sales,
        order_count,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesSummary
)
SELECT 
    d_year,
    d_month_seq,
    ca_state,
    total_sales,
    order_count,
    avg_sales_price
FROM 
    TopSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;
