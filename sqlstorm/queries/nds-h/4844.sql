WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank,
        p.p_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
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
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < cast('1998-10-01' as date)
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    h.c_name AS customer_name,
    o.o_orderkey,
    o.lineitem_count,
    o.total_revenue,
    CASE 
        WHEN h.rn <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    COALESCE(pg.p_name, 'Unknown Part') AS part_name
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    HighValueCustomers h ON r.s_suppkey = h.c_custkey
LEFT JOIN 
    OrderDetails o ON o.o_orderkey = r.s_suppkey
LEFT JOIN 
    part pg ON pg.p_partkey = r.s_suppkey
WHERE 
    r.rank = 1
    AND (h.c_acctbal IS NULL OR r.s_acctbal > 10000)
ORDER BY 
    total_revenue DESC, 
    supplier_name, 
    customer_name;