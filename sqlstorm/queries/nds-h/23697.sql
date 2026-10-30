WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
PartPricing AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    p.p_name AS part_name,
    od.total_revenue,
    pp.total_cost,
    COALESCE((SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = od.o_orderkey AND l.l_returnflag = 'R'), 0) AS return_count,
    CASE 
        WHEN od.item_count > 10 THEN 'High Volume'
        ELSE 'Regular Volume'
    END AS order_type
FROM 
    RankedSuppliers r
JOIN 
    partsupp ps ON r.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    PartPricing pp ON pp.p_partkey = p.p_partkey
JOIN 
    OrderDetails od ON od.o_orderkey = ps.ps_supplycost
WHERE 
    r.rank_per_nation = 1
    AND pp.total_cost > 1000
    AND r.s_acctbal IS NOT NULL
    AND (od.total_revenue IS NULL OR od.total_revenue > 500)
ORDER BY 
    r.s_name, p.p_name;