
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('Bachelor’s', 'Master’s')
),
AggregatedSales AS (
    SELECT 
        sd.d_year,
        sd.d_month_seq,
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT sd.ws_item_sk) AS distinct_items_sold
    FROM 
        SalesData sd
    GROUP BY 
        sd.d_year, sd.d_month_seq, sd.ws_item_sk
)

SELECT 
    ag.d_year,
    ag.d_month_seq,
    ag.ws_item_sk,
    ag.total_quantity,
    ag.total_net_paid,
    ag.avg_sales_price,
    bi.ib_lower_bound,
    bi.ib_upper_bound
FROM 
    AggregatedSales ag
JOIN 
    item i ON ag.ws_item_sk = i.i_item_sk
JOIN 
    household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
JOIN 
    income_band bi ON hd.hd_income_band_sk = bi.ib_income_band_sk
ORDER BY 
    ag.total_net_paid DESC
LIMIT 100;
