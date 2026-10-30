
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS average_cost,
        COUNT(ps.ps_supplycost) AS supply_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    CASE 
        WHEN COALESCE(MAX(l.l_quantity), 0) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS supplier_status,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    (SELECT AVG(total_supply_value) FROM SupplierStats) AS avg_supplier_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pa.average_cost) AS median_part_cost
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    PartAnalysis pa ON pa.p_partkey = l.l_partkey
WHERE 
    o.o_orderstatus IN ('O', 'P') 
    AND (s.s_acctbal IS NOT NULL OR s.s_comment IS NOT NULL)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND COALESCE(SUM(l.l_discount), 0) < 1000
ORDER BY 
    total_revenue DESC;
