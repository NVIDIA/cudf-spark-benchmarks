WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS suppliers_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        ts.nation_name,
        ts.suppliers_count,
        SUM(CASE WHEN rs.total_revenue IS NOT NULL THEN rs.total_revenue ELSE 0 END) AS total_nation_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        TopSuppliers ts ON n.n_name = ts.nation_name
    LEFT JOIN 
        RankedSales rs ON n.n_nationkey = rs.p_partkey
    GROUP BY 
        r.r_name, ts.nation_name, ts.suppliers_count
)
SELECT 
    region_name,
    nation_name,
    suppliers_count,
    total_nation_revenue
FROM 
    FinalReport
ORDER BY 
    total_nation_revenue DESC, nation_name ASC;
