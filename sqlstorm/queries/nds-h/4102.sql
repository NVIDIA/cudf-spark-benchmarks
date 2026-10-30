
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    r.r_name AS region_name,
    COALESCE(sd.supplied_parts, 0) AS total_supplied_parts,
    sd.total_supply_cost
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    (
        SELECT 
            n.n_nationkey, 
            r.r_regionkey 
        FROM 
            nation n
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey
    ) nr ON o.o_custkey = nr.n_nationkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
JOIN 
    region r ON nr.r_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, r.r_name, sd.total_supply_cost, sd.supplied_parts
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC,
    p.p_name ASC;
