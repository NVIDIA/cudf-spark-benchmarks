
WITH ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year > (EXTRACT(YEAR FROM DATE('2002-10-01')) - 30) OR c.c_birth_year IS NULL
),
RecentSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ws.ws_item_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = (EXTRACT(YEAR FROM DATE('2002-10-01')) - 1)
        AND d.d_moy BETWEEN 6 AND 8
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk
),
SalesComparison AS (
    SELECT 
        r.customer_name,
        r.total_sales AS recent_sales,
        i.total_catalog_sales,
        CASE 
            WHEN i.total_catalog_sales > r.total_sales THEN 'Catalog > Web'
            WHEN i.total_catalog_sales < r.total_sales THEN 'Web > Catalog'
            ELSE 'Equal Sales'
        END AS sales_comparison
    FROM 
        (SELECT 
            CONCAT(ac.c_first_name, ' ', ac.c_last_name) AS customer_name,
            SUM(rs.total_sales) AS total_sales
        FROM 
            ActiveCustomers ac
        JOIN 
            RecentSales rs ON ac.c_customer_sk = rs.ws_item_sk
        GROUP BY 
            ac.c_customer_sk, ac.c_first_name, ac.c_last_name) r
    JOIN 
        ItemStats i ON r.customer_name LIKE CONCAT('%', i.i_item_sk, '%')
)
SELECT 
    customer_name,
    recent_sales,
    total_catalog_sales,
    sales_comparison,
    CASE 
        WHEN recent_sales IS NULL THEN 'No Recent Sales'
        WHEN total_catalog_sales IS NULL THEN 'No Catalog Sales'
        ELSE 'Sales Data Available'
    END AS sales_status
FROM 
    SalesComparison
WHERE 
    recent_sales > 1000
ORDER BY 
    recent_sales DESC;
