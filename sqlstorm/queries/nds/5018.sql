
WITH sales_summary AS (
    SELECT 
        CASE 
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog'
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web'
            ELSE 'Store'
        END AS sales_channel,
        COALESCE(cs_ext_sales_price, ws_ext_sales_price, ss_ext_sales_price) AS total_sales,
        COALESCE(cs_quantity, ws_quantity, ss_quantity) AS quantity_sold,
        d_year,
        d_month_seq
    FROM 
        catalog_sales cs
    FULL OUTER JOIN web_sales ws ON cs_order_number = ws_order_number
    FULL OUTER JOIN store_sales ss ON cs_order_number = ss_ticket_number
    JOIN date_dim dd ON COALESCE(cs_sold_date_sk, ws_sold_date_sk, ss_sold_date_sk) = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
)
SELECT 
    sales_channel,
    SUM(total_sales) AS total_revenue,
    SUM(quantity_sold) AS total_units_sold,
    AVG(total_sales) AS avg_sales_per_transaction,
    COUNT(*) AS transaction_count
FROM 
    sales_summary
GROUP BY 
    sales_channel
ORDER BY 
    total_revenue DESC;
