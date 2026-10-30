
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) FILTER (WHERE cd_marital_status = 'M') AS married_customers,
        COUNT(DISTINCT c_customer_sk) FILTER (WHERE cd_marital_status = 'S') AS single_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
recent_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY 
        sr_customer_sk
),
item_sales_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
performance_benchmark AS (
    SELECT 
        ds.cd_gender,
        ds.total_customers,
        ds.avg_purchase_estimate,
        rr.total_returns,
        rr.total_return_amount,
        it.total_sold,
        it.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ds.cd_gender ORDER BY it.total_net_profit DESC) AS sales_rank
    FROM 
        demographic_summary ds
    LEFT JOIN 
        recent_returns rr ON rr.sr_customer_sk IN (SELECT c.c_customer_sk FROM customer c JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk WHERE cd.cd_gender = ds.cd_gender)
    LEFT JOIN 
        item_sales_summary it ON it.total_sold > 0
)
SELECT 
    pb.cd_gender,
    pb.total_customers,
    pb.avg_purchase_estimate,
    COALESCE(pb.total_returns, 0) AS total_returns,
    COALESCE(pb.total_return_amount, 0) AS total_return_amount,
    COALESCE(pb.total_sold, 0) AS total_sold,
    COALESCE(pb.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN pb.sales_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    performance_benchmark pb
ORDER BY 
    pb.total_net_profit DESC;
