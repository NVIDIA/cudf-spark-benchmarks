
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    COALESCE(r.total_sales, 0) AS total_sales,
    CASE 
        WHEN r.sales_rank IS NULL THEN 'No purchases'
        WHEN r.sales_rank <= 10 THEN 'Top Purchaser'
        ELSE 'Regular Purchaser'
    END AS purchase_category
FROM CustomerDetails cd
LEFT JOIN RankedSales r ON cd.c_customer_sk = r.ws_bill_customer_sk
WHERE cd.cd_gender = 'F' 
AND cd.cd_marital_status = 'M' 
AND cd.cd_purchase_estimate > 1000
ORDER BY total_sales DESC;
