WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
NationsWithSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
    COALESCE(SUM(rv.total_revenue), 0) AS total_revenue,
    ns.supplier_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSupplier rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN 
    HighValueOrders rv ON ps.ps_partkey = rv.o_orderkey
JOIN 
    NationsWithSupplier ns ON p.p_name LIKE '%' || ns.n_name || '%'
GROUP BY 
    p.p_name, ns.supplier_count
ORDER BY 
    total_suppliers DESC, total_revenue DESC;
