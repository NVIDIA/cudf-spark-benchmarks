
WITH SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'M'
    GROUP BY 
        d.d_year, 
        d.d_month_seq, 
        d.d_week_seq
),
RankedSales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        d_week_seq, 
        total_sales, 
        total_discount, 
        total_orders, 
        unique_customers,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    total_sales,
    total_discount,
    total_orders,
    unique_customers,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, 
    d_month_seq, 
    d_week_seq;
