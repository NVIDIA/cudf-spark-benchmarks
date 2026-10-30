WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_spend
    FROM 
        customer c
    LEFT OUTER JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
BestSellingItems AS (
    SELECT 
        ir.i_item_id, 
        SUM(rs.ws_ext_sales_price) AS total_revenue
    FROM 
        RankedSales rs
    JOIN 
        item ir ON rs.ws_item_sk = ir.i_item_sk
    GROUP BY 
        ir.i_item_id
    HAVING 
        SUM(rs.ws_ext_sales_price) > 1000
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT cs.total_catalog_sales) AS catalog_sales_count,
    COALESCE(SUM(bs.total_revenue), 0) AS best_selling_item_revenue,
    CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Male'
    END AS gender,
    CASE 
        WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown Income Band'
        ELSE CONCAT('Income Band: ', hd.hd_income_band_sk)
    END AS income_band
FROM 
    customer c
LEFT JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    BestSellingItems bs ON bs.i_item_id = c.c_customer_id 
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id, cd.cd_gender, hd.hd_income_band_sk
HAVING 
    COUNT(DISTINCT cs.total_catalog_sales) > 0 
ORDER BY 
    best_selling_item_revenue DESC NULLS LAST;