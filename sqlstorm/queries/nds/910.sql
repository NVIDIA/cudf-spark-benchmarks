
WITH Customer_Sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS number_of_purchases
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk = (SELECT MAX(ss_inner.ss_sold_date_sk) FROM store_sales ss_inner)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM Customer_Sales cs
    WHERE cs.total_sales > (
        SELECT AVG(total_sales) FROM Customer_Sales
    )
),
Customer_Demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM High_Value_Customers hvc
JOIN Customer_Demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN income_band ib ON cd.income_band = ib.ib_income_band_sk
WHERE hvc.sales_rank <= 10
ORDER BY hvc.total_sales DESC;
