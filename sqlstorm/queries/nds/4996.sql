
WITH SalesSummary AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year, i.i_category
),
CustomerStats AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender IS NOT NULL
    GROUP BY
        cd.cd_gender
),
StoreSales AS (
    SELECT
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_store_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_name
)

SELECT
    ss.d_year,
    ss.i_category,
    ss.total_quantity,
    ss.total_sales,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase,
    st.s_store_name,
    st.total_store_sales,
    st.avg_discount
FROM
    SalesSummary ss
LEFT JOIN
    CustomerStats cs ON ss.d_year = (SELECT MAX(d_year) FROM SalesSummary) 
LEFT JOIN
    StoreSales st ON ss.total_sales > 0
WHERE
    ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY
    ss.total_sales DESC, cs.cd_gender;
