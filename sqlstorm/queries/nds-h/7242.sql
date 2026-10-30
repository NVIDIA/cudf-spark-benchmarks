
WITH  supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
region_nation_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    s.s_name AS supplier_name,
    s.total_value AS supplier_total_value,
    r.r_name AS region_name,
    r.total_nations AS nations_in_region,
    r.total_supplier_balance AS region_total_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    supplier_summary s
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    region_nation_summary r ON r.total_nations > 5
GROUP BY 
    s.s_name, s.total_value, r.r_name, r.total_nations, r.total_supplier_balance
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC, supplier_name ASC;
