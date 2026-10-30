WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(ts.total_revenue) AS total_revenue,
        SUM(ts.total_quantity) AS total_quantity
    FROM 
        TotalSales ts
    JOIN 
        orders o ON ts.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    rs.s_name,
    rs.supplier_nation,
    rs.p_name,
    rs.ps_supplycost,
    ns.total_revenue,
    ns.total_quantity
FROM 
    RankedSupplier rs
JOIN 
    NationSales ns ON rs.supplier_nation = ns.n_name
WHERE 
    rs.supplier_rank = 1
ORDER BY 
    ns.total_revenue DESC, 
    rs.ps_supplycost ASC
LIMIT 10;
