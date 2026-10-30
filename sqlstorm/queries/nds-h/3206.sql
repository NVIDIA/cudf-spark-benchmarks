
WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O' 
        AND o_orderdate >= DATE '1997-01-01'
),
SupplierPartStats AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        SUM(ps_availqty) AS total_availqty,
        AVG(ps_supplycost) AS avg_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c_custkey,
        c_name,
        c_acctbal
    FROM 
        customer
    WHERE 
        c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_mktsegment = 'BUILDING') AS building_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_returnflag = 'N'
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 0) 
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
