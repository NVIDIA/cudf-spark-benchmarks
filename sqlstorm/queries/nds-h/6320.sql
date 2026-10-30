
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost,
        p.p_brand,
        p.p_type,
        ps.ps_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_brand, p.p_type, ps.ps_partkey
),
OrderLineSummary AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, l.l_partkey
)
SELECT 
    r.r_name,
    SUM(ol.total_revenue) AS revenue,
    SUM(sp.total_available) AS total_supply,
    COUNT(DISTINCT sp.s_suppkey) AS supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierPartDetails sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    OrderLineSummary ol ON sp.ps_partkey = ol.l_partkey
GROUP BY 
    r.r_name
ORDER BY 
    revenue DESC, total_supply DESC;
