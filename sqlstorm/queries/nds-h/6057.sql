WITH RevenueByNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        n.n_name
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        rb.total_revenue,
        ps.supplier_count
    FROM 
        part p
    JOIN 
        RevenueByNation rb ON rb.total_revenue > 1000000
    JOIN 
        PartSupplierCount ps ON p.p_partkey = ps.ps_partkey
    ORDER BY 
        rb.total_revenue DESC
    LIMIT 10
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_revenue,
    tp.supplier_count
FROM 
    TopParts tp
ORDER BY 
    tp.supplier_count DESC, tp.total_revenue DESC;