
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
), aggregated_shipping AS (
    SELECT 
        l.l_shipmode,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    INNER JOIN 
        ranked_orders r ON o.o_orderkey = r.o_orderkey
    WHERE 
        r.rank <= 5
    GROUP BY 
        l.l_shipmode
)
SELECT 
    s.s_name,
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT ps.ps_suppkey) AS number_of_suppliers,
    ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost,
    SUM(a.total_revenue) AS total_revenue_by_mode
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    aggregated_shipping a ON ps.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice DESC LIMIT 1)
GROUP BY 
    s.s_name, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_revenue_by_mode DESC, avg_supply_cost ASC;
