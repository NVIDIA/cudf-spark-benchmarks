WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS average_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.total_availability,
        s.average_cost,
        s.unique_suppliers
    FROM 
        part p
    JOIN 
        SupplierStats s ON p.p_partkey = s.ps_partkey
    ORDER BY 
        s.total_availability DESC
    LIMIT 10
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    tp.p_name,
    tp.total_availability,
    tp.average_cost,
    tp.unique_suppliers
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    TopParts tp ON l.l_partkey = tp.p_partkey
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_totalprice DESC, ro.o_orderdate DESC;