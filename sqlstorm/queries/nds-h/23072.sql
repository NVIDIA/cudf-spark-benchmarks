WITH  SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SR.total_revenue, 0) AS total_revenue,
        RANK() OVER (ORDER BY COALESCE(SR.total_revenue, 0) DESC) AS revenue_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierRevenue SR ON s.s_suppkey = SR.s_suppkey
), BizarreCounts AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS bizarre_nation_count,
        SUM(CASE WHEN n.n_name IS NULL THEN 1 ELSE 0 END) AS null_nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
), FinalReport AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_revenue,
        rs.revenue_rank,
        bc.bizarre_nation_count,
        bc.null_nation_count
    FROM 
        RankedSuppliers rs
    JOIN 
        BizarreCounts bc ON bc.bizarre_nation_count > 2
    WHERE 
        rs.total_revenue > (SELECT 
                                AVG(total_revenue) 
                            FROM 
                                RankedSuppliers)
)
SELECT 
    fr.s_suppkey,
    fr.s_name,
    fr.total_revenue,
    fr.revenue_rank,
    fr.bizarre_nation_count,
    fr.null_nation_count,
    CONCAT('Supplier ', fr.s_name, ' from region with ', fr.bizarre_nation_count, ' bizarre nations counted') AS description
FROM 
    FinalReport fr
WHERE 
    fr.total_revenue BETWEEN (SELECT MIN(total_revenue) FROM RankedSuppliers) AND 
                               (SELECT MAX(total_revenue) FROM RankedSuppliers)
ORDER BY 
    fr.revenue_rank;
