
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
)
SELECT 
    r.r_name,
    AVG(ss.total_supply_cost) AS avg_supply_cost,
    MAX(o.total_revenue) AS max_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM RankedOrders o2 WHERE o2.o_orderdate >= DATE '1997-06-01')
WHERE 
    r.r_name IS NOT NULL AND ss.parts_supplied IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    AVG(ss.total_supply_cost) > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) 
ORDER BY 
    r.r_name ASC;
