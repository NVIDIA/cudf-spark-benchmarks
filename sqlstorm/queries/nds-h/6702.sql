WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
), 
region_summary AS (
    SELECT 
        r.r_name AS region_name,
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
) 
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_orderdate,
    ro.total_revenue,
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance
FROM 
    ranked_orders ro
JOIN 
    region_summary rs ON ro.o_orderstatus = CASE 
        WHEN ro.total_revenue > 50000 THEN 'O' 
        ELSE 'F' 
    END
ORDER BY 
    ro.total_revenue DESC, 
    rs.region_name ASC
LIMIT 100;
