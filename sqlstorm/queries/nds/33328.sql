
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerCTE AS (
    SELECT 
        c_customer_id,
        cd_gender,
        cd_marital_status,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c_current_cdemo_sk) AS demo_count
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        c_first_shipto_date_sk IS NOT NULL
),
TopSellingItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_sales,
        order_count
    FROM 
        SalesCTE
    JOIN 
        item ON SalesCTE.ws_item_sk = item.i_item_sk
    WHERE 
        rn <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE 
            WHEN w.ws_sold_date_sk BETWEEN 20230101 AND 20231231 THEN w.ws_ext_sales_price 
            ELSE 0 
        END) AS total_purchases
    FROM 
        web_sales w
    JOIN 
        customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cu.c_customer_id,
    cu.cd_gender,
    cu.cd_marital_status,
    ti.i_item_desc,
    ti.total_sales,
    cp.total_purchases,
    CASE 
        WHEN cp.total_purchases IS NULL THEN 'No Purchases'
        WHEN cp.total_purchases > 1000 THEN 'High Spending'
        ELSE 'Regular Spending'
    END AS spending_category
FROM 
    CustomerCTE cu
LEFT JOIN 
    TopSellingItems ti ON ti.i_item_id = (SELECT i_item_id FROM item WHERE i_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales))
LEFT JOIN 
    CustomerPurchases cp ON cu.c_customer_id = cp.c_customer_id
ORDER BY 
    cu.c_customer_id, ti.total_sales DESC;
