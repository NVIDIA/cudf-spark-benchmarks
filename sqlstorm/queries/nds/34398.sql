
WITH  SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) as row_num
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
IncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS income_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        DENSE_RANK() OVER (ORDER BY d.d_year, d.d_month_seq) AS month_rank
    FROM 
        date_dim d
    WHERE 
        d.d_year >= 2020
)
SELECT 
    s.ws_item_sk,
    MAX(s.ws_sales_price) AS max_sales_price,
    SUM(s.ws_quantity) AS total_quantity,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    d.d_year,
    d.month_rank,
    COALESCE(id.income_status, 'Undefined') AS income_category,
    AVG(s.ws_ext_sales_price) FILTER (WHERE id.cd_gender = 'F') AS avg_female_sales,
    AVG(s.ws_ext_sales_price) FILTER (WHERE id.cd_gender = 'M') AS avg_male_sales
FROM 
    SalesDetails s
JOIN 
    IncomeDemographics id ON s.ws_item_sk = id.cd_demo_sk
JOIN 
    DateInfo d ON s.ws_order_number = d.d_date_sk
GROUP BY 
    s.ws_item_sk, d.d_year, d.month_rank, id.income_status
HAVING 
    SUM(s.ws_quantity) > 100
ORDER BY 
    total_orders DESC,
    max_sales_price DESC
LIMIT 50
