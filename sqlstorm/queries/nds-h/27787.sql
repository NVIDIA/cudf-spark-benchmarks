
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 10
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.nation_name,
    COUNT(DISTINCT pp.p_partkey) AS popular_part_count,
    SUM(ro.total_revenue) AS total_revenue_last_6_months
FROM 
    RankedSuppliers r
LEFT JOIN 
    PopularParts pp ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM PopularParts p))
LEFT JOIN 
    RecentOrders ro ON r.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o))
WHERE 
    r.supplier_rank <= 5
GROUP BY 
    r.s_suppkey, r.s_name, r.nation_name
ORDER BY 
    total_revenue_last_6_months DESC;
