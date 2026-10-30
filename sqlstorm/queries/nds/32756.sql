
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_order_number, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        sales_rank
    FROM SalesCTE
    WHERE sales_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_credit_rating, 
        SUM(CASE WHEN ws.ws_ext_discount_amt IS NOT NULL THEN ws.ws_ext_discount_amt ELSE 0 END) AS total_discount 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
),
SalesAnalysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_credit_rating,
        ts.total_sales,
        ci.total_discount,
        CASE 
            WHEN ci.total_discount > 50 THEN 'High Discount'
            WHEN ci.total_discount BETWEEN 20 AND 50 THEN 'Medium Discount'
            ELSE 'Low Discount'
        END AS discount_category
    FROM CustomerInfo ci
    JOIN TopSales ts ON ci.c_customer_sk = ts.ws_item_sk
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_credit_rating,
    sa.total_sales,
    sa.total_discount,
    sa.discount_category,
    ROW_NUMBER() OVER (PARTITION BY sa.discount_category ORDER BY sa.total_sales DESC) AS discount_rank
FROM SalesAnalysis sa
WHERE sa.total_sales > 100.00
ORDER BY sa.discount_category, sa.total_sales DESC;
