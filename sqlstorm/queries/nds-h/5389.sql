WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_brand = 'Brand#33' 
        AND s.s_acctbal > 100.00
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_mktsegment = 'BUILDING' 
        AND c.c_acctbal > 500.00
), 
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS line_item_count,
        o.o_shippriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_shippriority
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    h.c_custkey,
    h.c_name,
    h.c_acctbal,
    o.o_orderkey,
    o.o_orderdate,
    o.total_sales,
    o.line_item_count,
    o.o_shippriority
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers h ON h.rn <= 10
JOIN 
    OrderMetrics o ON o.o_shippriority = 1
WHERE 
    r.rank = 1
ORDER BY 
    o.total_sales DESC, 
    h.c_acctbal DESC;