WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount,
        COUNT(*) AS line_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    oi.total_line_amount,
    oi.line_count,
    oi.avg_quantity
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    CustomerOrders co ON r.s_suppkey = co.c_custkey
LEFT JOIN 
    OrderLineItem oi ON co.o_orderkey = oi.o_orderkey
WHERE 
    (co.o_orderdate >= '1997-01-01' OR r.s_acctbal IS NULL)
    AND (oi.total_line_amount > 1000 OR r.s_acctbal < 50000)
ORDER BY 
    r.s_acctbal DESC NULLS LAST, 
    co.o_orderdate ASC;