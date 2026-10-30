
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_ext_discount_amt) AS total_discount,
        AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesWithCustomer AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales_price,
        sd.total_discount,
        sd.avg_net_paid,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.hd_income_band_sk,
        cd.c_customer_sk
    FROM SalesData sd
    JOIN web_sales ws ON sd.ws_item_sk = ws.ws_item_sk
    JOIN CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
),
FinalReport AS (
    SELECT 
        item.i_product_name,
        SUM(swc.total_quantity) AS total_quantity_sold,
        SUM(swc.total_sales_price) AS total_sales_generated,
        COUNT(DISTINCT swc.c_customer_sk) AS unique_customers,
        AVG(swc.avg_net_paid) AS avg_amount_spent,
        COUNT(*) AS transactions_count,
        CASE 
            WHEN AVG(swc.cd_purchase_estimate) > 500 THEN 'High Value Customers'
            WHEN AVG(swc.cd_purchase_estimate) BETWEEN 200 AND 500 THEN 'Medium Value Customers'
            ELSE 'Low Value Customers'
        END AS customer_value_segment
    FROM SalesWithCustomer swc
    JOIN item ON swc.ws_item_sk = item.i_item_sk
    GROUP BY item.i_product_name
    ORDER BY total_sales_generated DESC
)
SELECT * FROM FinalReport
WHERE unique_customers > 100
LIMIT 10;
