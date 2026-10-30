
WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AggregatedData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_quantity) AS overall_quantity,
        SUM(sd.total_sales_price) AS overall_sales_price,
        SUM(sd.total_discount) AS overall_discount,
        COUNT(DISTINCT cd.c_customer_sk) AS total_customers,
        SUM(cd.total_sales) AS total_revenue
    FROM SalesData sd
    JOIN CustomerData cd ON sd.ws_item_sk = cd.c_customer_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ad.cd_gender,
    ad.cd_marital_status,
    ad.cd_education_status,
    ad.overall_quantity,
    ad.overall_sales_price,
    ad.overall_discount,
    ad.total_customers,
    ad.total_revenue,
    RANK() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank
FROM AggregatedData ad
ORDER BY ad.total_revenue DESC
LIMIT 10;
