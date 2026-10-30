
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        d.d_year,
        d.d_month_seq
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_year, 
        d.d_month_seq
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM SalesSummary
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_quantity,
    r.total_sales,
    r.total_net_paid,
    r.d_year,
    r.d_month_seq
FROM RankedSales r
WHERE r.sales_rank <= 10
ORDER BY r.d_year, r.d_month_seq, r.total_sales DESC;
