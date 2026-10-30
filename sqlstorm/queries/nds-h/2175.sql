WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(sr.supplier_revenue, 0)) AS total_supplier_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierRevenue sr ON n.n_nationkey = sr.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.unique_parts,
    rg.r_name AS region_name,
    rg.nation_count,
    rg.total_supplier_revenue
FROM 
    OrderSummary os
LEFT JOIN 
    RegionSummary rg ON rg.total_supplier_revenue > (SELECT AVG(total_supplier_revenue) FROM RegionSummary)
WHERE 
    os.total_revenue > 10000
ORDER BY 
    os.total_revenue DESC, os.o_orderdate ASC
LIMIT 100;
