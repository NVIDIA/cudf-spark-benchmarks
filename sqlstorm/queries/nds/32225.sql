
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_name
),
ReturnsCTE AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalMetrics AS (
    SELECT 
        cte.c_first_name,
        cte.c_last_name,
        cte.cd_gender,
        s.total_sales,
        s.total_profit,
        r.total_returns,
        r.total_return_amt,
        COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0) AS net_sales
    FROM 
        CustomerCTE cte
    LEFT JOIN 
        SalesCTE s ON cte.c_customer_sk = s.ws_sold_date_sk
    LEFT JOIN 
        ReturnsCTE r ON cte.c_customer_sk = r.sr_item_sk
    WHERE 
        cte.GenderRank <= 10
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_sales,
    f.total_profit,
    f.total_returns,
    f.total_return_amt,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 1000 THEN 'High Value'
        WHEN f.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value_Category
FROM 
    FinalMetrics f
ORDER BY 
    f.net_sales DESC;
