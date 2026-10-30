
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        CAST(d.d_date AS DATE) AS sales_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_date, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sales_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.sales_date,
    COUNT(DISTINCT rs.ws_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT rs.cd_gender) AS unique_genders,
    COUNT(DISTINCT rs.cd_marital_status) AS unique_marital_statuses,
    SUM(rs.total_quantity) AS total_quantity_sold,
    SUM(rs.total_sales) AS total_revenue,
    MAX(rs.sales_rank) AS highest_sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.sales_date
ORDER BY 
    rs.sales_date;
