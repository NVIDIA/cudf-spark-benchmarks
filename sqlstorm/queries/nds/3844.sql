
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerAttributes AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
StoreStock AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ra.ws_item_sk,
    ra.total_quantity,
    ra.total_sales_price,
    st.total_stock,
    COUNT(DISTINCT ca.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN ca.cd_gender = 'M' THEN 1 ELSE NULL END) AS male_ratio,
    COALESCE(NULLIF(SUM(CASE WHEN ca.cd_marital_status = 'M' THEN 1 ELSE 0 END), 0), 0) AS total_married_customers
FROM 
    RankedSales ra
LEFT JOIN 
    StoreStock st ON ra.ws_item_sk = st.inv_item_sk
LEFT JOIN 
    web_sales ws ON ra.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    CustomerAttributes ca ON ws.ws_bill_customer_sk = ca.c_customer_sk
WHERE 
    ra.rank = 1
AND 
    (st.total_stock IS NULL OR st.total_stock > 0)
GROUP BY 
    ra.ws_item_sk, ra.total_quantity, ra.total_sales_price, st.total_stock
ORDER BY 
    total_sales_price DESC;
