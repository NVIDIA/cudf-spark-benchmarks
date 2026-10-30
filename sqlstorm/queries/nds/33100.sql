
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        apartment_count.apartment_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_dep_count DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ca_address_sk,
            COUNT(*) AS apartment_count
        FROM customer_address
        GROUP BY ca_address_sk
    ) AS apartment_count ON c.c_current_addr_sk = apartment_count.ca_address_sk
), LastPurchase AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), PurchaseSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_item_sk) AS total_items_purchased,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), CombinedData AS (
    SELECT 
        ccte.c_customer_sk,
        ccte.c_first_name,
        ccte.c_last_name,
        ccte.cd_marital_status,
        ld.last_purchase_date,
        ps.total_items_purchased,
        ps.total_sales_amount
    FROM CustomerCTE ccte
    LEFT JOIN LastPurchase ld ON ccte.c_customer_sk = ld.c_customer_sk
    LEFT JOIN PurchaseSummary ps ON ccte.c_customer_sk = ps.c_customer_sk
    WHERE ccte.rn = 1
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.last_purchase_date,
    COALESCE(cd.total_items_purchased, 0) AS items_purchased,
    COALESCE(cd.total_sales_amount, 0.00) AS sales_amount
FROM CombinedData cd
WHERE 
    (cd.last_purchase_date IS NOT NULL AND cd.c_first_name LIKE 'A%')
    OR (cd.total_sales_amount > 1000 AND cd.cd_marital_status = 'M')
ORDER BY cd.total_sales_amount DESC
LIMIT 100;
