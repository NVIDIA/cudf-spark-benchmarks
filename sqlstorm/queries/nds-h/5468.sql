WITH RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        rs.nation_count,
        rs.total_supplier_balance,
        COUNT(os.o_orderkey) AS total_orders,
        SUM(os.total_revenue) AS total_revenue_generated
    FROM 
        RegionStats rs
    JOIN 
        region r ON rs.r_name = r.r_name
    LEFT JOIN 
        OrderStats os ON rs.nation_count > 0
    GROUP BY 
        r.r_name, rs.nation_count, rs.total_supplier_balance
)
SELECT 
    fr.region_name,
    fr.nation_count,
    fr.total_supplier_balance,
    fr.total_orders,
    fr.total_revenue_generated
FROM 
    FinalReport fr
ORDER BY 
    fr.total_revenue_generated DESC
LIMIT 10;