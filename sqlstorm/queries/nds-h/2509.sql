
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
ExtendedPartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand AS Brand,
        CASE 
            WHEN p.p_size > 30 THEN 'Large'
            WHEN p.p_size BETWEEN 15 AND 30 THEN 'Medium'
            ELSE 'Small'
        END AS Size_Category,
        p.p_retailprice + (p.p_retailprice * 0.1) AS Adjusted_Price
    FROM part p
)
SELECT 
    eo.p_name,
    eo.Brand,
    ss.total_cost,
    COUNT(DISTINCT lo.l_orderkey) AS Order_Count,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS Total_Sales,
    AVG(lo.l_tax) AS Avg_Tax_Rate
FROM ExtendedPartInfo eo
LEFT JOIN lineitem lo ON lo.l_partkey = eo.p_partkey
JOIN SupplierStats ss ON ss.s_suppkey = lo.l_suppkey
WHERE eo.Adjusted_Price > 50.00
AND lo.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY eo.p_name, eo.Brand, ss.total_cost
HAVING COUNT(DISTINCT lo.l_orderkey) > 10
ORDER BY Total_Sales DESC
LIMIT 5;
