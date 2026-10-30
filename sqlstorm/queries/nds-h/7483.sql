WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.rn <= 5
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT h.l_orderkey) AS high_value_orders,
    SUM(h.total_value) AS total_high_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    HighValueLineItems h ON h.l_orderkey IN (SELECT l_orderkey FROM lineitem)
GROUP BY 
    r.r_name
ORDER BY 
    total_high_value DESC;