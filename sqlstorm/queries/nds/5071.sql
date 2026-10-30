
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk AS item_sk, 
        cs.cs_order_number AS order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (4, 5) 
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS total_items_purchased,
        SUM(sd.total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.order_number
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
PromoData AS (
    SELECT 
        p.p_promo_sk, 
        p.p_promo_name, 
        SUM(ws.ws_quantity) AS total_sales_by_promo
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cd.total_items_purchased) AS avg_items_purchased,
    AVG(cd.total_spent) AS avg_spent,
    pd.total_sales_by_promo,
    pd.p_promo_name
FROM 
    CustomerData cd
JOIN 
    PromoData pd ON cd.total_spent > 1000
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, pd.p_promo_name, pd.total_sales_by_promo
ORDER BY 
    total_sales_by_promo DESC;
