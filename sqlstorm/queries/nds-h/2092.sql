WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_totalprice,
        o_orderdate,
        RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS order_rank
    FROM 
        orders
    WHERE
        o_orderdate >= DATE '1996-01-01' 
        AND o_orderdate < DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(NULLIF(l.l_discount, 0)) AS avg_discount,
    MAX(CASE WHEN r.order_rank = 1 THEN o.o_totalprice ELSE NULL END) AS max_top_order_price,
    COUNT(DISTINCT CASE WHEN ci.total_spent > 10000 THEN ci.c_custkey ELSE NULL END) AS high_value_customers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedOrders r ON o.o_orderkey = r.o_orderkey
LEFT JOIN 
    CustomerOrders ci ON o.o_custkey = ci.c_custkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC
LIMIT 10;