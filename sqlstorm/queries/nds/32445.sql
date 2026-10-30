
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ws_sold_date_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales_price,
        cs_sold_date_sk
    FROM
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),
RankedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(s.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(s.total_sales_price), 0) AS total_sales_price
    FROM 
        item
    LEFT JOIN 
        SalesCTE s ON item.i_item_sk = s.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
IncomeStats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    rs.i_item_id,
    rs.i_item_desc,
    rs.total_quantity,
    rs.total_sales_price,
    isd.customer_count,
    isd.avg_purchase_estimate
FROM 
    RankedSales rs
LEFT JOIN 
    IncomeStats isd ON (rs.total_quantity > 1000 AND isd.hd_income_band_sk IS NOT NULL)
ORDER BY 
    rs.total_sales_price DESC
LIMIT 10;
