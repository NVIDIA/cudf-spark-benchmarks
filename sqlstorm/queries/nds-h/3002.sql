WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    c.c_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    s.s_name AS supplier_name,
    CASE 
        WHEN SUM(li.l_discount) IS NULL THEN 0
        ELSE SUM(li.l_discount) 
    END AS total_discounted
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierPartDetails s ON li.l_partkey = s.ps_partkey AND li.l_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus IN ('F', 'O')
    AND o.o_orderkey IN (SELECT o_orderkey FROM TopOrders)
GROUP BY 
    c.c_name, s.s_name
ORDER BY 
    revenue DESC;