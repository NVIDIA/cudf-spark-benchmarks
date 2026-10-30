WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT d_date_sk 
                           FROM date_dim 
                           WHERE d_date = cast('2002-10-01' as date))
),
TopWebSales AS (
    SELECT 
        R.ws_item_sk,
        R.ws_order_number,
        R.ws_quantity,
        R.ws_ext_sales_price,
        COALESCE(SUM(CASE WHEN s.ss_item_sk IS NOT NULL THEN s.ss_quantity ELSE 0 END), 0) AS store_quantity,
        COALESCE(SUM(CASE WHEN c.cs_item_sk IS NOT NULL THEN c.cs_quantity ELSE 0 END), 0) AS catalog_quantity
    FROM 
        RankedSales R
    LEFT JOIN 
        store_sales s ON R.ws_item_sk = s.ss_item_sk AND R.ws_order_number = s.ss_ticket_number
    LEFT JOIN 
        catalog_sales c ON R.ws_item_sk = c.cs_item_sk AND R.ws_order_number = c.cs_order_number
    WHERE 
        R.rank_sales = 1
    GROUP BY 
        R.ws_item_sk, R.ws_order_number, R.ws_quantity, R.ws_ext_sales_price
),
FinalSales AS (
    SELECT 
        w.ws_item_sk,
        w.ws_order_number,
        w.ws_quantity,
        w.ws_ext_sales_price,
        w.store_quantity,
        w.catalog_quantity,
        CASE 
            WHEN w.store_quantity > w.catalog_quantity THEN 'Store Dominant'
            WHEN w.catalog_quantity > w.store_quantity THEN 'Catalog Dominant'
            ELSE 'Equal Sales'
        END AS Sales_Dominance
    FROM 
        TopWebSales w
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unspecified'
            ELSE cd.cd_gender 
        END AS customer_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        f.ws_item_sk,
        f.ws_order_number,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(f.ws_quantity) AS total_quantity,
        SUM(f.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count,
        MAX(f.Sales_Dominance) AS sales_dominance,
        CASE 
            WHEN SUM(f.ws_ext_sales_price) IS NULL THEN 'No Sales'
            WHEN SUM(f.ws_ext_sales_price) > 5000 THEN 'High Sales'
            ELSE 'Low Sales'
        END AS sales_performance
    FROM 
        FinalSales f
    INNER JOIN 
        CustomerInfo c ON f.ws_item_sk = c.c_customer_sk
    GROUP BY 
        f.ws_item_sk, f.ws_order_number, c.c_first_name, c.c_last_name, c.c_email_address
)
SELECT 
    ss.*
FROM 
    SalesSummary ss
WHERE 
    ss.transaction_count > 5 
    AND ss.sales_performance = 'High Sales'
ORDER BY 
    ss.total_sales DESC
LIMIT 10;