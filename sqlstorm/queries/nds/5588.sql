
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        dd.d_year,
        dd.d_month_seq
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        dd.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020
),
AggregatedSales AS (
    SELECT 
        cs.c_customer_id,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
    FROM 
        CustomerData cs
    JOIN 
        SalesData sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        cs.c_customer_id
),
RankedCustomers AS (
    SELECT 
        ca.c_customer_id,
        ca.total_quantity,
        ca.total_profit,
        DENSE_RANK() OVER (ORDER BY ca.total_profit DESC) AS profit_rank
    FROM 
        AggregatedSales ca
)
SELECT 
    rc.c_customer_id,
    rc.total_quantity,
    rc.total_profit,
    rc.profit_rank,
    (SELECT COUNT(*) FROM RankedCustomers WHERE profit_rank <= rc.profit_rank) AS cumulative_count
FROM 
    RankedCustomers rc
WHERE 
    rc.profit_rank <= 100
ORDER BY 
    rc.profit_rank;
