WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
)
SELECT 
    r.r_name,
    p.p_name,
    COALESCE(RankedSuppliers.s_name, 'Unknown Supplier') AS supplier_name,
    OrderStats.total_revenue,
    OrderStats.unique_customers,
    SupplierPartInfo.total_supply_cost
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers ON s.s_suppkey = RankedSuppliers.s_suppkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    OrderStats ON p.p_partkey = OrderStats.o_orderkey
LEFT JOIN 
    SupplierPartInfo ON p.p_partkey = SupplierPartInfo.ps_partkey
WHERE 
    (p.p_size > 10 OR p.p_type LIKE '%metal%')
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%quality%')
ORDER BY 
    total_revenue DESC, 
    unique_customers ASC
LIMIT 100;