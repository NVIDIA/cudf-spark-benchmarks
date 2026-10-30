
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459202 AND 2459207
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
), 
SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(total_sales) AS sales_sum,
        AVG(total_orders) AS avg_orders
    FROM CustomerSales
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.customer_count,
    ss.sales_sum,
    ss.avg_orders,
    CASE 
        WHEN ss.sales_sum >= 10000 THEN 'High Value Customer'
        WHEN ss.sales_sum < 10000 AND ss.sales_sum >= 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM SalesSummary ss
ORDER BY ss.sales_sum DESC;
