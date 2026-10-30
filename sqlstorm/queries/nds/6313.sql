
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        CAST(d_date AS DATE) AS sales_date,
        cd_gender,
        hd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws_item_sk, d_date, cd_gender, hd_income_band_sk
),
RankedSales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_date, cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    rs.sales_date,
    rs.cd_gender,
    rs.hd_income_band_sk,
    rs.total_quantity,
    rs.total_sales
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_date, rs.cd_gender, rs.total_sales DESC;
