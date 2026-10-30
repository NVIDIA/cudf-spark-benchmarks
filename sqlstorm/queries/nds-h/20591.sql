WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
RecentBigSpenders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 2
)

SELECT 
    R.c_name AS customer_name,
    R.order_count,
    PS.p_name AS part_name,
    PS.p_retailprice,
    RS.s_name AS supplier_name
FROM 
    RecentBigSpenders R
RIGHT JOIN 
    PartSupplier PS ON PS.supplier_count > R.order_count
LEFT JOIN 
    RankedSuppliers RS ON PS.p_partkey = RS.s_suppkey AND RS.rn = 1
WHERE 
    PS.p_retailprice = (SELECT MAX(p_retailprice) FROM PartSupplier)
ORDER BY 
    R.order_count DESC NULLS LAST, PS.p_retailprice DESC
LIMIT 100;