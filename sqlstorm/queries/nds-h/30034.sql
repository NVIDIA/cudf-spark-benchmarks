
WITH  NationalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS status_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SalesAggregate AS (
    SELECT
        n.n_name,
        AVG(o.o_totalprice) AS avg_order_price,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        NationalSales n
    LEFT JOIN 
        OrderStats o ON n.total_sales > (SELECT AVG(o2.o_totalprice) FROM OrderStats o2)
    GROUP BY 
        n.n_name
)

SELECT 
    s.n_name,
    s.avg_order_price,
    CASE 
        WHEN s.total_orders IS NULL THEN 'No Orders'
        WHEN s.total_orders < 5 THEN 'Few Orders'
        ELSE 'Multiple Orders'
    END AS order_volume,
    COALESCE(s.total_orders, 0) AS confirmed_orders,
    CASE 
        WHEN s.total_orders > 10 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    SalesAggregate s

UNION 

SELECT 
    n.n_name,
    NULL AS avg_order_price,
    'No Orders' AS order_volume,
    0 AS confirmed_orders,
    'No Demand' AS demand_category
FROM 
    nation n
WHERE 
    n.n_nationkey NOT IN (SELECT n_nationkey FROM NationalSales);
