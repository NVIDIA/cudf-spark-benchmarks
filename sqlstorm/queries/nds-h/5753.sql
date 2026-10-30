
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopCostParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        RankedParts rp
    JOIN 
        lineitem l ON rp.p_partkey = l.l_partkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.rank_cost = 1
    GROUP BY 
        rp.p_partkey, rp.p_name, r.r_name
)
SELECT 
    tcp.p_name,
    tcp.region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(tcp.total_revenue) AS total_revenue_from_top_parts
FROM 
    TopCostParts tcp
JOIN 
    lineitem l ON tcp.p_partkey = l.l_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    tcp.p_name, tcp.region_name
ORDER BY 
    total_revenue_from_top_parts DESC
LIMIT 10;
