
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics h
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
SalesRanked AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.distinct_items,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
)
SELECT 
    sr.c_customer_id,
    sr.total_sales,
    sr.order_count,
    sr.distinct_items,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top 10 Customer'
        WHEN sr.sales_rank > 10 AND sr.sales_rank <= 50 THEN 'Top 50 Customer'
        ELSE 'Other'
    END AS customer_category,
    id.ib_lower_bound,
    id.ib_upper_bound
FROM 
    SalesRanked sr
LEFT JOIN 
    IncomeDemographics id ON sr.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = c.c_customer_sk)
WHERE 
    sr.total_sales > 1000
ORDER BY 
    sr.total_sales DESC;
