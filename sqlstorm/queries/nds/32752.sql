
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_web_sales,
        COALESCE(cd.cd_gender, 'U') AS gender,
        CASE 
            WHEN cu.hd_income_band_sk IS NOT NULL THEN ib.ib_upper_bound
            ELSE NULL
        END AS income_upper
    FROM 
        CustomerSales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics cu ON cs.c_customer_sk = cu.hd_demo_sk
    LEFT JOIN 
        income_band ib ON cu.hd_income_band_sk = ib.ib_income_band_sk
),
MaxSales AS (
    SELECT 
        MAX(total_web_sales) AS max_sales
    FROM 
        FilteredSales
),
SalesAnalysis AS (
    SELECT 
        f.c_customer_sk,
        f.total_web_sales,
        f.gender,
        f.income_upper,
        (f.total_web_sales * 100.0 / ms.max_sales) AS sales_percentage
    FROM 
        FilteredSales f,
        MaxSales ms
)
SELECT 
    sa.c_customer_sk,
    sa.total_web_sales,
    sa.gender,
    sa.income_upper,
    sa.sales_percentage,
    CASE 
        WHEN sa.sales_percentage >= 50 THEN 'High Buyer'
        WHEN sa.sales_percentage >= 20 THEN 'Average Buyer'
        ELSE 'Low Buyer'
    END AS buyer_category,
    ROW_NUMBER() OVER (ORDER BY sa.total_web_sales DESC) AS customer_rank
FROM 
    SalesAnalysis sa
WHERE 
    sa.total_web_sales IS NOT NULL
ORDER BY 
    sa.total_web_sales DESC;
