WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
),
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY i_current_price DESC) AS rank
    FROM 
        item
    JOIN 
        catalog_page ON i_item_sk = cp_catalog_page_sk
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date) AND (i_rec_end_date IS NULL OR i_rec_end_date >= cast('2002-10-01' as date))
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    id.i_product_name,
    id.i_current_price,
    COALESCE(s.total_quantity, 0) AS total_web_sales
FROM 
    CustomerCTE c
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_item_sk
JOIN 
    ItemDetails id ON s.ws_item_sk = id.i_item_sk
WHERE 
    c.cd_purchase_estimate > 1000
    AND id.rank <= 5
ORDER BY 
    total_web_sales DESC
LIMIT 50;