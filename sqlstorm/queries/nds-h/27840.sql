WITH AggregatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price_after_discount,
        COUNT(DISTINCT c.c_custkey) AS unique_customers_count,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, r.r_name
)
SELECT 
    region_name,
    COUNT(DISTINCT p_partkey) AS part_count,
    SUM(total_available_qty) AS total_qty_available,
    AVG(avg_price_after_discount) AS overall_avg_price
FROM 
    AggregatedData
GROUP BY 
    region_name
HAVING 
    AVG(avg_price_after_discount) > 100
ORDER BY 
    overall_avg_price DESC;
