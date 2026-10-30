
WITH RankedSales AS (
    SELECT 
        cs_bill_customer_sk,
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales 
    WHERE cs_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY cs_bill_customer_sk, cs_item_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        r.total_sales,
        r.order_count
    FROM RankedSales AS r
    JOIN customer AS c ON r.cs_bill_customer_sk = c.c_customer_sk
    WHERE r.sales_rank <= 5
),
SalesByItem AS (
    SELECT 
        i.i_item_id,
        SUM(ws_ext_sales_price) AS online_sales,
        SUM(cs_ext_sales_price) AS catalog_sales
    FROM item AS i
    LEFT JOIN web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales AS cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    tc.c_customer_id,
    sbi.i_item_id,
    sbi.online_sales,
    sbi.catalog_sales,
    (sbi.online_sales + sbi.catalog_sales) AS total_sales
FROM TopCustomers AS tc
JOIN SalesByItem AS sbi ON tc.total_sales > sbi.catalog_sales
ORDER BY tc.c_customer_id, total_sales DESC
LIMIT 100;
