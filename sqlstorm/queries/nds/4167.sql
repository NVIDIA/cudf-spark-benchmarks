
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate > 1000
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 5
),
RecentSaleSummary AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS sale_count,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY 
        ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hvc.cd_purchase_estimate,
    hvc.customer_rank,
    r.total_returns,
    r.total_return_amount,
    rhws.sale_count,
    rhws.total_net_paid,
    rhws.avg_sales_price,
    COALESCE((SELECT SUM(w.ws_net_paid) FROM web_sales w WHERE w.ws_item_sk = rhws.ws_item_sk AND w.ws_bill_customer_sk = c.c_customer_sk), 0) AS additional_net_paid
FROM 
    customer AS c
LEFT JOIN 
    HighValueCustomers AS hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    ReturnStats AS r ON c.c_customer_sk = r.sr_customer_sk
JOIN 
    RecentSaleSummary AS rhws ON rhws.ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE price_rank = 1)
WHERE 
    r.total_return_amount IS NOT NULL OR hvc.customer_rank IS NOT NULL
ORDER BY 
    hvc.cd_purchase_estimate DESC, c.c_last_name ASC;
