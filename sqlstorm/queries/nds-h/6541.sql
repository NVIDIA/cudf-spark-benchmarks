
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
TopOrders AS (
    SELECT 
        o.order_rank,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.customer_name,
        o.c_acctbal
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.customer_name,
    t.o_totalprice,
    SUM(sp.ps_supplycost) AS total_supplycost,
    COUNT(sp.ps_partkey) AS part_count
FROM 
    TopOrders t
LEFT JOIN 
    SupplierParts sp ON t.o_orderkey = sp.ps_partkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.customer_name, t.o_totalprice
ORDER BY 
    t.o_totalprice DESC;
