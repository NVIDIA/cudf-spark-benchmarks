
WITH SupplierOrderStats AS (
    SELECT 
        s.s_name,
        n.n_name AS nation,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_name
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    sos.s_name,
    sos.nation,
    sos.total_quantity,
    sos.total_revenue,
    rs.r_name AS region_name,
    rs.supplier_count,
    rs.total_account_balance
FROM 
    SupplierOrderStats sos
JOIN 
    RegionStats rs ON sos.nation = rs.r_name
WHERE 
    sos.total_revenue > 1000000 AND rs.supplier_count > 5
ORDER BY 
    sos.total_revenue DESC, rs.total_account_balance ASC
LIMIT 10;
