WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_sold
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
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
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    rs.r_name,
    rs.nation_count,
    rs.total_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY rs.r_name ORDER BY os.total_revenue DESC) AS revenue_rank
FROM 
    OrderSummary os
LEFT JOIN 
    customer c ON os.o_orderkey = c.c_custkey
LEFT JOIN 
    RegionStats rs ON c.c_nationkey = rs.nation_count
WHERE 
    (rs.total_supplier_balance IS NULL OR rs.total_supplier_balance > 10000)
    AND (os.total_revenue > (SELECT AVG(total_revenue) FROM OrderSummary))
ORDER BY 
    rs.r_name, os.total_revenue DESC;