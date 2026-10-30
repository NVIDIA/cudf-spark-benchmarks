
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_item_price
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
),
SalesByGender AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.total_transactions) AS avg_transactions
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
SalesTrend AS (
    SELECT
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS yearly_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
)
SELECT
    sbg.cd_gender,
    sbg.customer_count,
    sbg.total_sales,
    sbg.avg_transactions,
    st.d_year,
    st.yearly_sales,
    st.avg_sales_price
FROM
    SalesByGender sbg
JOIN
    SalesTrend st ON sbg.total_sales BETWEEN st.avg_sales_price * 0.5 AND st.avg_sales_price * 1.5
ORDER BY
    sbg.total_sales DESC, st.d_year ASC;
