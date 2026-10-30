WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        NTILE(4) OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales)) AS sales_quartile
    FROM
        CustomerSales cs
),
HighValueCustomers AS (
    SELECT 
        s.c_customer_id,
        s.total_sales,
        CASE 
            WHEN s.total_sales > 5000 THEN 'High Value'
            ELSE 'Low Value'
        END AS value_category
    FROM
        SalesSummary s
    WHERE
        s.total_sales > 5000
),
RecentSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS recent_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS recent_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS recent_store_orders,
        cast('2002-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AS recent_period
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= cast('2002-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk AND cs.cs_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= cast('2002-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk AND ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= cast('2002-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
    GROUP BY
        c.c_customer_id
)
SELECT 
    hv.c_customer_id,
    hv.value_category,
    rs.recent_web_orders,
    rs.recent_catalog_orders,
    rs.recent_store_orders
FROM 
    HighValueCustomers hv
LEFT JOIN 
    RecentSales rs ON hv.c_customer_id = rs.c_customer_id
ORDER BY 
    hv.value_category, rs.recent_web_orders DESC NULLS LAST;