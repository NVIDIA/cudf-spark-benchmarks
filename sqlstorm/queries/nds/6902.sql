
WITH SalesData AS (
    SELECT 
        ws1.ws_item_sk,
        SUM(ws1.ws_quantity) AS total_quantity_sold, 
        SUM(ws1.ws_ext_sales_price) AS total_sales,
        SUM(ws1.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws1.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws1.ws_item_sk ORDER BY SUM(ws1.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws1
    INNER JOIN 
        date_dim dd ON ws1.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws1.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.total_discount,
        sd.total_orders
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        tsi.total_quantity_sold,
        tsi.total_sales,
        tsi.total_discount,
        ws.ws_order_number
    FROM 
        TopSellingItems tsi
    JOIN 
        web_sales ws ON tsi.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_marital_status,
    sa.cd_purchase_estimate,
    SUM(sa.total_sales) AS total_sales_by_customer,
    AVG(sa.total_discount) AS average_discount_per_purchase,
    COUNT(DISTINCT sa.ws_order_number) AS orders_count
FROM 
    SalesAnalysis sa
GROUP BY 
    sa.c_customer_sk, 
    sa.c_first_name, 
    sa.c_last_name, 
    sa.cd_gender, 
    sa.cd_marital_status, 
    sa.cd_purchase_estimate
ORDER BY 
    total_sales_by_customer DESC;
