
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales_quantity,
        sd.total_sales_amount,
        sd.total_orders,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.sales_rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesWithCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ti.i_item_desc,
        ti.i_brand,
        ti.i_category,
        ti.total_sales_quantity,
        ti.total_sales_amount
    FROM 
        TopItems ti
    JOIN 
        web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerData c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.gender,
    c.income_band,
    SUM(s.total_sales_amount) AS total_spent,
    COUNT(DISTINCT s.i_item_desc) AS unique_items_purchased,
    MAX(s.total_sales_quantity) AS max_quantity_per_item
FROM 
    CustomerData c
LEFT JOIN 
    SalesWithCustomer s ON c.c_customer_sk = s.c_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.gender, c.income_band
HAVING 
    SUM(s.total_sales_amount) > 0
ORDER BY 
    total_spent DESC;
