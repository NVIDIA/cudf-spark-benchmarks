
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_sales, 
        SUM(ws.ws_net_profit) AS total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        sd.*, 
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.ws_item_sk,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.ib_income_band_sk,
    rs.total_quantity,
    rs.total_sales,
    rs.total_profit
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.d_year, rs.d_month_seq, rs.sales_rank;
