
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        CustomerData cd
    JOIN 
        customer c ON cd.c_customer_sk = c.c_customer_sk
    WHERE 
        cd.rank <= 10
),
SalesAnalysis AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        COUNT(tc.c_customer_sk) AS customer_count
    FROM 
        SalesData sd
    LEFT JOIN 
        TopCustomers tc ON sd.ws_item_sk IN (
            SELECT cp.cp_catalog_page_sk 
            FROM catalog_page cp 
            WHERE cp.cp_catalog_page_sk = sd.ws_item_sk
        )
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    sa.ws_item_sk,
    sa.total_quantity,
    sa.total_sales,
    COALESCE(sa.customer_count, 0) AS customer_count,
    CASE 
        WHEN sa.total_sales > 10000 THEN 'HIGH'
        WHEN sa.total_sales BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_sales DESC;
