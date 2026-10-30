
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    ns.r_name,
    COALESCE(rs.supplier_rank, 0) AS supplier_rank,
    ts.total_revenue,
    ns.nation_count,
    ns.total_supplier_balance
FROM 
    RegionStats ns
LEFT JOIN 
    RankedSuppliers rs ON ns.nation_count = rs.s_suppkey
LEFT JOIN 
    TotalSales ts ON ts.o_orderkey = rs.s_suppkey
WHERE 
    ns.total_supplier_balance IS NOT NULL
ORDER BY 
    ns.total_supplier_balance DESC,
    supplier_rank ASC
LIMIT 100;
