
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
SalesDistribution AS (
    SELECT
        CASE
            WHEN total_sales < 100 THEN 'Low'
            WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS sales_band,
        COUNT(*) AS customer_count,
        AVG(total_quantity) AS avg_quantity,
        AVG(order_count) AS avg_orders
    FROM
        CustomerSales
    GROUP BY
        sales_band
)
SELECT
    sd.sales_band,
    sd.customer_count,
    sd.avg_quantity,
    sd.avg_orders,
    cd.cd_gender,
    cd.cd_marital_status
FROM
    SalesDistribution AS sd
JOIN customer_demographics AS cd ON sd.sales_band = CASE
        WHEN sd.sales_band = 'Low' THEN 'Low'
        WHEN sd.sales_band = 'Medium' THEN 'Medium'
        ELSE 'High'
    END
ORDER BY
    sd.sales_band;
