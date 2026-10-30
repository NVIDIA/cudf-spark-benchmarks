
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS average_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics AS hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
RankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.average_sales_price,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.ib_lower_bound,
        cs.ib_upper_bound,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rs.cd_gender,
    COUNT(*) AS customer_count,
    SUM(rs.total_sales) AS total_sales_by_gender,
    AVG(rs.average_sales_price) AS average_sales_price_by_gender,
    MAX(rs.sales_rank) AS max_sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.cd_gender
ORDER BY 
    total_sales_by_gender DESC;
